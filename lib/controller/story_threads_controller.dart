import 'package:flutter/cupertino.dart';
import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/models/story_threads_model.dart';

class StoryThreadsController {
  PageController pageController = PageController();
  Map<String, StoryController> _controllers = {};

  jumpTo(int index) => pageController.jumpToPage(index);

  void nextThreads() => pageController.nextPage(duration: Duration(milliseconds: 500), curve: Curves.linear);

  void previousThreads() => pageController.previousPage(duration : Duration(milliseconds: 500), curve: Curves.linear);

  StoryController findController(String id) => _controllers[id] ??= StoryController();

  void onPageChanged(StoryThreadsModel thread) {
    _controllers.forEach((key, value) => value.pause());
    findController(thread.id).play();
  }
}
