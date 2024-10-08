import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';

enum PlaybackState { pause, play, next, previous }

/// Controller to sync playback between animated child (story) views. This
/// helps make sure when stories are paused, the animation (gifs/slides) are
/// also paused.
/// Another reason for using the controller is to place the stories on `paused`
/// state when a media is loading.
class StoryController {
  /// Stream that broadcasts the playback state of the stories.
  final playbackNotifier = BehaviorSubject<PlaybackState>();
  VideoPlayerController? playerController;

  void attachVideoController(VideoPlayerController playerController) {
    this.playerController = playerController;

    this.playerController?.addListener(
      () async {
        if (playerController.value.isPlaying) {
          playbackNotifier.add(PlaybackState.play);
        } else if (!playerController.value.isCompleted) {
          if ((playerController.value.duration - playerController.value.position) > Duration(milliseconds: 500)) {
            playbackNotifier.add(PlaybackState.pause);
          }
        }
      },
    );
  }

  /// Notify listeners with a [PlaybackState.pause] state
  void pause() {
    if (playerController != null) {
      playerController!.pause();
    } else {
      playbackNotifier.add(PlaybackState.pause);
    }
  }

  /// Notify listeners with a [PlaybackState.play] state
  void play() {
    if (playerController != null) {
      playerController!.play();
    } else {
      playbackNotifier.add(PlaybackState.play);
    }
  }

  void next() {
    playerController = null;
    playbackNotifier.add(PlaybackState.next);
  }

  void previous() {
    playerController = null;
    playbackNotifier.add(PlaybackState.previous);
  }

  void jumpTo(int index) {
    for (int i = 0; i < index; i++) {
      next();
    }
  }

  /// Remember to call dispose when the story screen is disposed to close
  /// the notifier stream.
  void dispose() {
    playbackNotifier.close();
  }
}
