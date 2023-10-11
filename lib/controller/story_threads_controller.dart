import 'package:flutter/cupertino.dart';
import 'package:story_view/controller/story_controller.dart';

class StoryThreadsController {
  PageController pageController = PageController();
  Map<String, StoryController> _controllers = {};

  StoryController find(String id) => _controllers[id] ??= StoryController();
}
