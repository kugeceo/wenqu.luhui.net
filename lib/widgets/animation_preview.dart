import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:svga_previewer/view_models/svga_view_model.dart';
import 'package:svga_previewer/widgets/svga_preview.dart';
import 'package:svgaplayer_flutter/player.dart';

class AnimationPreview extends StatelessWidget {
  final SVGAAnimationController controller;
  
  const AnimationPreview({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Consumer<SVGAViewModel>(
        builder: (context, viewModel, child) {
          return Container(
            decoration: BoxDecoration(
              color: viewModel.previewBackgroundColor,
              border: viewModel.showBorder ? Border.all(
                color: Colors.grey.shade800,
                width: 1,
              ) : null,
              borderRadius: viewModel.showBorder ? BorderRadius.circular(4) : null,
            ),
            child: viewModel.svgaFile == null
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('无预览'),
                  )
                : SVGAPreview(controller: controller, file: viewModel.svgaFile!),
          );
        },
      ),
    );
  }
} 