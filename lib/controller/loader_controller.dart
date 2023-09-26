import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../models/story_model.dart';

class LoaderController {
  static init(List<StoryModel> stories) async {
    final fileInfo = await DefaultCacheManager().getFileFromCache(stories.first.events.first.url);
    if (fileInfo == null) {
      final downloadedFile = await DefaultCacheManager().downloadFile(stories.first.events.first.url);
      await DefaultCacheManager().putFile(stories.first.events.first.url, downloadedFile.file.readAsBytesSync());
    }
  }
}
