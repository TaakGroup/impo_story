import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'models/story_model.dart';

enum StoryState { transition, loading, buffering, success, failure }

enum StoryEvent { none, play, pause }

enum Direction { up, down, left, right }

class StoryPipeline {
  final StoryState? storyState;
  StoryEvent? videoEvent = StoryEvent.none;
  StoryEvent? progressEvent = StoryEvent.none;
  final Function? retry;

  StoryPipeline({this.storyState, this.videoEvent, this.progressEvent, this.retry});
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
      repo: kIsWeb ? NonStoringObjectProvider() : JsonCacheInfoRepository(databaseName: key),
    ),
  );

  static preload(List<StoryModel> stories) async {
    for (var story in stories) {
      for (final event in story.events) {
        if (event.url.isNotEmpty) {
          if (event.url.split('.').last != "m3u8") {
            final fileInfo = await StoryCacheManager.instance.getFileFromCache(event.url);
            if (fileInfo == null) {
              final downloadedFile = await await StoryCacheManager.instance.downloadFile(event.url);
              await await StoryCacheManager.instance.putFile(event.url, downloadedFile.file.readAsBytesSync());
            }
          }
        }
      }
    }
  }
}
