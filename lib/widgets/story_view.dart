import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:story_view/models/story_events.dart';
import 'package:story_view/models/story_model.dart';
import 'package:web_browser_detect/web_browser_detect.dart';

import '../controller/story_controller.dart';
import '../utils.dart';
import 'story_image.dart';
import 'story_video.dart';
import 'dart:io';

/// Indicates where the progress indicators should be placed.
enum ProgressPosition { top, bottom, none }

/// This is used to specify the height of the progress indicator. Inline stories
/// should use [small]
enum IndicatorHeight { small, large }

/// This is a representation of a story item (or page).
class StoryItem {
  /// Specifies how long the page should be displayed. It should be a reasonable
  /// amount of time greater than 0 milliseconds.
  final Duration duration;

  /// Has this page been shown already? This is used to indicate that the page
  /// has been displayed. If some pages are supposed to be skipped in a story,
  /// mark them as shown `shown = true`.
  ///
  /// However, during initialization of the story view, all pages after the
  /// last unshown page will have their `shown` attribute altered to false. This
  /// is because the next item to be displayed is taken by the last unshown
  /// story item.
  bool shown;

  /// The page content
  final Widget view;

  /// The cta content
  final Widget cta;

  final StoryModel storyModel;

  // Stream
  final Rx<StoryPipeline> state;

  StoryItem(
    this.view,
    this.cta,
    this.storyModel,
    this.state, {
    required this.duration,
    this.shown = false,
  });

  /// Short hand to create text-only page.
  ///
  /// [title] is the text to be displayed on [backgroundColor]. The text color
  /// alternates between [Colors.black] and [Colors.white] depending on the
  /// calculated contrast. This is to ensure readability of text.
  ///
  /// Works for inline and full-page stories. See [StoryView.inline] for more on
  /// what inline/full-page means.
  // static StoryItem text({
  //   required String title,
  //   required Color backgroundColor,
  //   Key? key,
  //   TextStyle? textStyle,
  //   bool shown = false,
  //   bool roundedTop = false,
  //   bool roundedBottom = false,
  //   Duration? duration,
  // }) {
  //   double contrast = ContrastHelper.contrast([
  //     backgroundColor.red,
  //     backgroundColor.green,
  //     backgroundColor.blue,
  //   ], [
  //     255,
  //     255,
  //     255
  //   ] /** white text */);
  //
  //   return StoryItem(
  //     Container(
  //       key: key,
  //       decoration: BoxDecoration(
  //         color: backgroundColor,
  //         borderRadius: BorderRadius.vertical(
  //           top: Radius.circular(roundedTop ? 8 : 0),
  //           bottom: Radius.circular(roundedBottom ? 8 : 0),
  //         ),
  //       ),
  //       padding: EdgeInsets.symmetric(
  //         horizontal: 24,
  //         vertical: 16,
  //       ),
  //       child: Center(
  //         child: Text(
  //           title,
  //           style: textStyle?.copyWith(
  //                 color: contrast > 1.8 ? Colors.white : Colors.black,
  //               ) ??
  //               TextStyle(
  //                 color: contrast > 1.8 ? Colors.white : Colors.black,
  //                 fontSize: 18,
  //               ),
  //           textAlign: TextAlign.center,
  //         ),
  //       ),
  //       //color: backgroundColor,
  //     ),
  //     cta ?? SizedBox(),
  //     shown: shown,
  //     duration: duration ?? Duration(seconds: 3),
  //   );
  // }

  /// Factory constructor for page images. [controller] should be same instance as
  /// one passed to the `StoryView`
  factory StoryItem.pageImage({
    required String url,
    required StoryController controller,
    required StoryModel model,
    Key? key,
    BoxFit imageFit = BoxFit.fitWidth,
    Widget? cta,
    bool shown = false,
    Map<String, dynamic>? requestHeaders,
    required Duration duration,
    ButtonStyle? retryButtonStyle,
    TextStyle? errorTextStyle,
  }) {
    Rx<StoryPipeline> loadEvent = StoryPipeline().obs;

    return StoryItem(
      Container(
        key: key,
        color: Colors.black,
        child: StoryImage.url(
          url,
          loadEvent: loadEvent,
          controller: controller,
          fit: imageFit,
          requestHeaders: requestHeaders,
          errorTextStyle: errorTextStyle,
          retryButtonStyle: retryButtonStyle,
        ),
      ),
      cta ?? SizedBox(),
      model,
      loadEvent,
      shown: shown,
      duration: duration,
    );
  }

