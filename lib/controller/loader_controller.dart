import '../models/story_model.dart';
import '../utils.dart';

class LoaderController {
  static init(List<StoryModel> stories) async {
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
