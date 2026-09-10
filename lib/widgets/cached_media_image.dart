import 'dart:io';
import 'package:flutter/material.dart';
import '../services/media_cache_service.dart';

class CachedMediaImage extends StatefulWidget {
  final int wordId;
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const CachedMediaImage({
    Key? key,
    required this.wordId,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.errorBuilder,
  }) : super(key: key);

  @override
  _CachedMediaImageState createState() => _CachedMediaImageState();
}

class _CachedMediaImageState extends State<CachedMediaImage> {
  File? _localFile;

  @override
  void initState() {
    super.initState();
    _checkLocalCache();
  }

  Future<void> _checkLocalCache() async {
    final file = await MediaCacheService.getLocalFile(widget.wordId, widget.imageUrl);
    if (mounted) {
      if (file != null) {
        setState(() {
          _localFile = file;
        });
      } else {
        // Asynchronously cache on demand
        MediaCacheService.cacheSingleMedia(widget.wordId, widget.imageUrl).then((downloadedFile) {
          if (mounted && downloadedFile != null) {
            setState(() {
              _localFile = downloadedFile;
            });
          }
        }).catchError((_) {});
      }
    }
  }

  @override
  void didUpdateWidget(CachedMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.wordId != widget.wordId) {
      _checkLocalCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_localFile != null) {
      return Image.file(
        _localFile!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: widget.errorBuilder,
      );
    } else {
      return Image.network(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: widget.errorBuilder,
      );
    }
  }
}