  /// Shorthand for creating inline image. [controller] should be same instance as
  /// one passed to the `StoryView`
  // factory StoryItem.inlineImage({
  //   required String url,
  //   Text? caption,
  //   required StoryController controller,
  //   Key? key,
  //   BoxFit imageFit = BoxFit.cover,
  //   Map<String, dynamic>? requestHeaders,
  //   bool shown = false,
  //   bool roundedTop = true,
  //   bool roundedBottom = false,
  //   Duration? duration,
  // }) {
  //   return StoryItem(
  //     ClipRRect(
  //       key: key,
  //       child: Container(
  //         color: Colors.grey[100],
  //         child: Container(
  //           color: Colors.black,
  //           child: Stack(
  //             children: <Widget>[
  //               StoryImage.url(
  //                 url,
  //                 controller: controller,
  //                 fit: imageFit,
  //                 requestHeaders: requestHeaders,
  //               ),
  //               Container(
  //                 margin: EdgeInsets.only(bottom: 16),
  //                 padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  //                 child: Align(
  //                   alignment: Alignment.bottomLeft,
  //                   child: Container(
  //                     child: caption == null ? SizedBox() : caption,
  //                     width: double.infinity,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //       borderRadius: BorderRadius.vertical(
  //         top: Radius.circular(roundedTop ? 8 : 0),
  //         bottom: Radius.circular(roundedBottom ? 8 : 0),
  //       ),
  //     ),
  //     shown: shown,
  //     duration: duration ?? Duration(seconds: 3),
  //   );
  // }

  factory StoryItem.fromModel(
    StoryModel storyModel,
    StoryController controller, {
    ButtonStyle? buttonStyle,
    Function(LinkModel link)? onButtonPressed,
  }) {
    final cta = storyModel.events.firstWhereOrNull((element) => element.type == StoryEventType.cta);
    final video = storyModel.events.firstWhereOrNull((element) => element.type == StoryEventType.video);
    final image = storyModel.events.firstWhereOrNull((element) => element.type == StoryEventType.image);

    final ctaWidget = cta == null
        ? SizedBox()
        : ElevatedButton(
            onPressed: () => onButtonPressed?.call(cta.link),
            style: buttonStyle,
            child: Text(cta.text!),
          );

    if (video != null) {
      return StoryItem.pageVideo(
        video.streamUrl != null && video.streamUrl!.isNotEmpty ? video.streamUrl! : video.url,
        model: storyModel,
        imageFit: BoxFit.cover,
        duration: Duration(milliseconds: storyModel.duration),
        controller: controller,
        cta: ctaWidget,
      );
    } else {
      // if (image != null)
      return StoryItem.pageImage(
        url: image!.url,
        model: storyModel,
        imageFit: BoxFit.cover,
        duration: Duration(milliseconds: storyModel.duration),
        controller: controller,
        cta: ctaWidget,
      );
    }
  }

  /// Shorthand for creating page video. [controller] should be same instance as
  /// one passed to the `StoryView`
  factory StoryItem.pageVideo(
    String url, {
    required StoryController controller,
    required StoryModel model,
    Key? key,
    required Duration duration,
    BoxFit imageFit = BoxFit.cover,
    Widget? cta,
    bool shown = false,
    Map<String, dynamic>? requestHeaders,
  }) {
    Rx<StoryPipeline> loadEvent = StoryPipeline().obs;
    if (kIsWeb) {
      final browser = Browser();
      if (browser.browserAgent == BrowserAgent.Safari) {
        final ext = url.split('.').last;
        if (ext == 'webm') {
          url = url.replaceAll('.webm', '.mp4');
        }
      }
    } else if(Platform.isIOS){
      final ext = url.split('.').last;
      if (ext == 'webm') {
        url = url.replaceAll('.webm', '.mp4');
      }
    }

    return StoryItem(
      Container(
        key: key,
        color: Colors.black,
        child: StoryVideo.url(
          url,
          state: loadEvent,
          controller: controller,
          requestHeaders: requestHeaders,
        ),
      ),
      cta ?? SizedBox(),
      model,
      loadEvent,
      shown: shown,
      duration: duration,
    );
  }

