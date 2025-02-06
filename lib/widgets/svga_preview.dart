import 'package:flutter/material.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'dart:io';

class SVGAPreview extends StatefulWidget {
  final File file;
  
  const SVGAPreview({super.key, required this.file});
  
  @override
  State<SVGAPreview> createState() => _SVGAPreviewState();
}

class _SVGAPreviewState extends State<SVGAPreview> with SingleTickerProviderStateMixin {
  late SVGAAnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = SVGAAnimationController(vsync: this);
    _loadSVGA();
  }

  @override
  void didUpdateWidget(SVGAPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _loadSVGA();
    }
  }
  
  Future<void> _loadSVGA() async {
    try {
      _controller.reset();
      final parser = SVGAParser();
      final videoItem = await parser.decodeFromBuffer(
        await widget.file.readAsBytes(),
      );
      if (mounted) {
        _controller.videoItem = videoItem;
        _controller.repeat();
      }
    } catch (e) {
      print('加载SVGA文件失败: $e');
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SVGAImage(_controller);
  }
} 