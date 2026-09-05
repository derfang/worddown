import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

void main() {
  Directory('assets/sounds').createSync(recursive: true);
  
  _writeWav('assets/sounds/correct.wav', 800, 0.2); // 800 Hz for 0.2s
  _writeWav('assets/sounds/wrong.wav', 150, 0.4);   // 150 Hz for 0.4s
  print('Sounds generated.');
}

void _writeWav(String path, double frequency, double durationSeconds) {
  int sampleRate = 44100;
  int numSamples = (sampleRate * durationSeconds).toInt();
  int numChannels = 1;
  int bitsPerSample = 16;
  int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
  int blockAlign = numChannels * bitsPerSample ~/ 8;
  int subChunk2Size = numSamples * numChannels * bitsPerSample ~/ 8;
  int chunkSize = 36 + subChunk2Size;

  var builder = BytesBuilder();
  
  // "RIFF"
  builder.add([82, 73, 70, 70]);
  builder.add(_int32ToBytes(chunkSize));
  // "WAVE"
  builder.add([87, 65, 86, 69]);
  
  // "fmt "
  builder.add([102, 109, 116, 32]);
  builder.add(_int32ToBytes(16)); // Subchunk1Size
  builder.add(_int16ToBytes(1));  // AudioFormat (PCM)
  builder.add(_int16ToBytes(numChannels));
  builder.add(_int32ToBytes(sampleRate));
  builder.add(_int32ToBytes(byteRate));
  builder.add(_int16ToBytes(blockAlign));
  builder.add(_int16ToBytes(bitsPerSample));
  
  // "data"
  builder.add([100, 97, 116, 97]);
  builder.add(_int32ToBytes(subChunk2Size));
  
  // Audio data
  for (int i = 0; i < numSamples; i++) {
    double time = i / sampleRate;
    // Generate sine wave
    double value = sin(2 * pi * frequency * time);
    
    // Add a slight decay envelope so it doesn't click at the end
    double envelope = 1.0;
    if (i > numSamples - 4410) { // last 0.1s fade out
      envelope = (numSamples - i) / 4410;
    }
    value *= envelope;
    
    int sample = (value * 32767).toInt();
    builder.add(_int16ToBytes(sample));
  }
  
  File(path).writeAsBytesSync(builder.toBytes());
}

List<int> _int32ToBytes(int value) {
  var data = ByteData(4);
  data.setInt32(0, value, Endian.little);
  return data.buffer.asUint8List();
}

List<int> _int16ToBytes(int value) {
  var data = ByteData(2);
  data.setInt16(0, value, Endian.little);
  return data.buffer.asUint8List();
}
