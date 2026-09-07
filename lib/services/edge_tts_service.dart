import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class EdgeTtsService {
  static const String _trustedClientToken = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';
  static const int _winEpoch = 11644473600;
  static const String _chromiumFullVersion = '143.0.3650.75';
  static const String _chromiumMajorVersion = '143';
  static const String _secMsGecVersion = '1-$_chromiumFullVersion';

  static const List<String> usVoices = [
    'en-US-JennyNeural',
    'en-US-GuyNeural',
    'en-US-AriaNeural',
    'en-US-ChristopherNeural',
    'en-US-EricNeural',
    'en-US-MichelleNeural',
  ];

  static const List<String> ukVoices = [
    'en-GB-SoniaNeural',
    'en-GB-RyanNeural',
    'en-GB-LibbyNeural',
    'en-GB-ThomasNeural',
  ];

  static String getRandomVoice({required bool isUk}) {
    final pool = isUk ? ukVoices : usVoices;
    final rand = Random();
    return pool[rand.nextInt(pool.length)];
  }

  static String _generateMuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();
  }

  static String _generateUuidHex() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  static String _generateSecMsGec() {
    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    var ticks = nowSeconds + _winEpoch;
    ticks -= ticks % 300;
    final ticksStr = '${ticks * 10000000}';
    final strToHash = '$ticksStr$_trustedClientToken';
    return sha256.convert(utf8.encode(strToHash)).toString().toUpperCase();
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static Future<Uint8List> synthesize(
    String text, {
    required bool isUk,
    String? voice,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final selectedVoice = voice ?? getRandomVoice(isUk: isUk);
    final secMsGec = _generateSecMsGec();
    final connectionId = _generateUuidHex();
    final muid = _generateMuid();

    final wsUrl = 'https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1'
        '?TrustedClientToken=$_trustedClientToken'
        '&ConnectionId=$connectionId'
        '&Sec-MS-GEC=$secMsGec'
        '&Sec-MS-GEC-Version=$_secMsGecVersion';

    final userAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$_chromiumMajorVersion.0.0.0 Safari/537.36 Edg/$_chromiumMajorVersion.0.0.0';

    final client = HttpClient();
    client.userAgent = userAgent;

    WebSocket? webSocket;
    try {
      final request = await client.openUrl('GET', Uri.parse(wsUrl));
      request.headers.set('Pragma', 'no-cache');
      request.headers.set('Cache-Control', 'no-cache');
      request.headers.set('Origin', 'chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold');
      request.headers.set('Cookie', 'muid=$muid;');
      request.headers.set('Sec-WebSocket-Version', '13');
      request.headers.set('Sec-WebSocket-Key', base64.encode(List<int>.generate(16, (i) => i)));
      request.headers.set('Connection', 'Upgrade');
      request.headers.set('Upgrade', 'websocket');

      final response = await request.close();
      if (response.statusCode != 101) {
        throw Exception('Edge TTS connection failed (status: ${response.statusCode})');
      }

      final socket = await response.detachSocket();
      webSocket = WebSocket.fromUpgradedSocket(socket, serverSide: false);

      // Send speech config
      const configMessage =
          'Content-Type:application/json; charset=utf-8\r\nPath:speech.config\r\n\r\n'
          '{"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"false"},"outputFormat":"audio-24khz-48kbitrate-mono-mp3"}}}}';
      webSocket.add(configMessage);

      // Send SSML request
      final requestId = _generateUuidHex();
      final escapedText = _escapeXml(text);
      final ssml =
          '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="${isUk ? 'en-GB' : 'en-US'}">'
          '<voice name="$selectedVoice">'
          '$escapedText'
          '</voice>'
          '</speak>';
      final ssmlMessage =
          'X-RequestId:$requestId\r\nContent-Type:application/ssml+xml\r\nPath:ssml\r\n\r\n$ssml';
      webSocket.add(ssmlMessage);

      final List<int> audioData = [];
      final completer = Completer<Uint8List>();

      final subscription = webSocket.listen(
        (data) {
          if (data is List<int>) {
            if (data.length > 2) {
              final headerLen = (data[0] << 8) | data[1];
              if (data.length > 2 + headerLen) {
                audioData.addAll(data.sublist(2 + headerLen));
              }
            }
          } else if (data is String && data.contains('Path:turn.end')) {
            if (!completer.isCompleted) {
              completer.complete(Uint8List.fromList(audioData));
            }
          }
        },
        onError: (err) {
          if (!completer.isCompleted) completer.completeError(err);
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(Uint8List.fromList(audioData));
          }
        },
        cancelOnError: true,
      );

      final result = await completer.future.timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Edge TTS request timed out');
        },
      );
      await subscription.cancel();
      return result;
    } finally {
      try {
        await webSocket?.close();
      } catch (_) {}
      client.close();
    }
  }
}
