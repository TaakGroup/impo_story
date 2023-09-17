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
    type = StoryEventType.values[json['type'] ?? 0];
    link = json['link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['link'] = this.link;
    return data;
  }
}
