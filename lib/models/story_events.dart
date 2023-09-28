enum StoryEventType {
  video,
  image,
  cta,
}

class LinkModel {
  String? url;
  late int? type;

  LinkModel.fromJson(Map<String, dynamic>? json) {
    url = json?['url'];
    type = json?['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['url'] = this.url;
    return data;
  }
}

class StoryEvents {
  late StoryEventType type;
  late String url;
  late String? streamUrl;
  late String? text;
  late LinkModel link;

  StoryEvents({required this.type, required this.link});

  StoryEvents.fromJson(Map<String, dynamic> json) {
    type = StoryEventType.values[json['type'] - 1 ?? 0];
    url = json['url'];
    streamUrl = json['streamUrl'];
    text = json['text'];
    link = LinkModel.fromJson(json['link']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['url'] = this.url;
    data['streamUrl'] = this.streamUrl;
    data['text'] = this.text;
    data['link'] = this.link.toJson();
    return data;
  }
}
