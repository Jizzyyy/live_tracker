import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tracker_providers.dart';
import '../../utils/ui_helpers.dart';

class MemberListSheet extends ConsumerWidget {
  const MemberListSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider);
    final members = roomState.members.values.toList();

    return PremiumGlass(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SizedBox(
                width: 40, height: 4,
                child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(2)))),
              ),
            ),
            const SizedBox(height: 24),
            Text('Active Members (${members.length})', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final m = members[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(m.id.substring(0, 1))),
                    title: Text('User ${m.id}'),
                    subtitle: Text('${(m.speedKmh ?? 0).toStringAsFixed(1)} km/h • Updated just now'),
                    trailing: IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: () {
                        ref.read(focusedMemberProvider.notifier).state = m;
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
