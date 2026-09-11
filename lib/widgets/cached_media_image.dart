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
    // 1. Check local disk cache (instant — if was already cached/pre-cached)
    final file = await MediaCacheService.getLocalFile(widget.wordId, widget.imageUrl);
    if (file != null && await file.exists() && await file.length() > 0) {
      if (mounted) setState(() => _localFile = file);
      return;
    }

    // 2. Not yet on disk — start ensuring media is cached via Hugging Face or CDN.
    // If it takes longer than 250ms, kick off Image.network fallback so the user
    // never stares at a stalled spinner while downloading.
    bool resolved = false;
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!resolved && mounted && _localFile == null && _fallbackUrl == null) {
        setState(() => _fallbackUrl = widget.imageUrl);
      }
    });

    final cachedFile = await MediaCacheService.ensureMediaCached(
      widget.wordId,
      widget.imageUrl,
    );
    resolved = true;

    if (mounted) {
      if (cachedFile != null) {
        setState(() => _localFile = cachedFile);
      } else if (_fallbackUrl == null) {
        setState(() => _fallbackUrl = widget.imageUrl);
      }
    }
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
