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
  // Fallback URL after HF lookup; if HF also fails, this stays null and we use original CDN.
  String? _fallbackUrl;

  @override
  void initState() {
    super.initState();
    _checkLocalCache();
  }

  Future<void> _checkLocalCache() async {
    // 1. Check local disk cache (instant — was already downloaded before)
    final file = await MediaCacheService.getLocalFile(widget.wordId, widget.imageUrl);
    if (file != null) {
      if (mounted) setState(() => _localFile = file);
      return;
    }

    // 2. Try to fetch from Hugging Face backup (encrypted → decrypt → save to disk)
    final hfFile = await MediaCacheService.fetchAndDecryptFromHuggingFace(
      widget.wordId,
      widget.imageUrl,
    );
    if (hfFile != null) {
      if (mounted) setState(() => _localFile = hfFile);
      return;
    }

    // 3. Fall back to original CDN URL and cache it for next time
    MediaCacheService.cacheSingleMedia(widget.wordId, widget.imageUrl).then((downloaded) {
      if (mounted && downloaded != null) {
        setState(() => _localFile = downloaded);
      } else if (mounted) {
        // Let Image.network render directly from the CDN URL
        setState(() => _fallbackUrl = widget.imageUrl);
      }
    }).catchError((_) {
      if (mounted) setState(() => _fallbackUrl = widget.imageUrl);
    });
  }

  @override
  void didUpdateWidget(CachedMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.wordId != widget.wordId) {
      setState(() {
        _localFile = null;
        _fallbackUrl = null;
      });
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
    } else if (_fallbackUrl != null) {
      return Image.network(
        _fallbackUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: widget.errorBuilder,
      );
    } else {
      // Still loading — show sized placeholder
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
  }
}
