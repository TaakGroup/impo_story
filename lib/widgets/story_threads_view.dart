import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_slider/carousel_slider.dart';
import 'package:story_view/models/story_events.dart';
import '../controller/story_threads_controller.dart';
import '../models/story_model.dart';
import '../models/story_threads_model.dart';
import 'story_view.dart';

class StoryThreadsView extends StatelessWidget {
  final StoryThreadsController controller;
  final List<StoryThreadsModel> threads;
  final Function(LinkModel link)? onButtonPressed;
  final ButtonStyle? buttonStyle;
  final Function()? onComplete;
  final void Function(StoryModel)? onStoryShow;
  final ButtonStyle? retryButtonStyle;
  final TextStyle? errorTextStyle;
  final Color? indicatorForegroundColor;
  final Widget? title;
  final Widget? avatar;

  const StoryThreadsView({
    Key? key,
    required this.controller,
    required this.threads,
    this.onButtonPressed,
    this.buttonStyle,
    this.onComplete,
    this.onStoryShow,
    this.retryButtonStyle,
    this.errorTextStyle,
    this.indicatorForegroundColor,
    this.title,
    this.avatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CarouselSlider.builder(
        slideTransform: CubeTransform(),
        onSlideChanged: (index) => controller.onPageChanged(threads[index]),
        controller: controller.pageController,
        unlimitedMode: true,
        itemCount: threads.length,
        slideBuilder: (i) => StoryView(
          inline: true,
          showShadow: true,
          onPreviousPressed: controller.previousThreads,
          controller: controller.findController(threads[i].id),
          onComplete: () {
            if (threads[i] == threads.last) {
              onComplete?.call();
            } else {
              controller.nextThreads();
            }
          },
          onStoryShow: onStoryShow,
          retryButtonStyle: retryButtonStyle,
          errorTextStyle: errorTextStyle,
          indicatorForegroundColor: indicatorForegroundColor,
          title: title,
          avatar: avatar,
          storyItems: [
            for (int j = 0; j < threads.length; j++)
              StoryItem.fromModel(
                threads[i].stories[j],
                controller.findController(threads[i].id),
                onButtonPressed: onButtonPressed,
                buttonStyle: buttonStyle,
              )
          ],
        ),
      ),
    );
  }
}
