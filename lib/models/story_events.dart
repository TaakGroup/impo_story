enum StoryEventType {
  video,
  image,
  cta,
}

class StoryEvents {
  late StoryEventType type;
  late String link;
  late String? text;

  StoryEvents({required this.type, required this.link});

  StoryEvents.fromJson(Map<String, dynamic> json) {
    type = StoryEventType.values[json['type'] - 1 ?? 0];
    link = json['link'];
    text = json['text'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['link'] = this.link;
    data['text'] = this.text;
    return data;
  }
}
