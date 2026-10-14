import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class EdgeTtsService {
  static const String _trustedClientToken = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';
  static const int _winEpoch = 11644473600;
  static const double _sToNs = 1e9;
  static const String _chromiumFullVersion = '143.0.3650.75';
  static const String _chromiumMajorVersion = '143';
  static const String _secMsGecVersion = '2-$_chromiumFullVersion';

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

  // --- Sec-MS-GEC v2 DRM Implementation ---
  static const int _u32Mask = 0xFFFFFFFF;

  static const List<int> _sha256Initial = [
    0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A,
    0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19,
  ];

  static const List<int> _sha256State = [
    0xFD9FBEA2, 0x91243CE7, 0xBE499094, 0xCD2E1E0A,
    0x6C006F49, 0x04BD35AB, 0xFEB0A7E4, 0x03EFFBD2,
  ];

  static const List<int> _sha256Schedule = [
    0xEB24BF9E, 0x1558691F, 0xA0C09EE2, 0x0CFA32BA,
    0xA622EE8C, 0xD1DD9491, 0xC0DD25A0, 0xF9E70AB6,
    0xF0C31573, 0x7058CE4E, 0x7188E606, 0x00E5AB33,
    0xD258B060, 0x72766564,
  ];

  static const List<int> _sha256RoundConstants = [
    0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5,
    0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5,
    0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3,
    0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174,
    0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC,
    0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
    0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7,
    0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967,
    0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13,
    0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85,
    0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3,
    0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
    0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5,
    0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3,
    0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208,
    0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2,
  ];

  static const int _sha256Adjustment = 0xC9DC06A7;
  static final List<int> _sha256BlockConstants = [
    ..._sha256RoundConstants.sublist(0, 14),
    _sha256Adjustment,
    ..._sha256RoundConstants.sublist(15),
  ];

  static const int _sha256Sigma0Adjustment = 0x059C0B80;
  static const int _sha256Sigma1Adjustment = 0x000B92C0;

  static const List<List<int>> _cs64Coefficients = [
    [0xE82E91B1, 0xB32700D0], [0x44DE24C6, 0x88DFF51D],
    [0x3BEB65BC, 0x29514038], [0xC89C5933, 0xB328CBDF],
    [0x8D1EC211, 0xD405B4D5], [0x314EF5D5, 0x26E55F3C],
    [0xE92491B1, 0x607801C6], [0xF0A5B9D5, 0x82B2C1FB],
    [0x06064CF3, 0xFA51A3DA], [0xDA79FA60, 0x207CC464],
    [0xBED20560, 0x3C3C74F3], [0x89F9C9F8, 0xD2D14B61],
    [0x35FA38C6, 0xBB04A2C1], [0xCB49E3C6, 0xC5626167],
  ];

  static const int _cs64Factor = 0x82893933;
  static const int _cs64Adjustment0 = 0xF2F90B1A;
  static const int _cs64Adjustment1 = 0x0B1A0000;

  static int _rol16(int value) {
    value &= _u32Mask;
    return (((value << 16) & _u32Mask) | (value >> 16)) & _u32Mask;
  }

  static List<int> _wordsLe4Even(List<int> data) {
    final remainder = (-data.length) % 4;
    final padLen = (remainder < 0 ? remainder + 4 : remainder);
    final padded = Uint8List(data.length + padLen);
    padded.setRange(0, data.length, data);
    if (padded.isEmpty) return [];
    final byteData = ByteData.sublistView(padded);
    final words = <int>[];
    for (int i = 0; i < padded.length; i += 4) {
      words.add(byteData.getUint32(i, Endian.little));
    }
    if (words.length % 2 != 0) {
      words.add(0);
    }
    return words;
  }

  static int _sigma0(int v) {
    v &= _u32Mask;
    return ((v >> 7) ^ ((v << 25) & _u32Mask) ^ (v >> 18) ^ ((v << 14) & _u32Mask) ^ (v >> 3)) & _u32Mask;
  }

  static int _sigma1(int v) {
    v &= _u32Mask;
    return ((v >> 17) ^ ((v << 15) & _u32Mask) ^ (v >> 19) ^ ((v << 13) & _u32Mask) ^ (v >> 10)) & _u32Mask;
  }

  static void _expandSha256Schedule(List<int> words, [int firstWord = 16]) {
    for (int i = firstWord; i < 64; i++) {
      final x = words[i - 2];
      final y = words[i - 15];
      final s1 = ((x >> 17) ^ ((x << 15) & _u32Mask) ^ (x >> 19) ^ ((x << 13) & _u32Mask) ^ (x >> 10));
      final s0 = ((y >> 7) ^ ((y << 25) & _u32Mask) ^ (y >> 18) ^ ((y << 14) & _u32Mask) ^ (y >> 3));
      words.add((s1 + words[i - 7] + s0 + words[i - 16]) & _u32Mask);
    }
  }

  static List<int> _sha256Rounds(List<int> state, List<int> words, [int firstRound = 0]) {
    int a = state[0], b = state[1], c = state[2], d = state[3];
    int e = state[4], f = state[5], g = state[6], h = state[7];
    final constants = (firstRound == 14) ? _sha256BlockConstants : _sha256RoundConstants;

    final aligned = (64 < ((firstRound + 7) ~/ 8) * 8) ? 64 : ((firstRound + 7) ~/ 8) * 8;
    for (int i = firstRound; i < aligned; i++) {
      final rotE = e * 0x100000001;
      final rotA = a * 0x100000001;
      final t1 = (h + ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) + (g ^ (e & (f ^ g))) + constants[i] + words[i]) & _u32Mask;
      final t2 = (((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) + ((a & b) | (c & (a | b)))) & _u32Mask;
      h = g; g = f; f = e;
      e = (d + t1) & _u32Mask;
      d = c; c = b; b = a;
      a = (t1 + t2) & _u32Mask;
    }

    for (int i = aligned; i < 64; i += 8) {
      var rotE = e * 0x100000001;
      var rotA = a * 0x100000001;
      var t1 = (h + ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) + (g ^ (e & (f ^ g))) + constants[i] + words[i]) & _u32Mask;
      d = (d + t1) & _u32Mask;
      h = (t1 + ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) + ((a & b) | (c & (a | b)))) & _u32Mask;

      rotE = d * 0x100000001;
      rotA = h * 0x100000001;
      t1 = (g + ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) + (f ^ (d & (e ^ f))) + constants[i + 1] + words[i + 1]) & _u32Mask;
      c = (c + t1) & _u32Mask;
      g = (t1 + ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) + ((h & a) | (b & (h | a)))) & _u32Mask;

      rotE = c * 0x100000001;
      rotA = g * 0x100000001;
      t1 = (f + ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) + (e ^ (c & (d ^ e))) + constants[i + 2] + words[i + 2]) & _u32Mask;
      b = (b + t1) & _u32Mask;
      f = (t1 + ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) + ((g & h) | (a & (g | h)))) & _u32Mask;

      rotE = b * 0x100000001;
      rotA = f * 0x100000001;
      t1 = (e + ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) + (d ^ (b & (c ^ d))) + constants[i + 3] + words[i + 3]) & _u32Mask;
      a = (a + t1) & _u32Mask;
      e = (t1 + ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) + ((f & g) | (h & (f | g)))) & _u32Mask;

      rotE = a * 0x100000001;
      rotA = e * 0x100000001;
      t1 = (d + ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) + (c ^ (a & (b ^ c))) + constants[i + 4] + words[i + 4]) & _u32Mask;
      h = (h + t1) & _u32Mask;
      d = (t1 + ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) + ((e & f) | (g & (e | f)))) & _u32Mask;

      rotE = h * 0x100000001;
      rotA = d * 0x100000001;
      t1 = (c + ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) + (b ^ (h & (a ^ b))) + constants[i + 5] + words[i + 5]) & _u32Mask;
      g = (g + t1) & _u32Mask;
      c = (t1 + ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) + ((d & e) | (f & (d | e)))) & _u32Mask;

      rotE = g * 0x100000001;
      rotA = c * 0x100000001;
      t1 = (b + ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) + (a ^ (g & (h ^ a))) + constants[i + 6] + words[i + 6]) & _u32Mask;
      f = (f + t1) & _u32Mask;
      b = (t1 + ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) + ((c & d) | (e & (c | d)))) & _u32Mask;

      rotE = f * 0x100000001;
      rotA = b * 0x100000001;
      t1 = (a + ((rotE >> 6) ^ (rotE >> 11) ^ (rotE >> 25)) + (h ^ (f & (g ^ h))) + constants[i + 7] + words[i + 7]) & _u32Mask;
      e = (e + t1) & _u32Mask;
      a = (t1 + ((rotA >> 2) ^ (rotA >> 13) ^ (rotA >> 22)) + ((b & c) | (d & (b | c)))) & _u32Mask;
    }

    return [a, b, c, d, e, f, g, h];
  }

  static List<int> _sha256Init(List<int> data) {
    final words = List<int>.filled(14, 0, growable: true);
    words.add((data[0] << 16) | (data[1] << 8) | data[2]);
    words.add((data[3] << 24) | (data[4] << 16) | (data[5] << 8) | data[6]);

    for (int index = 16; index < 30; index++) {
      int value = _sha256Schedule[index - 16];
      if (index - 2 >= 14) {
        final s1 = _sigma1(words[index - 2]);
        value += (index == 16 ? (s1 ^ _sha256Sigma1Adjustment) : s1);
      }
      if (index - 7 >= 14) {
        value += words[index - 7];
      }
      if (index - 15 >= 14) {
        final s0 = _sigma0(words[index - 15]);
        value += (index == 29 ? (s0 ^ _sha256Sigma0Adjustment) : s0);
      }
      words.add(value & _u32Mask);
    }
    words.add(
      (_sigma1(words[28]) +
       words[23] +
       _sigma0(words[15]) +
       words[14] +
       _sha256Adjustment -
       _sha256RoundConstants[14]) & _u32Mask,
    );
    _expandSha256Schedule(words, 31);
    final working = _sha256Rounds(_sha256State, words, 14);
    return List<int>.generate(8, (i) => (_sha256Initial[i] + working[i]) & _u32Mask);
  }

  static Uint8List _sha256Digest(List<int> data) {
    final length = 57 + data.length;
    final padZeros = ((55 - length) % 64 + 64) % 64;
    final padded = <int>[...data.sublist(7), 0x80, ...List.filled(padZeros, 0)];
    final lenBits = length * 8;
    final bdata = ByteData(8)..setUint64(0, lenBits, Endian.big);
    padded.addAll(bdata.buffer.asUint8List());

    var state = _sha256Init(data.sublist(0, 7));
    for (int offset = 0; offset < padded.length; offset += 64) {
      final chunk = Uint8List.fromList(padded.sublist(offset, offset + 64));
      final chunkData = ByteData.sublistView(chunk);
      final words = <int>[];
      for (int i = 0; i < 64; i += 4) {
        words.add(chunkData.getUint32(i, Endian.big));
      }
      _expandSha256Schedule(words, 16);
      final working = _sha256Rounds(state, words, 0);
      state = List<int>.generate(8, (i) => (state[i] + working[i]) & _u32Mask);
    }

    final out = ByteData(32);
    for (int i = 0; i < 8; i++) {
      out.setUint32(i * 4, state[i], Endian.big);
    }
    return out.buffer.asUint8List();
  }

  static List<int> _cs64Digest(List<int> data, Uint8List digest) {
    final dData = ByteData.sublistView(digest);
    final keyA = dData.getUint32(0, Endian.little) | 1;
    final keyB = dData.getUint32(4, Endian.little) | 1;

    final factorA = (keyA * _cs64Factor) & _u32Mask;
    final factorB = (keyB * _cs64Factor) & _u32Mask;

    final terms = <int>[];
    final offsets = <int>[];

    for (int i = 0; i < _cs64Coefficients.length; i++) {
      final coeff = _cs64Coefficients[i][0];
      final offset = _cs64Coefficients[i][1];
      final factor = (i % 2 == 0) ? factorA : factorB;
      terms.add((coeff * factor) & _u32Mask);
      offsets.add(offset);
    }

    final words = _wordsLe4Even([0, ...data]);
    for (int index = 0; index < words.length; index++) {
      final word = words[index];
      int term = (word * (index % 2 == 0 ? keyA : keyB)) & _u32Mask;
      int offset = (_rol16(word) * (index % 2 == 0 ? 0xEF0569FB : 0xC31713DB)) & _u32Mask;
      if (index == 0) {
        term = (term + _cs64Adjustment0 * factorA) & _u32Mask;
        offset = (offset + _cs64Adjustment1) & _u32Mask;
      }
      terms.add(term);
      offsets.add(offset);
    }

    int swapAcc = 0;
    int swapLast = 0;
    int state = 0;
    int acc = 0;

    for (int index = 0; index < terms.length; index += 2) {
      final x = terms[index];
      final y = terms[index + 1];

      var t = _rol16((offsets[index] + x) & _u32Mask);
      var q = (t * 0x76F50F34) & _u32Mask;
      swapAcc = (swapAcc + ((_rol16(q) * 0xC3EFEA97) & _u32Mask) + q) & _u32Mask;

      t = _rol16((offsets[index + 1] + y) & _u32Mask);
      q = (t * 0x1881CE3C) & _u32Mask;
      swapLast = (((_rol16(q) * 0x35BD1EC9) & _u32Mask) + q) & _u32Mask;
      swapAcc = (swapAcc + swapLast) & _u32Mask;

      state = (state * keyA + x) & _u32Mask;
      state = (_rol16(state) * 0xCF98B111) & _u32Mask;
      state = (_rol16(state) * 0x87085B9F) & _u32Mask;
      state = (_rol16(state) * 0x12CEB96D) & _u32Mask;
      state = (_rol16(state) * 0x257E1D83) & _u32Mask;
      acc = (acc + state) & _u32Mask;

      t = (state * keyB + y) & _u32Mask;
      t = (_rol16(t) * 0xA27416F5) & _u32Mask;
      t = (_rol16(t) * 0xD38396FF) & _u32Mask;
      state = (_rol16((_rol16(t) * 0x7C932B89) & _u32Mask) * 0xBFA49F69) & _u32Mask;
      acc = (acc + state) & _u32Mask;
    }

    return [swapLast ^ state, swapAcc ^ acc];
  }

  static String generateSecMsGecV2([double? unixTimestamp]) {
    double ticks = unixTimestamp ?? (DateTime.now().toUtc().millisecondsSinceEpoch / 1000.0);
    ticks += _winEpoch;
    ticks -= ticks % 300;
    ticks *= _sToNs / 100;
    final strToHash = '${ticks.toStringAsFixed(0)}$_trustedClientToken';
    final data = ascii.encode(strToHash);

    final digest = _sha256Digest(data);
    final cs64Words = _cs64Digest(data, digest);

    final cs64Bytes = ByteData(8)
      ..setUint32(0, cs64Words[0], Endian.little)
      ..setUint32(4, cs64Words[1], Endian.little);

    final cs64Hex = cs64Bytes.buffer.asUint8List().map((b) => b.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();
    final sha256Hex = digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();

    return '$cs64Hex-$sha256Hex';
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
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final selectedVoice = voice ?? getRandomVoice(isUk: isUk);
    final secMsGec = generateSecMsGecV2();
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
