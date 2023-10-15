import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:story_view/models/story_events.dart';
import '../controller/story_threads_controller.dart';
import '../models/story_model.dart';
import '../models/story_threads_model.dart';
import 'story_view.dart';
import 'dart:math' as math;

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
      backgroundColor: Colors.black,
      body: CubePageView(
        onPageChanged: (index) => controller.onPageChanged(threads[index]),
        controller: controller.pageController,
        // itemCount: threads.length,
        children: [
          for (var model in threads)
            StoryView(
              inline: true,
              showShadow: true,
              onPreviousPressed: controller.previousThreads,
              controller: controller.findController(model.id),
              onComplete: () {
                if (threads == threads.last) {
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
                    model.stories[j],
                    controller.findController(model.id),
                    onButtonPressed: onButtonPressed,
                    buttonStyle: buttonStyle,
                  )
              ],
            )
        ],
      ),
    );
  }
}

/// This Widget has the [PageView] widget inside.
/// It works in two modes :
///   1 - Using the default constructor [CubePageView] passing the items in `children` property.
///   2 - Using the factory constructor [CubePageView.builder] passing a `itemBuilder` and `itemCount` properties.
class CubePageView extends StatefulWidget {
  /// Called whenever the page in the center of the viewport changes.
  final ValueChanged<int> onPageChanged;

  /// An object that can be used to control the position to which this page
  /// view is scrolled.
  final PageController controller;

  /// Widgets you want to use inside the [CubePageView], this is only required if you use [CubePageView] constructor
  final List<Widget> children;

  /// Creates a scrollable list that works page by page from an explicit [List]
  /// of widgets.
  const CubePageView({
    Key? key,
    required this.onPageChanged,
    required this.controller,
    required this.children,
  }) : super(key: key);

  /// Creates a scrollable list that works page by page using widgets that are
  /// created on demand.
  ///
  /// This constructor is appropriate if you want to customize the behavior
  ///
  /// Providing a non-null [itemCount] lets the [CubePageView] compute the maximum
  /// scroll extent.
  ///
  /// [itemBuilder] will be called only with indices greater than or equal to
  /// zero and less than [itemCount].
  CubePageView.builder({
    Key? key,
    required this.onPageChanged,
    required this.controller,
    required this.children,
  }) : super(key: key);

  @override
  _CubePageViewState createState() => _CubePageViewState();
}

class _CubePageViewState extends State<CubePageView> {
  final _pageNotifier = ValueNotifier(0.0);
  late PageController _pageController;

  void _listener() {
    _pageNotifier.value = _pageController.page!;
  }

  @override
  void initState() {
    widget.children.reversed;
    _pageController = widget.controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.addListener(_listener);
    });
    super.initState();
  }

  @override
  void dispose() {
    _pageController.removeListener(_listener);
    _pageController.dispose();
    _pageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _pageNotifier,
      builder: (_, value, child) => PageView.builder(
        controller: _pageController,
        onPageChanged: widget.onPageChanged,
        physics: const ClampingScrollPhysics(),
        itemCount: widget.children.length,
        itemBuilder: (_, index) {
          return CubeWidget(
            child: widget.children[index],
            index: index,
            pageNotifier: value,
          );
        },
      ),
    );
  }
}

/// This widget has the logic to do the 3D cube transformation
/// It only should be used if you use [CubePageView.builder]
class CubeWidget extends StatelessWidget {
  /// Index of the current item
  final int index;

  /// Page Notifier value, it comes from the [CubeWidgetBuilder]
  final double pageNotifier;

  /// Child you want to use inside the Cube
  final Widget child;

  const CubeWidget({
    Key? key,
    required this.index,
    required this.pageNotifier,
    required this.child,
  }) : super(key: key);

  double degToRad(num deg) => deg * (math.pi / 180.0);

  @override
  Widget build(BuildContext context) {
    final isLeaving = (index - pageNotifier) <= 0;
    final t = (index - pageNotifier);
    final rotationY = lerpDouble(0, 60, t);
    final opacity = lerpDouble(0, 1, t.abs())?.clamp(0.0, 1.0);
    final transform = Matrix4.identity();
    transform.setEntry(3, 2, 0.003);
    transform.rotateY(-degToRad(rotationY ?? 0));
    return Transform(
      alignment: isLeaving ? Alignment.centerRight : Alignment.centerLeft,
      transform: transform,
      child: Stack(
        children: [
          child,
          // IgnorePointer(
          //   child: Positioned.fill(
          //     child: Opacity(
          //       opacity: opacity ?? 1,
          //       child: Container(
          //         color: Colors.black,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
