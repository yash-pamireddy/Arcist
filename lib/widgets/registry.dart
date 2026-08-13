import 'package:flutter/material.dart';
import 'time.dart';
import 'Pulse.dart';

// Central Environment Registry: Drop any new widget file in the widgets folder,
// and import it here to have main.dart automatically manage and render it.
final List<Widget> widgetRegistryList = [
  const TimeWidget(),
  const SizedBox(height: 14),
  const PulseWidget(),
];