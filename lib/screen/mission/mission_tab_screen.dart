// import 'package:flutter/material.dart';
// import 'mission_suggest_screen.dart';
// import 'mission_start_screen.dart';
// import 'mission_rest_screen.dart';
// import 'mission_list_screen.dart'; // 기록 화면
//
// /// 4가지 화면 상태를 enum으로 표현
// enum MissionView { suggest, start, rest, list }
//
// class MissionTabScreen extends StatefulWidget {
//   const MissionTabScreen({super.key});
//
//   @override
//   State<MissionTabScreen> createState() => _MissionTabScreenState();
// }
//
// class _MissionTabScreenState extends State<MissionTabScreen> {
//   /// 현재 보여줄 화면 상태
//   MissionView currentView = MissionView.suggest;
//
//   /// 미션 시작 시
//   void goToStart() {
//     setState(() {
//       currentView = MissionView.start;
//     });
//   }
//
//   /// 미션 중단 또는 완료 후 다시 제안화면으로
//   void goToSuggest() {
//     setState(() {
//       currentView = MissionView.suggest;
//     });
//   }
//
//   /// 그냥 쉴래 눌렀을 때
//   void goToRest() {
//     setState(() {
//       currentView = MissionView.rest;
//     });
//   }
//
//   /// 미션 기록 보기
//   void showList() {
//     setState(() {
//       currentView = MissionView.list;
//     });
//   }
//
//   /// 홈으로 돌아가기
//   void goHome() {
//     Navigator.popUntil(context, (route) => route.isFirst);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     switch (currentView) {
//       case MissionView.start: // 수락?? ->
//         return MissionStartScreen(onCancel: goToSuggest);
//
//       case MissionView.rest: // 그냥 쉴래
//         return const MissionListScreen(); // 미션 기록 화면
//         // return MissionRestScreen(onViewList: showList);
//
//       // case MissionView.list:
//       //   return const MissionListScreen(); // 미션 기록 화면
//
//       case MissionView.suggest:
//       default:
//         return MissionSuggestScreen(
//           onStart: goToStart,
//           onRest: goToRest,
//           onViewList: showList,
//         );
//     }
//   }
// }
