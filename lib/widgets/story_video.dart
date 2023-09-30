import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../utils.dart';
import '../controller/story_controller.dart';

class StoryVideo extends StatefulWidget {
  final StoryController storyController;
  final TextStyle? errorTextStyle;
  final String videoUrl;
  final Rx<StoryPipeline> state;

  StoryVideo(
    this.videoUrl, {
    required this.storyController,
    required this.state,
    this.errorTextStyle,
    Key? key,
  }) : super(key: key ?? UniqueKey());

  static StoryVideo url(
    String url, {
    required StoryController controller,
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

  initializeVideo() async {
    widget.storyController.playerController = null;
    widget.storyController.pause();
    SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(StoryPipeline(storyState: StoryState.loading)));

    final fileInfo = await StoryCacheManager.instance.getFileFromCache(widget.videoUrl);

    if (fileInfo != null) {
      this.playerController = VideoPlayerController.file(fileInfo.file);
    } else {
      this.playerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    }

    playerController?.initialize().then(
      (v) {
        widget.storyController.attachVideoController(playerController!);

        playerController?.addListener(() {
          if (playerController!.value.isPlaying) {
            SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(StoryPipeline(storyState: StoryState.success)));
          } else if (playerController!.value.isBuffering) {
            SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(StoryPipeline(storyState: StoryState.buffering)));
          }
        });

        playerController!.play();
      },
      onError: (_) {
        SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(StoryPipeline(storyState: StoryState.failure, retry: initializeVideo)));
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
        if (widget.state.value.storyState == StoryState.success || widget.state.value.storyState == StoryState.buffering) {
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
    return Container(
      color: Colors.black,
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width * 1920 / 1080,
            child: getContentView(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.storyController.playerController = null;
    SchedulerBinding.instance.addPostFrameCallback((_) => widget.state(StoryPipeline(storyState: StoryState.loading)));
    playerController?.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
