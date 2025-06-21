import 'package:flutter/material.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'dart:io';

class SVGAPreview extends StatefulWidget {
  final SVGAAnimationController controller;
  final File file;
  
  const SVGAPreview({super.key, required this.controller, required this.file});
  
  @override
  State<SVGAPreview> createState() => _SVGAPreviewState();
}

class _SVGAPreviewState extends State<SVGAPreview> {
  @override
  void initState() {
    super.initState();
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
      print("jpjpjp 11111111 ${widget.controller.hashCode}"); 
      widget.controller.reset();
      print("jpjpjp 222222222"); 
      final parser = SVGAParser();
      print("jpjpjp ${parser.hashCode}"); 
      final videoItem = await parser.decodeFromBuffer(
        await widget.file.readAsBytes(),
      );
      if (mounted) {
        widget.controller.videoItem = videoItem;
        widget.controller.repeat();
      }
    } catch (e) {
      print('jpjpjp 加载SVGA文件失败: $e');
    }
  }
  
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SVGAImage(widget.controller);
  }
} 