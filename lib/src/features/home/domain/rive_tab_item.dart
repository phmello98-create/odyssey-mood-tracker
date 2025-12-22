import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveTabItem {
  RiveTabItem({this.stateMachine = "", this.artboard = "", this.status});

  UniqueKey? id = UniqueKey();
  String stateMachine;
  String artboard;
  late SMIBool? status;

  static List<RiveTabItem> get tabItems => [
    RiveTabItem(stateMachine: "CHAT_Interactivity", artboard: "CHAT"), // Home
    RiveTabItem(
      stateMachine: "SEARCH_Interactivity",
      artboard: "SEARCH",
    ), // Log
    RiveTabItem(stateMachine: "BELL_Interactivity", artboard: "BELL"), // Mood
    RiveTabItem(
      stateMachine: "TIMER_Interactivity",
      artboard: "TIMER",
    ), // Timer
    RiveTabItem(
      stateMachine: "USER_Interactivity",
      artboard: "USER",
    ), // Profile
  ];
}