  /// Shorthand for creating a story item from an image provider such as `AssetImage`
  /// or `NetworkImage`. However, the story continues to play while the image loads
  /// up.
// factory StoryItem.pageProviderImage(
//   ImageProvider image, {
//   Key? key,
//   BoxFit imageFit = BoxFit.fitWidth,
//   Widget? cta,
//   bool shown = false,
//   Duration? duration,
// }) {
//   return StoryItem(
//       Container(
//         key: key,
//         color: Colors.black,
//         child: Stack(
//           children: <Widget>[
//             Center(
//               child: Image(
//                 image: image,
//                 height: double.infinity,
//                 width: double.infinity,
//                 fit: imageFit,
//               ),
//             ),
//             SafeArea(
//               child: Align(
//                 alignment: Alignment.bottomCenter,
//                 child: Container(
//                   width: double.infinity,
//                   margin: EdgeInsets.only(
//                     bottom: 24,
//                   ),
//                   padding: EdgeInsets.symmetric(
//                     horizontal: 24,
//                     vertical: 8,
//                   ),
//                   child: cta,
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//       shown: shown,
//       duration: duration ?? Duration(seconds: 3));
// }

  /// Shorthand for creating an inline story item from an image provider such as `AssetImage`
  /// or `NetworkImage`. However, the story continues to play while the image loads
  /// up.
// factory StoryItem.inlineProviderImage(
//   ImageProvider image, {
//   Key? key,
//   Text? caption,
//   bool shown = false,
//   bool roundedTop = true,
//   bool roundedBottom = false,
//   Duration? duration,
// }) {
//   return StoryItem(
//     Container(
//       key: key,
//       decoration: BoxDecoration(
//           color: Colors.grey[100],
//           borderRadius: BorderRadius.vertical(
//             top: Radius.circular(roundedTop ? 8 : 0),
//             bottom: Radius.circular(roundedBottom ? 8 : 0),
//           ),
//           image: DecorationImage(
//             image: image,
//             fit: BoxFit.cover,
//           )),
//       child: Container(
//         margin: EdgeInsets.only(
//           bottom: 16,
//         ),
//         padding: EdgeInsets.symmetric(
//           horizontal: 24,
//           vertical: 8,
//         ),
//         child: Align(
//           alignment: Alignment.bottomLeft,
//           child: Container(
//             child: caption == null ? SizedBox() : caption,
//             width: double.infinity,
//           ),
//         ),
//       ),
//     ),
//     shown: shown,
//     duration: duration ?? Duration(seconds: 3),
//   );
// }
}

/// Widget to display stories just like Whatsapp and Instagram. Can also be used
/// inline/inside [ListView] or [Column] just like Google News app. Comes with
/// gestures to pause, forward and go to previous page.
class StoryView extends StatefulWidget {
  /// The pages to displayed.
  final List<StoryItem?> storyItems;

  /// Callback for when a full cycle of story is shown. This will be called
  /// each time the full story completes when [repeat] is set to `true`.
  final VoidCallback? onComplete;

  /// Callback for when a vertical swipe gesture is detected. If you do not
  /// want to listen to such event, do not provide it. For instance,
  /// for inline stories inside ListViews, it is preferrable to not to
  /// provide this callback so as to enable scroll events on the list view.
  final Function(Direction?)? onVerticalSwipeComplete;

  /// Callback for when a story is currently being shown.
  final ValueChanged<StoryModel>? onStoryShow;

  /// Where the progress indicator should be placed.
  final ProgressPosition progressPosition;

  /// Should the story be repeated forever?
  final bool repeat;

  /// If you would like to display the story as full-page, then set this to
  /// `false`. But in case you would display this as part of a page (eg. in
  /// a [ListView] or [Column]) then set this to `true`.
  final bool inline;

  // Controls the playback of the stories
  final StoryController controller;

  // Indicator Color
  final Color? indicatorColor;

  // Indicator Foreground Color
  final Color? indicatorForegroundColor;

  final Widget? avatar;

  final Widget? title;

  final Widget? mark;

  final Widget? leading;

  final bool showShadow;

  final TextStyle? errorTextStyle;

  final ButtonStyle? retryButtonStyle;

  final Widget? failureIcon;

  final EdgeInsets? profilePadding;

  final Function? onPreviousPressed;

  StoryView({
    required this.storyItems,
    required this.controller,
    this.onComplete,
    this.onStoryShow,
    this.progressPosition = ProgressPosition.top,
    this.repeat = false,
    this.inline = false,
    this.onVerticalSwipeComplete,
    this.indicatorColor,
    this.indicatorForegroundColor,
    this.avatar,
    this.title,
    this.mark,
    this.leading,
    this.showShadow = true,
    this.errorTextStyle,
    this.retryButtonStyle,
    this.failureIcon,
    this.profilePadding,
    this.onPreviousPressed,
  });

