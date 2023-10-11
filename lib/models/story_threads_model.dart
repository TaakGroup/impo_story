
import 'package:story_view/models/story_model.dart';

class StoryThreadsModel {
  late String id;
  late List<StoryModel> stories;

  StoryThreadsModel.fromJson(Map<String, dynamic> json) {
    this.id = json["id"];
    this.stories = [for(var mapJson in json['stories']) StoryModel.fromJson(mapJson)];
  }
}