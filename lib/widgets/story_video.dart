import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../utils.dart';
import '../controller/story_controller.dart';

class VideoLoader {
  String url;

  File? videoFile;

  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading;

  final Rx<LoadStateEvent> loadEvent;

  VideoLoader(this.url, this.loadEvent, {this.requestHeaders});

  void loadVideo(VoidCallback onComplete) {
    this.state = LoadState.loading;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      loadEvent(LoadStateEvent(LoadState.loading));
    });

    if (this.videoFile != null) {
      this.state = LoadState.success;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        loadEvent(LoadStateEvent(LoadState.success));
      });
      onComplete();
    }

    final fileStream = DefaultCacheManager().getFileStream(this.url, headers: this.requestHeaders as Map<String, String>?);

    fileStream.listen(
      (fileResponse) {
        if (fileResponse is FileInfo) {
          if (this.videoFile == null) {
            this.state = LoadState.success;
            SchedulerBinding.instance.addPostFrameCallback((_) {
              loadEvent(LoadStateEvent(LoadState.success));
            });
            this.videoFile = fileResponse.file;
            onComplete();
          }
        }
      },
      onError: (_) {
        this.state = LoadState.failure;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          loadEvent(LoadStateEvent(LoadState.failure, () => loadVideo(onComplete)));
        });
      },
    );
  }
}

class StoryVideo extends StatefulWidget {
  final StoryController? storyController;
  final VideoLoader videoLoader;
  final TextStyle? errorTextStyle;

  StoryVideo(
    this.videoLoader, {
    this.storyController,
    Key? key,
    this.errorTextStyle,
  }) : super(key: key ?? UniqueKey());

  static StoryVideo url(
    String url, {
    StoryController? controller,
    Map<String, dynamic>? requestHeaders,
    TextStyle? errorTextStyle,
    required Rx<LoadStateEvent> loadEvent,
    Key? key,
  }) {
    return StoryVideo(
      VideoLoader(url, loadEvent, requestHeaders: requestHeaders),
      storyController: controller,
      key: key,
      errorTextStyle: errorTextStyle,
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
    print('F' * 100);
    widget.storyController!.pause();

    widget.videoLoader.loadVideo(() {
      print('A' * 100);
      if (widget.videoLoader.state == LoadState.success) {
        this.playerController = VideoPlayerController.file(widget.videoLoader.videoFile!);

        playerController!.initialize().then((v) {
          setState(() {});
          widget.storyController!.play();
        });

        if (widget.storyController != null) {
          _streamSubscription = widget.storyController!.playbackNotifier.listen((playbackState) {
            if (playbackState == PlaybackState.pause) {
              playerController!.pause();
            } else {
              playerController!.play();
            }
          });
        }
      } else {
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    super.initState();

    initializeVideo();
  }

  Widget getContentView() {
    if (widget.videoLoader.state == LoadState.success && playerController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: playerController!.value.aspectRatio,
          child: VideoPlayer(playerController!),
        ),
      );
    } else if (widget.videoLoader.state == LoadState.loading) {
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
      // if (widget.videoLoader.state == LoadState.failure)
      return SizedBox();
    }
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
            width: MediaQuery.of(context).size.width,
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
