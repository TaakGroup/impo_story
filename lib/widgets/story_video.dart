import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../utils.dart';
import '../controller/story_controller.dart';

class StoryVideo extends StatefulWidget {
  final StoryController? storyController;
  final VideoPlayerController playerController;
  final Rx<StoryPipeline> state;
  final TextStyle? errorTextStyle;

  StoryVideo({
    Key? key,
    this.storyController,
    required this.state,
    this.errorTextStyle,
    required this.playerController,
  }) : super(key: key ?? UniqueKey());

  static StoryVideo url(
    String url, {
    StoryController? controller,
    Map<String, dynamic>? requestHeaders,
    TextStyle? errorTextStyle,
    required Rx<StoryPipeline> state,
    Key? key,
  }) {
    return StoryVideo(
      storyController: controller,
      state: state,
      errorTextStyle: errorTextStyle,
      key: key,
      playerController: VideoPlayerController.networkUrl(Uri.parse(url))..initialize(),
    );
  }

  @override
  State<StatefulWidget> createState() {
    return StoryVideoState();
  }
}

class StoryVideoState extends State<StoryVideo> {
  Future<void>? playerLoader;
  StreamSubscription? _streamSubscription;

  initializeVideo() {
    widget.storyController!.pause();
    SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(StoryPipeline(storyState: StoryState.loading)));

    widget.playerController.addListener(() {
      if(widget.playerController.value.isInitialized) {
        SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(StoryPipeline(storyState: StoryState.success)));
        widget.storyController!.attachVideoController(widget.playerController);
        widget.playerController.play();
      }
    });

    // this.playerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    // playerController!.initialize().then(
    //   (v) {
    //
    //   },
    //   onError: (_) {
    //     SchedulerBinding.instance
    //         .addPostFrameCallback((_) => widget.state(StoryPipeline(storyState: StoryState.failure, retry: initializeVideo)));
    //   },
    // );
  }

  @override
  void initState() {
    initializeVideo();
    super.initState();
  }

  Widget getContentView() {
    return Obx(
      () {
        if (widget.state.value.storyState == StoryState.success) {
          return Center(
            child: AspectRatio(
              aspectRatio: widget.playerController.value.aspectRatio,
              child: VideoPlayer(widget.playerController),
            ),
          );
        } else if (widget.state.value.storyState == StoryState.loading) {
          return Center(
            child: Container(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
          );
        } else {
          return SizedBox();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: MediaQuery.of(context).size.height * 9 / 16,
            height: MediaQuery.of(context).size.height,
            child: getContentView(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.playerController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
