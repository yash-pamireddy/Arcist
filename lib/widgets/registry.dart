// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'extension_item.dart';
import 'Pulse.dart';
import 'time.dart';

List<ExtensionItem> extensionRegistry = [
  ExtensionItem(name: 'PulseWidget', widget: const PulseWidget()),
  ExtensionItem(name: 'TimeWidget', widget: const TimeWidget()),
];

List<Widget> get widgetRegistryList {
  return extensionRegistry
      .where((item) => item.isEnabled)
      .map((item) => item.widget)
      .toList();
}
