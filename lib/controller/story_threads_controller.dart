import 'package:flutter/cupertino.dart';
import 'package:story_view/controller/story_controller.dart';

class StoryThreadsController {
  PageController pageController = PageController();
  Map<String, StoryController> _controllers = {};

  StoryThreadsController() {
    pageController.addListener(() {
      // Todo : stop last thread
      // if(pageController.page! % 1 == 0) {
      //   _controllers.values.last.pause();
      // }
    });
  }

  jumpTo(int index) => pageController.jumpTo(index.toDouble());

  void nextThreads() => pageController.nextPage(duration: Duration(milliseconds: 200), curve: Curves.linear);

  StoryController findController(String id) => _controllers[id] ??= StoryController();
}
