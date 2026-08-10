import 'package:flutter/material.dart';

class MapFab extends StatelessWidget {
  const MapFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS belum aktif — coming soon!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      tooltip: 'My Location',
      child: const Icon(Icons.my_location),
    );
  }
}
