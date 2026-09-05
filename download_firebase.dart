import 'dart:io';

void main() async {
  final url = Uri.parse('https://dl.google.com/firebase/sdk/cpp/firebase_cpp_sdk_windows_13.11.0.zip');
  final file = File('build/windows/x64/firebase_cpp_sdk_windows_13.11.0.zip');
  
  if (!await Directory('build/windows/x64').exists()) {
    await Directory('build/windows/x64').create(recursive: true);
  }

  print('Starting robust download from $url');
  
  while (true) {
    int downloadedBytes = 0;
    if (await file.exists()) {
      downloadedBytes = await file.length();
    }
    
    final client = HttpClient();
    client.autoUncompress = false;
    try {
      final request = await client.getUrl(url);
      if (downloadedBytes > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$downloadedBytes-');
        print('Resuming from $downloadedBytes bytes...');
      } else {
        print('Starting fresh download...');
      }
      
      final response = await request.close();
      
      if (response.statusCode == 200 || response.statusCode == 206) {
        final expectedLength = response.contentLength;
        final totalLength = response.statusCode == 206 ? downloadedBytes + expectedLength : expectedLength;
        
        print('Target size: ${totalLength ~/ (1024 * 1024)} MB');
        
        final sink = file.openWrite(mode: downloadedBytes > 0 ? FileMode.append : FileMode.write);
        
        await for (var data in response) {
          sink.add(data);
          downloadedBytes += data.length;
          
          if (downloadedBytes % (5 * 1024 * 1024) < data.length) {
            print('Downloaded ${downloadedBytes ~/ (1024 * 1024)} MB / ${totalLength ~/ (1024 * 1024)} MB');
          }
        }
        await sink.close();
        
        if (downloadedBytes == totalLength || expectedLength == -1) {
          print('Download completed successfully!');
          break;
        }
      } else if (response.statusCode == 416) {
        print('Already fully downloaded (416 Range Not Satisfiable).');
        break;
      } else {
        print('Unexpected status code: ${response.statusCode}');
        await Future.delayed(Duration(seconds: 3));
      }
    } catch (e) {
      print('Connection dropped: $e');
      print('Reconnecting in 2 seconds...');
      await Future.delayed(Duration(seconds: 2));
    } finally {
      client.close();
    }
  }
}
