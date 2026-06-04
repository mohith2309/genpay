import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';

class MoodPicker extends StatefulWidget {
  final String? selectedMood;
  final ValueChanged<String?> onMoodSelected;

  const MoodPicker({
    super.key,
    this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  State<MoodPicker> createState() => _MoodPickerState();
}

class _MoodPickerState extends State<MoodPicker> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedMood;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling?',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.moods.map((mood) {
            final isSelected = _selected == mood;
            final label = AppConstants.moodLabels[mood] ?? '';
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selected = isSelected ? null : mood;
                });
                widget.onMoodSelected(_selected);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : Theme.of(context).dividerColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected ? AppColors.accent : Theme.of(context).hintColor,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
