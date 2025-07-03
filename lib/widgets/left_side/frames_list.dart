import 'package:flutter/material.dart';
import 'package:svga_previewer/view_models/svga_view_model.dart';

class FramesList extends StatelessWidget {
  final SVGAViewModel viewModel;

  const FramesList({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: ValueKey(viewModel.currentFileName),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: viewModel.frames.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => viewModel.setCurrentFrameIndex(index),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: index == viewModel.currentFrameIndex
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade800,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Image.file(
                    viewModel.frames[index],
                    key: ValueKey('frame_${viewModel.currentFileName}_$index'),
                    fit: BoxFit.contain,
                    cacheWidth: null,
                    cacheHeight: null,
                    gaplessPlayback: false,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  color: Colors.black45,
                  child: Text(
                    '图 ${index + 1}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}