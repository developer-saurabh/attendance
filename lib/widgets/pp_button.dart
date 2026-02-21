import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool filled;

  const AppButton({super.key, required this.text, required this.onPressed, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: filled
          ? null
          : ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(text),
      ),
    );
  }
}
