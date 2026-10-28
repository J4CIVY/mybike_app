import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ble/ble_controller.dart';
import 'bike_remote_controls_walk_away.dart';
import 'bike_remote_controls_walk_up.dart';

class BikeRemoteControlsSecurity extends StatelessWidget {
  final BleState ble;
  final WidgetRef ref;
  final VoidCallback onStateChanged;
  final void Function(String message) onHeroSnack;

  const BikeRemoteControlsSecurity({
    super.key,
    required this.ble,
    required this.ref,
    required this.onStateChanged,
    required this.onHeroSnack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BikeRemoteControlsWalkAway(
          ble: ble,
          ref: ref,
          onStateChanged: onStateChanged,
          onHeroSnack: onHeroSnack,
        ),
        const Divider(color: Color(0xFFF8FAFC), height: 1, thickness: 1, indent: 56, endIndent: 16),
        BikeRemoteControlsWalkUp(
          ble: ble,
          ref: ref,
          onStateChanged: onStateChanged,
          onHeroSnack: onHeroSnack,
        ),
      ],
    );
  }
}
