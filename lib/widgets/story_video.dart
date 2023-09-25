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
  final Rx<StoryPipeline> state;

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
    required Rx<StoryPipeline> state,
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
    SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(StoryPipeline(storyState: StoryState.loading)));

    this.playerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    playerController!.initialize().then(
      (v) {
        SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(StoryPipeline(storyState: StoryState.success)));

        playerController!.addListener(() {
          if (this.playerController!.value.isPlaying) {
            if (widget.state.value.progressEvent != StoryEvent.play) {
              widget.storyController!.play();
              widget.state(StoryPipeline(videoEvent: StoryEvent.play));
            }
          } else if (!this.playerController!.value.isCompleted) {
            if (widget.state.value.progressEvent != StoryEvent.pause) {
              widget.storyController!.pause();
              widget.state(StoryPipeline(videoEvent: StoryEvent.pause));
            }
          }

          widget.state(StoryPipeline(progressEvent: StoryEvent.none));
        });

        widget.storyController!.playbackNotifier.listen((value) {
          if (value == PlaybackState.play) {
            if (widget.state.value.videoEvent != StoryEvent.play) {
              playerController!.play();
              widget.state(StoryPipeline(progressEvent: StoryEvent.play));
            }
            widget.state(StoryPipeline(videoEvent: StoryEvent.none));
          } else if (value == PlaybackState.pause) {
            if (widget.state.value.videoEvent != StoryEvent.pause) {
              playerController!.pause();
              widget.state(StoryPipeline(progressEvent: StoryEvent.pause));
            }
          }
        });

        playerController!.play();

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
        SchedulerBinding.instance
            .addPostFrameCallback((_) => widget.state(StoryPipeline(storyState: StoryState.failure, retry: initializeVideo)));
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
        if (widget.state.value.storyState == StoryState.success) {
          return Center(
            child: AspectRatio(
              aspectRatio: playerController!.value.aspectRatio,
              child: VideoPlayer(playerController!),
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
    // return Container(
    //   color: Colors.black,
    //   width: double.infinity,
    //   height: double.infinity,
    //   child: getContentView(),
    // );

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
    playerController?.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
