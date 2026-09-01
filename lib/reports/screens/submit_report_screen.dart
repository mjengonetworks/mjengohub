// lib/reports/screens/submit_report_screen.dart
//
// "Report infrastructure" form. Anonymous submission is allowed; when the user
// is signed in the JWT is attached automatically and the backend links the
// report to their account. Pops with `true` on success so the list can refresh.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/responsive.dart';
import '../models/report_model.dart';
import '../services/reports_service.dart';

class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _api = ReportsService();
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  String _category = kReportCategories.first;
  String _severity = 'medium';
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_title, _description, _location, _name, _email, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final res = await _api.submitReport(
      title: _title.text.trim(),
      description: _description.text.trim(),
      location: _location.text.trim(),
      category: _category,
      severity: _severity,
      reporterName: _name.text.trim(),
      reporterEmail: _email.text.trim(),
      reporterPhone: _phone.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      Get.back(result: true);
      Get.snackbar(
        'Report submitted',
        res['message'] as String? ?? 'Thank you for reporting.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } else {
      Get.snackbar(
        'Could not submit',
        res['message'] as String? ?? 'Please try again.',
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          'Report infrastructure',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: ContentWidth(
        maxWidth: 700,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Tell us about a road, bridge, building or utility that needs '
                'attention. Your report is public once reviewed.',
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 20),

              const FieldLabel('Title', required: true),
              AppTextField(
                controller: _title,
                hint: 'e.g. Collapsed culvert on Ngong Road',
                validator: (v) => requiredField(v, 'Title'),
              ),
              const SizedBox(height: 14),

              const FieldLabel('Category', required: true),
              AppDropdown<String>(
                value: _category,
                items: kReportCategories,
                labelOf: _titleCase,
                hint: 'Select a category',
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 14),

              const FieldLabel('Severity', required: true),
              AppDropdown<String>(
                value: _severity,
                items: kReportSeverities,
                labelOf: _titleCase,
                hint: 'Select severity',
                onChanged: (v) => setState(() => _severity = v ?? _severity),
              ),
              const SizedBox(height: 14),

              const FieldLabel('Location', required: true),
              AppTextField(
                controller: _location,
                hint: 'Road, town or county',
                validator: (v) => requiredField(v, 'Location'),
              ),
              const SizedBox(height: 14),

              const FieldLabel('Description', required: true),
              AppTextField(
                controller: _description,
                hint: 'What is the problem, and how bad is it?',
                maxLines: 5,
                validator: (v) => requiredField(v, 'Description'),
              ),

              const SizedBox(height: 26),
              Text(
                'Your details (optional)',
                style: GoogleFonts.montserrat(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Leave blank to report anonymously.',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 14),

              const FieldLabel('Name'),
              AppTextField(controller: _name, hint: 'Optional'),
              const SizedBox(height: 14),

              const FieldLabel('Email'),
              AppTextField(
                controller: _email,
                hint: 'Optional',
                keyboard: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: 14),

              const FieldLabel('Phone'),
              AppTextField(
                controller: _phone,
                hint: 'Optional',
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              AppSubmitButton(
                label: 'Submit report',
                busy: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
