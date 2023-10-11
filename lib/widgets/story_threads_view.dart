import 'package:flutter/material.dart';
import '../controller/story_threads_controller.dart';
import '../models/story_threads_model.dart';
import 'story_view.dart';

class StoryThreadsView extends StatelessWidget {
  final StoryThreadsController controller;
  final List<StoryThreadsModel> threads;

  const StoryThreadsView({Key? key, required this.controller, required this.threads}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: controller.pageController,
        itemCount: threads.length,
        itemBuilder: (_, i) => StoryView(
          controller: controller.find(threads[i].id),
          storyItems: [
            for (int j = 0; j < threads.length; j++)
              StoryItem.fromModel(
                threads[i].stories[j],
                controller.find(threads[i].id),
              )
          ],
        ),
      ),
    );
  }
}
