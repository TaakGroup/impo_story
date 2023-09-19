import 'package:story_view/models/story_events.dart';

class StoryModel {
  late String id;
  late bool isViewed;
  late String text;
  late String coverImage;
  late int duration;
  late List<StoryEvents> events;

  StoryModel(this.isViewed, this.id, this.events, this.duration, this.coverImage, this.text);

  StoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    isViewed = json['isViewed'];
    text = json['text'];
    coverImage = json['coverImage'];
    duration = json['duration'];
    if (json['events'] != null) {
      events = <StoryEvents>[];
      json['events'].forEach((v) {
        events.add(new StoryEvents.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['isViewed'] = this.isViewed;
    data['text'] = this.text;
    data['coverImage'] = this.coverImage;
    data['duration'] = this.duration;
    data['events'] = this.events.map((v) => v.toJson()).toList();

    return data;
  }
}
