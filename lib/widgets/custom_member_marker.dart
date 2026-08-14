import 'package:flutter/material.dart';
import '../models/tracker_models.dart';

class CustomMemberMarker extends StatelessWidget {
  final MemberLocation location;
  final bool isLocalUser;

  const CustomMemberMarker({super.key, required this.location, this.isLocalUser = false});

  @override
  Widget build(BuildContext context) {
    // Generate a unique color based on ID
    final colorHash = location.id.codeUnits.fold<int>(0, (p, c) => p + c);
    final colors = [Colors.blueAccent, Colors.greenAccent, Colors.orangeAccent, Colors.purpleAccent, Colors.pinkAccent];
    final color = isLocalUser ? Colors.cyanAccent : colors[colorHash % colors.length];

    return RepaintBoundary(
      child: AnimatedRotation(
        turns: (location.heading ?? 0) / 360.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 4),
            ],
          ),
          child: Center(
            child: Text(
              location.isIdle ? 'zZ' : location.id.substring(0, 1).toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
