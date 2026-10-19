import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/models/fsm_state.dart';

class FsmStatusBadge extends StatelessWidget {
  final FsmState state;

  const FsmStatusBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData iconData;

    switch (state) {
      case FsmState.idleGpsLock:
        badgeColor = AppColors.orange;
        iconData = Icons.gps_not_fixed;
        break;
      case FsmState.staging:
        badgeColor = AppColors.yellow;
        iconData = Icons.sensors;
        break;
      case FsmState.armed:
        badgeColor = AppColors.cyan;
        iconData = Icons.flash_on;
        break;
      case FsmState.running:
        badgeColor = AppColors.green;
        iconData = Icons.speed;
        break;
      case FsmState.finished:
        badgeColor = AppColors.purple;
        iconData = Icons.sports_score;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: badgeColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            blurRadius: 8.0,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 14.0, color: badgeColor),
          const SizedBox(width: 6.0),
          Text(
            state.displayName,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
