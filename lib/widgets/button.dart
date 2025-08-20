import 'package:flutter/material.dart';

class UseButton extends StatelessWidget {
  final VoidCallback? onTab; // Made nullable to disable when loading
  final String text;
  final bool isLoading; // Added loading state

  const UseButton({
    super.key,
    required this.onTab,
    required this.text,
    this.isLoading = false,
    CircularProgressIndicator? child, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTab, // Disable tap when loading
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            color: isLoading
                ? Colors.blue.shade300
                : Colors.blue, // Dim color when loading
          ),
          child: isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
