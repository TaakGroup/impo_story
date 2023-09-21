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
    bool isBuffering = false;
    widget.storyController!.pause();
    SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(LoadStateEvent(LoadState.loading)));

    this.playerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    playerController!.initialize().then((v) {
      SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(LoadStateEvent(LoadState.success)));
      widget.storyController!.play();
    }, onError: (_) {
      SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(LoadStateEvent(LoadState.failure, initializeVideo)));
    });

    playerController?.addListener(() {
      print('1'*100);
      if (this.playerController?.value.isPlaying ?? false) {
        print('2'*100);
        // Video played
        if (widget.storyController?.playbackNotifier.isPaused ?? false) {
          print('3'*100);
          // if story Paused
          widget.storyController!.play();
          isBuffering = false;
        }
      } else {
        print('4'*100);
        // Video paused
        if (!(widget.storyController?.playbackNotifier.isPaused ?? true)) {
          print('5'*100);
          // if story is played
          widget.storyController!.pause();
          isBuffering = true;
        }
      }
    });

    if (widget.storyController != null) {
      _streamSubscription = widget.storyController!.playbackNotifier.listen((playbackState) {
        print('6'*100);
        if (playbackState == PlaybackState.pause) {
          print('7'*100);
          // Story paused
          // if (!isBuffering)
            print('8'*100);
            playerController!.pause(); // video paused

        } else {
          print('9'*100);
          // if (!isBuffering)
            print('10'*100);
            playerController!.play(); // video played

        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initializeVideo();
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
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.height * 9 / 16,
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
