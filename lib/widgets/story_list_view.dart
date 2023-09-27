import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:story_view/models/story_model.dart';
import '../utils.dart';

class StoryListView extends StatelessWidget {
  final List<StoryModel> stories;
  final TextStyle? textStyle;
  final Function(StoryModel) onStoryPressed;
  final Color viewedColor, notViewedColor;
  final double height;
  final double coverSize;
  final double spacing;
  final EdgeInsetsGeometry? padding;
  final double visitedOpacity;

  const StoryListView({
    required this.stories,
    this.textStyle,
    required this.viewedColor,
    required this.notViewedColor,
    required this.onStoryPressed,
    this.height = 100,
    this.coverSize = 64,
    this.spacing = 16,
    this.padding,
    this.visitedOpacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        height: height,
        child: ListView.builder(
          padding: padding ?? EdgeInsets.only(right: 16),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          itemCount: stories.length,
          itemBuilder: (_, index) => StoryItemWidget(
            onTap: () => onStoryPressed.call(stories[index]),
            padding: EdgeInsets.only(left: spacing),
            story: stories[index],
            notViewedColor: notViewedColor,
            viewedColor: viewedColor,
            textStyle: textStyle,
            size: coverSize,
            visitedOpacity: visitedOpacity,
          ),
        ),
      ),
    );
  }
}

class StoryItemWidget extends StatelessWidget {
  final void Function()? onTap;
  final EdgeInsetsGeometry padding;
  final StoryModel story;
  final TextStyle? textStyle;
  final Color viewedColor, notViewedColor;
  final double size;
  final double visitedOpacity;

  const StoryItemWidget({
    this.onTap,
    required this.padding,
    required this.story,
    this.textStyle,
    required this.viewedColor,
    required this.notViewedColor,
    required this.size,
    this.visitedOpacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              width: size,
              height: size,
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: story.isViewed ? viewedColor : notViewedColor),
              ),
              child: Opacity(
                opacity: story.isViewed ? visitedOpacity : 1,
                child: Container(
                  width: size - 1.5,
                  height: size - 1.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        story.coverImage,
                        cacheManager: StoryCacheManager.instance,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(story.text, style: textStyle)
          ],
        ),
      ),
    );
  }
}
