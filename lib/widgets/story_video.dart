import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../utils.dart';
import '../controller/story_controller.dart';

class StoryVideo extends StatefulWidget {
  final StoryController? storyController;
  final TextStyle? errorTextStyle;
  final String videoUrl;
  final Rx<LoadStateEvent> state;

  StoryVideo(
    this.videoUrl, {
    this.storyController,
    required this.state,
    this.errorTextStyle,
    Key? key,
  }) : super(key: key ?? UniqueKey());

  static StoryVideo url(
    String url, {
    StoryController? controller,
    Map<String, dynamic>? requestHeaders,
    TextStyle? errorTextStyle,
    required Rx<LoadStateEvent> state,
    Key? key,
  }) {
    return StoryVideo(
      url,
      storyController: controller,
      state: state,
      errorTextStyle: errorTextStyle,
      key: key,
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
  VideoPlayerController? playerController;

  initializeVideo() {
    widget.storyController!.pause();
    SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(LoadStateEvent(LoadState.loading)));

    this.playerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    playerController!.initialize().then(
      (v) {
        SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(LoadStateEvent(LoadState.success)));
        widget.storyController!.play();
        playerController!.play();

        playerController!.addListener(() {
          if (this.playerController!.value.isPlaying) {
            widget.storyController!.play();
          } else if (!this.playerController!.value.isCompleted) {
            widget.storyController!.next();
          } else {
            widget.storyController!.pause();
          }
        });

        // if (widget.storyController != null) {
        //   _streamSubscription = widget.storyController!.playbackNotifier.listen((playbackState) {
        //     if (playbackState == PlaybackState.play) {
        //       // Story paused
        //       if (videoEvent != StoryEvent.play && videoEvent != StoryEvent.pause) {
        //         progressEvent = StoryEvent.play;
        //         playerController!.play();
        //       }
        //
        //       if (videoEvent == StoryEvent.pause) {
        //         widget.storyController!.pause();
        //       }
        //
        //       // video paused
        //     } else if (playbackState == PlaybackState.pause) {
        //       // Story played
        //       if (videoEvent != StoryEvent.pause) {
        //         progressEvent = StoryEvent.pause;
        //         playerController!.pause();
        //       }
        //     }
        //   });
        // }
      },
      onError: (_) {
        SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(LoadStateEvent(LoadState.failure, initializeVideo)));
      },
    );
  }

  @override
  void initState() {
    initializeVideo();
    super.initState();
  }

  Widget getContentView() {
    return Obx(
      () {
        if (widget.state.value.loadState == LoadState.success) {
          return Center(
            child: AspectRatio(
              aspectRatio: playerController!.value.aspectRatio,
              child: VideoPlayer(playerController!),
            ),
          );
        } else if (widget.state.value.loadState == LoadState.loading) {
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
      width: double.infinity,
      height: double.infinity,
      child: getContentView(),
    );

    // return Container(
    //   color: Colors.black,
    //   child: OverflowBox(
    //     maxWidth: double.infinity,
    //     maxHeight: double.infinity,
    //     child: FittedBox(
    //       fit: BoxFit.cover,
    //       child: SizedBox(
    //         height: MediaQuery.of(context).size.height * 9 / 16,
    //         width: MediaQuery.of(context).size.width,
    //         child: getContentView(),
    //       ),
    //     ),
    //   ),
    // );
  }

  @override
  void dispose() {
    playerController?.pause();
    playerController?.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
