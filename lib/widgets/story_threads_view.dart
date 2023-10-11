import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../controller/story_threads_controller.dart';
import '../models/story_threads_model.dart';
import 'story_view.dart';

class StoryThreadsView extends StatefulWidget {
  final StoryThreadsController controller;
  final List<StoryThreadsModel> threads;

  const StoryThreadsView({Key? key, required this.controller, required this.threads}) : super(key: key);



  @override
  State<StoryThreadsView> createState() => _StoryThreadsViewState();
}

class _StoryThreadsViewState extends State<StoryThreadsView> {

  double currentPageValue = 1;

  @override
  void initState() {
    super.initState();
    // widget.controller.pageController = PageController(initialPage: widget.initialPage);
    //
    // currentPageValue = widget.initialPage.toDouble();

    widget.controller.pageController!.addListener(() {
      setState(() {
        currentPageValue = widget.controller.pageController!.page!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
          controller: widget.controller.pageController,
          itemCount: widget.threads.length,
          itemBuilder: (_, i) {
            final isLeaving = (i - widget.controller.pageController.page!) <= 0;
            final t = (i - widget.controller.pageController.page!);
            final rotationY = lerpDouble(0, 30, t)!;
            const maxOpacity = 0.8;
            final num opacity =
            lerpDouble(0, maxOpacity, t.abs())!.clamp(0.0, maxOpacity);
            final isPaging = opacity != maxOpacity;
            final transform = Matrix4.identity();
            transform.setEntry(3, 2, 0.003);
            transform.rotateY(-rotationY * (pi / 180.0));
            return Transform(
              alignment: isLeaving ? Alignment.centerRight : Alignment.centerLeft,
              transform: transform,
              child: StoryView(
                controller: widget.controller.find(widget.threads[i].id),
                storyItems: [
                  for (int j = 0; j < widget.threads.length; j++)
                    StoryItem.fromModel(
                      widget.threads[i].stories[j],
                      widget.controller.find(widget.threads[i].id),
                    )
                ],
              ),
            );
          }
      ),
    );
  }
}
