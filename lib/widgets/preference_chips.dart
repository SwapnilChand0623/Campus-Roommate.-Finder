import 'package:flutter/material.dart';

class PreferenceChips extends StatelessWidget {
  const PreferenceChips({super.key, required this.items, this.icon});

  final List<String> items;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Chip(
            avatar: icon == null ? null : Icon(icon, size: 16),
            label: Text(item),
          ),
      ],
    );
  }
}
