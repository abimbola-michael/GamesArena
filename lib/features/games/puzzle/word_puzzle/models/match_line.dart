// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:flutter/material.dart';

class MatchLine {
  Offset start;
  Offset end;
  int player;
  int wordIndex;
  MatchLine({
    required this.start,
    required this.end,
    required this.player,
    required this.wordIndex,
  });
}
