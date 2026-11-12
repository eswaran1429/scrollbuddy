import 'package:flutter/material.dart';
import 'package:scrollbuddy/core/themes/app_colors.dart';

import 'brain_state.dart';

/// Two-stop gradient per state: green → purple → amber/orange → red.
List<Color> stateColors(BrainState s) => switch (s) {
  BrainState.healthy => const [AppColors.sage, Color(0xFF7FD1AE)],
  BrainState.tired => const [AppColors.lavender, AppColors.lilac],
  BrainState.cracking => const [AppColors.amber, AppColors.coral],
  BrainState.fried => const [AppColors.coral, Color(0xFFFF4D4D)],
};
