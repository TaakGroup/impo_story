import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';

import '../utils.dart';
import '../controller/story_controller.dart';

/// Utitlity to load image (gif, png, jpg, etc) media just once. Resource is
/// cached to disk with default configurations of [DefaultCacheManager].
class ImageLoader {
  ui.Codec? frames;

  final Rx<StoryPipeline> loadEvent;

  String url;

  Map<String, dynamic>? requestHeaders;

  StoryState state = StoryState.loading; // by default

  ImageLoader(this.url, this.loadEvent, {this.requestHeaders});

  /// Load image from disk cache first, if not found then load from network.
  /// `onComplete` is called when [imageBytes] become available.
  Future<void> loadImage(VoidCallback onComplete) async {
    this.state = StoryState.loading;
    SchedulerBinding.instance.addPostFrameCallback((_) => loadEvent(StoryPipeline(storyState: StoryState.loading)));
    onComplete();

    if (this.frames != null) {
      this.state = StoryState.success;
      SchedulerBinding.instance.addPostFrameCallback((_) => loadEvent(StoryPipeline(storyState: StoryState.success)));
      onComplete();
    }

    final fileStream = await StoryCacheManager.instance.getFileStream(this.url, headers: this.requestHeaders as Map<String, String>?);

    fileStream.listen(
      (fileResponse) {
        if (!(fileResponse is FileInfo)) return;
        // the reason for this is that, when the cache manager fetches
        // the image again from network, the provided `onComplete` should
        // not be called again
        if (this.frames != null) {
          return;
        }

        final imageBytes = fileResponse.file.readAsBytesSync();

        PaintingBinding.instance.instantiateImageCodec(imageBytes).then((codec) {
          this.frames = codec;
          this.state = StoryState.success;
          SchedulerBinding.instance.addPostFrameCallback((_) => loadEvent(StoryPipeline(storyState: StoryState.success)));
          onComplete();
        }, onError: (error) {
          this.state = StoryState.failure;
          SchedulerBinding.instance
              .addPostFrameCallback((_) => loadEvent(StoryPipeline(storyState: StoryState.failure, retry: () => loadImage(onComplete))));
          onComplete();
        });
      },
      onError: (error) {
        this.state = StoryState.failure;
        SchedulerBinding.instance
            .addPostFrameCallback((_) => loadEvent(StoryPipeline(storyState: StoryState.failure, retry: () => loadImage(onComplete))));
        onComplete();
      },
    );
  }
}

/// Widget to display animated gifs or still images. Shows a loader while image
/// is being loaded. Listens to playback states from [controller] to pause and
/// forward animated media.
class StoryImage extends StatefulWidget {
  final ImageLoader imageLoader;
  final TextStyle? errorTextStyle;
  final ButtonStyle? retryButtonStyle;

  final BoxFit? fit;

  final StoryController controller;

  StoryImage(
    this.imageLoader, {
    Key? key,
    required this.controller,
    this.fit,
    this.errorTextStyle,
    this.retryButtonStyle,
  }) : super(key: key ?? UniqueKey());

  /// Use this shorthand to fetch images/gifs from the provided [url]
  factory StoryImage.url(
    String url, {
    required StoryController controller,
    Map<String, dynamic>? requestHeaders,
    BoxFit fit = BoxFit.fitWidth,
    TextStyle? errorTextStyle,
    ButtonStyle? retryButtonStyle,
    required Rx<StoryPipeline> loadEvent,
    Key? key,
  }) {
    return StoryImage(
      ImageLoader(url, loadEvent, requestHeaders: requestHeaders),
      controller: controller,
      fit: fit,
      errorTextStyle: errorTextStyle,
      retryButtonStyle: retryButtonStyle,
      key: key,
    );
  }

  @override
  State<StatefulWidget> createState() => StoryImageState();
}

class StoryImageState extends State<StoryImage> {
  ui.Image? currentFrame;

  Timer? _timer;

  StreamSubscription<PlaybackState>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    widget.controller.playerController = null;
    if (widget.controller != null) {
      this._streamSubscription = widget.controller.playbackNotifier.listen((playbackState) {
        // for the case of gifs we need to pause/play
        if (widget.imageLoader.frames == null) {
          return;
        }

        if (playbackState == PlaybackState.pause) {
          this._timer?.cancel();
        } else {
          forward();
        }
      });
    }

    widget.controller?.pause();

    widget.imageLoader.loadImage(() async {
      if (mounted) {
        if (widget.imageLoader.state == StoryState.success) {
          widget.controller?.play();
          forward();
        } else {
          // refresh to show error
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamSubscription?.cancel();

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void forward() async {
    this._timer?.cancel();

    if (widget.controller != null && widget.controller!.playbackNotifier.stream.value == PlaybackState.pause) {
      return;
    }

    final nextFrame = await widget.imageLoader.frames!.getNextFrame();

    this.currentFrame = nextFrame.image;

    if (nextFrame.duration > Duration(milliseconds: 0)) {
      this._timer = Timer(nextFrame.duration, forward);
    }

    setState(() {});
  }

  Widget getContentView() {
    switch (widget.imageLoader.state) {
      case StoryState.success:
        return RawImage(
          image: this.currentFrame,
          fit: widget.fit,
        );
      case StoryState.failure:
        return SizedBox();
      default:
        return Center(
          child: Container(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: getContentView(),
    );
  }
}
