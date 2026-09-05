// lib/shared/widgets/form_fields.dart
//
// Shared form primitives for the API-backed submission forms (service request,
// infrastructure report, review, advertising enquiry). The visual spec is
// lifted from `report_incident_screen.dart` so every form in the app looks the
// same; that screen predates this file and still has its own private copies.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

InputDecoration appInputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSubtle),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      errorStyle: GoogleFonts.montserrat(fontSize: 11, color: AppColors.danger),
    );

/// Small uppercase label shown above a field or section.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          required ? '$text *' : text,
          style: GoogleFonts.montserrat(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
            letterSpacing: 0.2,
          ),
        ),
      );
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
    this.validator,
    this.textCapitalization = TextCapitalization.sentences,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboard;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        validator: validator,
        textCapitalization: textCapitalization,
        onFieldSubmitted: onSubmitted,
        style: GoogleFonts.montserrat(fontSize: 13.5, color: AppColors.textDark),
        decoration: appInputDecoration(hint),
      );
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    required this.hint,
  });

  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSubtle),
        style: GoogleFonts.montserrat(fontSize: 13.5, color: AppColors.textDark),
        decoration: appInputDecoration(hint),
        items: items
            .map((e) => DropdownMenuItem<T>(value: e, child: Text(labelOf(e))))
            .toList(),
        onChanged: onChanged,
      );
}

/// Full-width primary action button with a built-in busy state.
class AppSubmitButton extends StatelessWidget {
  const AppSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: busy ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            disabledBackgroundColor: AppColors.primaryBlue.withValues(alpha: 0.6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
        ),
      );
}

/// Required-field validator with a consistent message.
String? requiredField(String? v, String label) =>
    (v == null || v.trim().isEmpty) ? '$label is required' : null;

/// Loose email check — the backend is the real authority, this just catches
/// obvious typos before a round trip.
String? emailField(String? v) {
  final value = (v ?? '').trim();
  if (value.isEmpty) return 'Email is required';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
    return 'Enter a valid email address';
  }
  return null;
}
