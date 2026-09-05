import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    print('Fetching manifest...');
    final manifest = await yt.videos.streamsClient.getManifest('dQw4w9WgXcQ');
    print('Got manifest');
    final streamInfo = manifest.muxed.withHighestBitrate();
    print('URL: ${streamInfo.url}');
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
