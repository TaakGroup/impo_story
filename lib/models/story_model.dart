import 'package:story_view/models/story_events.dart';

class StoryModel {
  final String id;
  final bool isViewed;
  final String coverImage;
  final String text;
  final int duration;
  final List<StoryEvents> events;

  StoryModel(this.isViewed, this.id, this.events, this.duration, this.coverImage, this.text);
}
