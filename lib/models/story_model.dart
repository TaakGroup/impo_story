import 'package:story_view/models/story_events.dart';

class StoryModel {
  final String id;
  final String isViewed;
  final int duration;
  final List<StoryEvents> events;

  StoryModel(this.isViewed, this.id, this.events, this.duration);
}
