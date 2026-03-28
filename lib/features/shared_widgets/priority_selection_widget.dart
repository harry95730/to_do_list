import 'package:flutter/material.dart';

class PriorityOption {
  final String label;
  final Color color;

  const PriorityOption({required this.label, required this.color});
}

class PrioritySelector extends StatelessWidget {
  final String title;
  final List<PriorityOption> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const PrioritySelector({
    super.key,
    required this.title,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF434655),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(options.length, (index) {
            final option = options[index];
            final isSelected = selectedIndex == index;
            final isLast = index == options.length - 1;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 8.0),
                child: _buildPriorityButton(
                  label: option.label,
                  activeColor: option.color,
                  isSelected: isSelected,
                  onTap: () => onChanged(index),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPriorityButton({
    required String label,
    required Color activeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : const Color(0xFFEDEDF9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isSelected ? activeColor : const Color(0xFF434655),
            ),
          ),
        ),
      ),
    );
  }
}
