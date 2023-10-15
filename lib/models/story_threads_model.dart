import 'package:equatable/equatable.dart';
import 'package:story_view/models/story_model.dart';

class StoryThreadsModel extends Equatable {
  late String id;
  late List<StoryModel> stories;

  StoryThreadsModel.fromJson(Map<String, dynamic> json) {
    this.id = json["id"];
    this.stories = [for (var mapJson in json['stories']) StoryModel.fromJson(mapJson)];
  }

  bool get seen {
    bool flag = false;
    for (var story in stories) {
      if (story.isViewed) {
        flag = true;
        break;
      }
    }

    return flag;
  }

  @override
  List<Object?> get props => [seen];
}
