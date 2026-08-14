// lib/widgets/extension_item.dart
import 'package:flutter/material.dart';

class ExtensionItem {
  final String name;
  final Widget widget;
  bool isEnabled;

  ExtensionItem({
    required this.name,
    required this.widget,
    this.isEnabled = true,
  });
}