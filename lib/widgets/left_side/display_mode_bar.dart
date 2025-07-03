import 'package:flutter/material.dart';
import 'package:svga_previewer/view_models/svga_view_model.dart';
import 'package:svgaplayer_flutter/player.dart';

class DisplayModeBar extends StatelessWidget {
  final SVGAViewModel viewModel;
  final SVGAAnimationController controller;

  const DisplayModeBar({super.key, required this.viewModel, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,  // 使用 Scaffold 的默认背景色
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade800,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('排版模式:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 10),
              _ModeButton(
                mode: DisplayMode.showAll, 
                isSelected: viewModel.mode == DisplayMode.showAll, 
                onTap: () {
                  // DisplayMode oldMode = viewModel.mode;
                  viewModel.setMode(DisplayMode.showAll);
                  // 📌 切换回来会重新创建SVGAPreview重新播放，这里就不用控制动画了，后续再优化
                  // print("fffffff videoItem: ${controller.videoItem != null}, isAnimating: ${controller.isAnimating}");
                  // if (controller.videoItem != null && oldMode == DisplayMode.showBottom && controller.isAnimating == false) {
                  //   if (controller.isCompleted == true) {
                  //     controller.reset();
                  //   }
                  //   controller.repeat();
                  // }
                },
              ),
              const SizedBox(width: 12),
              _ModeButton(
                mode: DisplayMode.showTop, 
                isSelected: viewModel.mode == DisplayMode.showTop, 
                onTap: () {
                  // DisplayMode oldMode = viewModel.mode;
                  viewModel.setMode(DisplayMode.showTop);
                  // 📌 切换回来会重新创建SVGAPreview重新播放，这里就不用控制动画了，后续再优化
                  // print("fffffff videoItem: ${controller.videoItem != null}, isAnimating: ${controller.isAnimating}");
                  // if (controller.videoItem != null && oldMode == DisplayMode.showBottom && controller.isAnimating == false) {
                  //   if (controller.isCompleted == true) {
                  //     controller.reset();
                  //   }
                  //   controller.repeat();
                  // }
                },
              ),
              const SizedBox(width: 12),
              _ModeButton(
                mode: DisplayMode.showBottom, 
                isSelected: viewModel.mode == DisplayMode.showBottom, 
                onTap: () {
                  // print("fffffff videoItem: ${controller.videoItem != null}, isAnimating: ${controller.isAnimating}");
                  if (controller.videoItem != null && controller.isAnimating == true) {
                    controller.stop();
                  }
                  viewModel.setMode(DisplayMode.showBottom);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final DisplayMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color = isSelected ? Colors.blue.shade200 : Colors.grey.shade800;

    IconData? icon;
    switch (mode) {
      case DisplayMode.showAll:
        icon = Icons.vertical_align_center;
        break;
      case DisplayMode.showTop:
        icon = Icons.vertical_align_bottom;
        break;
      case DisplayMode.showBottom:
        icon = Icons.vertical_align_top;
        break;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          border: Border.all(
            color: color,  
            width: 1.5,           
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Center(
          child: Icon(
            icon,         
            color: color,
            size: 15,
          ),
        ),
      ),
    );
  }
}