  @override
  State<StatefulWidget> createState() {
    return StoryViewState();
  }
}

class StoryViewState extends State<StoryView> with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _currentAnimation;
  Timer? _nextDebouncer;

  StreamSubscription<PlaybackState>? _playbackSubscription;

  VerticalDragInfo? verticalDragInfo;

  StoryItem? get _currentStory {
    return widget.storyItems.firstWhereOrNull((it) => !it!.shown);
  }

  StoryItem get _currentView {
    var item = widget.storyItems.firstWhereOrNull((it) => !it!.shown);
    item ??= widget.storyItems.last;
    return item!;
  }

  @override
  void initState() {
    super.initState();

    // All pages after the first unshown page should have their shown value as
    // false
    final firstPage = widget.storyItems.firstWhereOrNull((it) => !it!.shown);
    if (firstPage == null) {
      widget.storyItems.forEach((it2) {
        it2!.shown = false;
      });
    } else {
      final lastShownPos = widget.storyItems.indexOf(firstPage);
      widget.storyItems.sublist(lastShownPos).forEach((it) {
        it!.shown = false;
      });
    }

    this._playbackSubscription = widget.controller.playbackNotifier.listen((playbackStatus) {
      switch (playbackStatus) {
        case PlaybackState.play:
          _removeNextHold();
          this._animationController?.forward();
          break;

        case PlaybackState.pause:
          _holdNext(); // then pause animation
          this._animationController?.stop(canceled: false);
          break;

        case PlaybackState.next:
          _removeNextHold();
          _goForward();
          break;

        case PlaybackState.previous:
          _removeNextHold();
          _goBack();
          break;
      }
    });

    _play();
  }

  @override
  void dispose() {
    _clearDebouncer();

    _animationController?.dispose();
    _playbackSubscription?.cancel();

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void _play() {
    _animationController?.dispose();
    // get the next playing page
    final storyItem = widget.storyItems.firstWhere((it) {
      return !it!.shown;
    })!;

    if (widget.onStoryShow != null) {
      widget.onStoryShow!(storyItem.storyModel);
    }

    _animationController = AnimationController(duration: storyItem.duration, vsync: this);

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        storyItem.shown = true;
        if (widget.storyItems.last != storyItem) {
          _beginPlay();
        } else {
          // done playing
          _onComplete();
        }
      }
    });

    _currentAnimation = Tween(begin: 0.0, end: 1.0).animate(_animationController!);

    widget.controller.play();
  }

  void _beginPlay() {
    setState(() {});
    _play();
  }

  void _onComplete() {
    if (widget.onComplete != null) {
      // widget.controller.pause();
      widget.onComplete!();
    }

    if (widget.repeat) {
      widget.storyItems.forEach((it) {
        it!.shown = false;
      });

      _beginPlay();
    }
  }

  void _goBack() {
    _animationController!.stop();

    if (this._currentStory == null) {
      widget.storyItems.last!.shown = false;
    }

    if (this._currentStory == widget.storyItems.first) {
      _beginPlay();
    } else {
      this._currentStory!.shown = false;
      int lastPos = widget.storyItems.indexOf(this._currentStory);
      final previous = widget.storyItems[lastPos - 1]!;

      previous.shown = false;

      _beginPlay();
    }
  }

  void _goForward() {
    if (this._currentStory != widget.storyItems.last) {
      _animationController!.stop();

      // get last showing
      final _last = this._currentStory;

      if (_last != null) {
        _last.shown = true;
        if (_last != widget.storyItems.last) {
          _beginPlay();
        }
      }
    } else {
      // this is the last page, progress animation should skip to end
      _animationController!.animateTo(1.0, duration: Duration(milliseconds: 10));
    }
  }

  void _clearDebouncer() {
    _nextDebouncer?.cancel();
    _nextDebouncer = null;
  }

  void _removeNextHold() {
    _nextDebouncer?.cancel();
    _nextDebouncer = null;
  }

  void _holdNext() {
    _nextDebouncer?.cancel();
    _nextDebouncer = Timer(Duration(milliseconds: 500), () {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(1.0),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1080 / 1920,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 12,
                        cornerSmoothing: 0.6,
                      ),
                    ),
                  ),
                  child: Stack(
                    children: <Widget>[
                      _currentView.view,
                      if (widget.showShadow)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xff31303027).withOpacity(0.15),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (widget.showShadow)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0xff31303027).withOpacity(0.15),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      Visibility(
                        visible: widget.progressPosition != ProgressPosition.none,
                        child: Align(
                          alignment: widget.progressPosition == ProgressPosition.top ? Alignment.topCenter : Alignment.bottomCenter,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Transform.rotate(
                              angle: pi,
                              child: PageBar(
                                // widget.storyItems.map((it) => PageData(Duration(seconds: 60), it!.shown)).toList(),
                                widget.storyItems.map((it) => PageData(it!.duration, it.shown)).toList(),
                                this._currentAnimation,
                                key: UniqueKey(),
                                indicatorHeight: widget.inline ? IndicatorHeight.small : IndicatorHeight.large,
                                indicatorColor: widget.indicatorColor,
                                indicatorForegroundColor: widget.indicatorForegroundColor,
                              ),
                            ),
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerLeft,
                        heightFactor: 1,
                        child: GestureDetector(
                          onTapDown: (details) {
                            widget.controller.pause();
                          },
                          onTapCancel: () {
                            widget.controller.play();
                          },
                          onTapUp: (details) {
                            // if debounce timed out (not active) then continue anim
                            if (_nextDebouncer?.isActive == false) {
                              widget.controller.play();
                            } else {
                              widget.controller.next();
                            }
                          },
                          onVerticalDragStart: widget.onVerticalSwipeComplete == null
                              ? null
                              : (details) {
                                  widget.controller.pause();
                                },
                          onVerticalDragCancel: widget.onVerticalSwipeComplete == null
                              ? null
                              : () {
                                  widget.controller.play();
                                },
                          onVerticalDragUpdate: widget.onVerticalSwipeComplete == null
                              ? null
                              : (details) {
                                  if (verticalDragInfo == null) {
                                    verticalDragInfo = VerticalDragInfo();
                                  }

                                  verticalDragInfo!.update(details.primaryDelta!);

                                  // TODO: provide callback interface for animation purposes
                                },
                          onVerticalDragEnd: widget.onVerticalSwipeComplete == null
                              ? null
                              : (details) {
                                  widget.controller.play();

                                  // finish up drag cycle
                                  if (!verticalDragInfo!.cancel && widget.onVerticalSwipeComplete != null) {
                                    widget.onVerticalSwipeComplete!(verticalDragInfo!.direction);
                                  }

                                  verticalDragInfo = null;
                                },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        heightFactor: 1,
                        child: SizedBox(
                          child: GestureDetector(
                            onTap: () {
                              if (widget.storyItems.first != _currentView) {
                                widget.controller.previous();
                              } else {
                                widget.onPreviousPressed?.call();
                              }
                            },
                          ),
                          width: MediaQuery.of(context).size.width / 4,
                        ),
                      ),
                      Obx(
                        () {
                          if (_currentView.state.value.storyState == StoryState.failure) {
                            return Directionality(
                              textDirection: TextDirection.rtl,
                              child: Center(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    widget.failureIcon ?? SizedBox(),
                                    Text(
                                      "برقراری ارتباط امکان پذیر نیست",
                                      style: widget.errorTextStyle?.copyWith(color: Colors.white),
                                    ),
                                    SizedBox(
                                      height: 16,
                                      width: double.infinity,
                                    ),
                                    OutlinedButton(
                                      onPressed: () => _currentView.state.value.retry?.call(),
                                      style: widget.retryButtonStyle,
                                      child: Text('تلاش مجدد'),
                                    )
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return SizedBox();
                          }
                        },
                      ),
                      Positioned(
                        bottom: 32,
                        left: 0,
                        right: 0,
                        child: Obx(() {
                          if (_currentView.state.value.storyState == StoryState.success)
                            return Directionality(
                              textDirection: TextDirection.rtl,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: _currentView.cta,
                                  ),
                                ],
                              ),
                            );
                          else
                            return SizedBox();
                        }),
                      ),
                      Visibility(
                        visible: widget.progressPosition != ProgressPosition.none,
                        child: Align(
                          alignment: widget.progressPosition == ProgressPosition.top ? Alignment.topCenter : Alignment.bottomCenter,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 28,
                            ),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      CircleAvatar(radius: 16, child: widget.avatar),
                                      const SizedBox(width: 8),
                                      widget.title ?? SizedBox(),
                                      const SizedBox(width: 2),
                                      widget.mark ?? SizedBox(),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      SizedBox.square(
                                        dimension: 24,
                                        child: Obx(
                                              () => _currentView.state.value.storyState == StoryState.buffering
                                              ? CircularProgressIndicator(
                                            strokeWidth: 1.0,
                                            color: Colors.white,
                                          )
                                              : SizedBox(),
                                        ),
                                      ),
                                      widget.leading ?? SizedBox(),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Positioned(
                      //   bottom: 20,
                      //   right: 16,
                      //   child: LikeButton(
                      //     size: 28,
                      //     bubblesColor: BubblesColor(
                      //       dotPrimaryColor: Colors.red,
                      //       dotSecondaryColor: Colors.redAccent,
                      //     ),
                      //     likeBuilder: (bool isLiked) => isLiked
                      //         ? Icon(
                      //             IconlyBold.heart,
                      //             color: Colors.red,
                      //             size: 28,
                      //           )
                      //         : Icon(
                      //             IconlyLight.heart,
                      //             color: Colors.white,
                      //             size: 28,
                      //           ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Capsule holding the duration and shown property of each story. Passed down
/// to the pages bar to render the page indicators.
class PageData {
  Duration duration;
  bool shown;

  PageData(this.duration, this.shown);
}

/// Horizontal bar displaying a row of [StoryProgressIndicator] based on the
/// [pages] provided.
class PageBar extends StatefulWidget {
  final List<PageData> pages;
  final Animation<double>? animation;
  final IndicatorHeight indicatorHeight;
  final Color? indicatorColor;
  final Color? indicatorForegroundColor;

  PageBar(
    this.pages,
    this.animation, {
    this.indicatorHeight = IndicatorHeight.large,
    this.indicatorColor,
    this.indicatorForegroundColor,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PageBarState();
  }
}

class PageBarState extends State<PageBar> {
  double spacing = 4;

  @override
  void initState() {
    super.initState();

    int count = widget.pages.length;
    spacing = (count > 15) ? 1 : ((count > 10) ? 2 : 4);

    widget.animation!.addListener(() {
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  bool isPlaying(PageData page) {
    return widget.pages.firstWhereOrNull((it) => !it.shown) == page;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: widget.pages.map((it) {
        return Expanded(
          child: Container(
            padding: EdgeInsets.only(right: widget.pages.last == it ? 0 : this.spacing),
            child: StoryProgressIndicator(
              isPlaying(it) ? widget.animation!.value : (it.shown ? 1 : 0),
              indicatorHeight: widget.indicatorHeight == IndicatorHeight.large ? 5 : 2,
              indicatorColor: widget.indicatorColor,
              indicatorForegroundColor: widget.indicatorForegroundColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Custom progress bar. Supposed to be lighter than the
/// original [ProgressIndicator], and rounded at the sides.
class StoryProgressIndicator extends StatelessWidget {
  /// From `0.0` to `1.0`, determines the progress of the indicator
  final double value;
  final double indicatorHeight;
  final Color? indicatorColor;
  final Color? indicatorForegroundColor;

  StoryProgressIndicator(
    this.value, {
    this.indicatorHeight = 2,
    this.indicatorColor,
    this.indicatorForegroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.fromHeight(
        this.indicatorHeight,
      ),
      foregroundPainter: IndicatorOval(
        this.indicatorForegroundColor ?? Colors.white.withOpacity(0.8),
        this.value,
      ),
      painter: IndicatorOval(
        this.indicatorColor ?? Colors.white.withOpacity(0.4),
        1.0,
      ),
    );
  }
}

class IndicatorOval extends CustomPainter {
  final Color color;
  final double widthFactor;

  IndicatorOval(this.color, this.widthFactor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = this.color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * this.widthFactor, size.height),
        Radius.circular(8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

/// Concept source: https://stackoverflow.com/a/9733420
class ContrastHelper {
  static double luminance(int? r, int? g, int? b) {
    final a = [r, g, b].map((it) {
      double value = it!.toDouble() / 255.0;
      return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4);
    }).toList();

    return a[0] * 0.2126 + a[1] * 0.7152 + a[2] * 0.0722;
  }

  static double contrast(rgb1, rgb2) {
    return luminance(rgb2[0], rgb2[1], rgb2[2]) / luminance(rgb1[0], rgb1[1], rgb1[2]);
  }
}
