import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../models/story_model.dart';

class LoaderController {
  static init(List<StoryModel> stories) async {
    for (var story in stories) {
      if (story.events.first.url.split('.').last != "m3u8") {
        final fileInfo = await DefaultCacheManager().getFileFromCache(story.events.first.url);
        if (fileInfo == null) {
          final downloadedFile = await DefaultCacheManager().downloadFile(story.events.first.url);
          await DefaultCacheManager().putFile(story.events.first.url, downloadedFile.file.readAsBytesSync());
        }
      }
    }
  }
}
