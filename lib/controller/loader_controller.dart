import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../models/story_model.dart';

class LoaderController {
  static init(List<StoryModel> stories) async {
    for (var story in stories) {
      for (final event in story.events) {
        if (event.url.isNotEmpty) {
          if (event.url.split('.').last != "m3u8") {
            final fileInfo = await DefaultCacheManager().getFileFromCache(event.url);
            if (fileInfo == null) {
              final downloadedFile = await DefaultCacheManager().downloadFile(event.url);
              await DefaultCacheManager().putFile(event.url, downloadedFile.file.readAsBytesSync());
            }
          }
        }
      }
    }
  }
}
