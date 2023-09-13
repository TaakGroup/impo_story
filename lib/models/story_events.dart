enum StoryEventType {
  video,
  image,
  cta,
}

class StoryEvents {
  final StoryEventType type;
  final String link;
  final String text;


  StoryEvents(this.type, this.link, this.text);
}
