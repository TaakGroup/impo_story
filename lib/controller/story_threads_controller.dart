import 'package:flutter/cupertino.dart';
import 'package:story_view/controller/story_controller.dart';

class StoryThreadsController {
  PageController pageController = PageController();
  Map<String, StoryController> _controllers = {};

  StoryThreadsController() {
    pageController.addListener(() {
      // Todo : stop last thread
    });
  }

  jumpTo(int index) => pageController.jumpTo(index.toDouble());

  StoryController findController(String id) => _controllers[id] ??= StoryController();
}
