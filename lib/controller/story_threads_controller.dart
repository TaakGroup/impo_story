import 'package:flutter/cupertino.dart';
import 'package:flutter_carousel_slider/carousel_slider.dart';
import 'package:story_view/controller/story_controller.dart';

class StoryThreadsController {
  CarouselSliderController pageController = CarouselSliderController();
  Map<String, StoryController> _controllers = {};

  // jumpTo(int index) => pageController.(index);

  void nextThreads() => pageController.nextPage(Duration(milliseconds: 500));

  void previousThreads() => pageController.previousPage(Duration(milliseconds: 500));

  StoryController findController(String id) => _controllers[id] ??= StoryController();

  void onPageChanged(thread) {}
}
