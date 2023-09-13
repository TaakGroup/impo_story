// import 'package:flutter/material.dart';
//
// import '../controller/story_controller.dart';
//
// void main() => runApp(MyApp());
//
// class MyApp extends StatelessWidget {
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//         title: 'Flutter Demo',
//         debugShowCheckedModeBanner: false,
//         theme: ThemeData(
//           primarySwatch: Colors.green,
//         ),
//         home: ImpoStory());
//   }
// }
//
// final StoryController controller = StoryController();
//
// class ImpoStory extends StatelessWidget {
//   List<String> videos = [
//     'https://timneh.arvanvod.ir/52O3Xod4nv/WOk3P72d8j/origin_kjgECnDlr2wihE6vsfMdvIn8uJOjETVDdlWHYEtC.mp4',
//     'https://timneh.arvanvod.ir/52O3Xod4nv/bEvmyMmMYy/origin_15tSXQJzvKT3nndeA2TLd2B3jtpBEFgR6FuO6Bsv.mp4',
//     'https://timneh.arvanvod.ir/52O3Xod4nv/m5YZPrqOEe/origin_HmDRDQLKRrFulW5iybJaf6fq45iwcQg92XaB1arv.mp4',
//   ];
//
//   ImpoStory({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: WillPopScope(
//         onWillPop: () => Future(() => false),
//         child: Directionality(
//           textDirection: TextDirection.ltr,
//           child: StoryView(
//             controller: controller,
//             indicatorColor: Colors.grey,
//             indicatorForegroundColor: Colors.white,
//
//             // onComplete: OnboardingController.to.onComplete,
//             // onStoryShow: (value) => OnboardingController.to.currentStory = stories.indexOf(value.view),
//             // controller: OnboardingController.to.storyController,
//             storyItems: [
//               for (int index = 0; index < videos.length; index++)
//                 StoryItem(
//                   Directionality(
//                     textDirection: TextDirection.rtl,
//                     child: VideoStory(
//                       url: videos[index],
//                       storyController: controller,
//                     ),
//                   ),
//                   duration: const Duration(seconds: 45),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
