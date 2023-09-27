import 'package:flutter_cache_manager/flutter_cache_manager.dart';

enum StoryState { loading, buffering, success, failure }

enum StoryEvent { none, play, pause }

enum Direction { up, down, left, right }

class StoryPipeline {
  final StoryState? storyState;
  StoryEvent? videoEvent = StoryEvent.none;
  StoryEvent? progressEvent = StoryEvent.none;
  final Function? retry;

  StoryPipeline({this.storyState, this.videoEvent, this.progressEvent,this.retry});
}

class VerticalDragInfo {
  bool cancel = false;

  Direction? direction;

  void update(double primaryDelta) {
    Direction tmpDirection;

    if (primaryDelta > 0) {
      tmpDirection = Direction.down;
    } else {
      tmpDirection = Direction.up;
    }

    if (direction != null && tmpDirection != direction) {
      cancel = true;
    }

    direction = tmpDirection;
  }
}

class StoryCacheManager {
  static const key = 'story';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 3),
      repo: JsonCacheInfoRepository(databaseName: key),
    ),
  );
}
