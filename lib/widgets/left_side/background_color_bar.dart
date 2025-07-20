import 'package:flutter/material.dart';
import 'package:svga_previewer/view_models/svga_view_model.dart';

class BackgroundColorBar extends StatelessWidget {
  final SVGAViewModel viewModel;

  const BackgroundColorBar({super.key, required this.viewModel});

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
          const Text('背景颜色:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ColorButton(
                color: Colors.transparent,
                isSelected: viewModel.previewBackgroundColor == Colors.transparent,
                onTap: () => viewModel.setPreviewBackgroundColor(Colors.transparent),
              ),
              _ColorButton(
                color: Colors.black,
                isSelected: viewModel.previewBackgroundColor == Colors.black,
                onTap: () => viewModel.setPreviewBackgroundColor(Colors.black),
              ),
              _ColorButton(
                color: Colors.white,
                isSelected: viewModel.previewBackgroundColor == Colors.white,
                onTap: () => viewModel.setPreviewBackgroundColor(Colors.white),
              ),
              _ColorButton(
                color: Colors.grey,
                isSelected: viewModel.previewBackgroundColor == Colors.grey,
                onTap: () => viewModel.setPreviewBackgroundColor(Colors.grey),
              ),
              _ColorButton(
                color: Colors.deepPurpleAccent,
                isSelected: viewModel.previewBackgroundColor == Colors.deepPurpleAccent,
                onTap: () => viewModel.setPreviewBackgroundColor(Colors.deepPurpleAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepPurpleAccent.shade100 : Colors.grey.shade800,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: color == Colors.transparent ? Center(
          child: Transform.rotate(
            angle: -0.785398,
            child: Container(
              width: 28,
              height: 2,
              color: Colors.red,
            ),
          ),
        ) : null,
      ),
    );
  }
} 