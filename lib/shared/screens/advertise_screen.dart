// lib/shared/screens/advertise_screen.dart
//
// "Advertise with Us" enquiry form — mirrors templates/advertise.html.
// Backed by api.py's `POST advertise` (AdvertisingInquiry). The website's
// form also has a file-attachment input, but the JSON endpoint never reads
// it (`request.get_json()` only), so it's omitted here rather than faked.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/site_service.dart';
import '../theme/app_theme.dart';
import '../widgets/form_fields.dart';
import '../widgets/responsive.dart';

class AdvertiseScreen extends StatefulWidget {
  const AdvertiseScreen({super.key});

  @override
  State<AdvertiseScreen> createState() => _AdvertiseScreenState();
}

class _AdvertiseScreenState extends State<AdvertiseScreen> {
  final _api = SiteService();
  final _formKey = GlobalKey<FormState>();

  final _companyName = TextEditingController();
  final _contactPerson = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _campaignObjectives = TextEditingController();
  final _targetAudience = TextEditingController();
  final _additionalInfo = TextEditingController();

  /// Matches the `<option>` values in templates/advertise.html exactly —
  /// these are the literal strings api.py stores, not display labels.
  static const _industries = <String, String>{
    'construction_equipment': 'Construction Equipment',
    'building_materials': 'Building Materials',
    'construction_services': 'Construction Services',
    'real_estate': 'Real Estate',
    'engineering_services': 'Engineering Services',
    'software_technology': 'Software & Technology',
    'financial_services': 'Financial Services',
    'other': 'Other',
  };

  static const _budgetRanges = <String, String>{
    '25k-50k': 'KSh 25,000 – 50,000',
    '50k-100k': 'KSh 50,000 – 100,000',
    '100k-200k': 'KSh 100,000 – 200,000',
    '200k+': 'KSh 200,000+',
  };

  static const _durations = <String, String>{
    '1_month': '1 Month',
    '3_months': '3 Months',
    '6_months': '6 Months',
    '12_months': '12 Months',
    'ongoing': 'Ongoing',
  };

  String? _industry;
  String? _budgetRange;
  String? _duration;
  bool _submitting = false;
  bool _submitted = false;
  String? _reference;

  @override
  void dispose() {
    for (final c in [
      _companyName, _contactPerson, _email, _phone,
      _campaignObjectives, _targetAudience, _additionalInfo,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final res = await _api.submitAdvertisingInquiry(
      companyName: _companyName.text.trim(),
      contactPerson: _contactPerson.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      industry: _industry,
      campaignObjectives: _campaignObjectives.text.trim(),
      targetAudience: _targetAudience.text.trim(),
      budgetRange: _budgetRange,
      campaignDuration: _duration,
      additionalInfo: _additionalInfo.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      setState(() {
        _submitted = true;
        _reference = res['reference'] as String?;
      });
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
          'Advertise with Us',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: ContentWidth(
        maxWidth: 700,
        child: _submitted ? _successView() : _form(),
      ),
    );
  }

  Widget _successView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 48),
              const SizedBox(height: 16),
              Text(
                'Enquiry received',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Our advertising team will be in touch shortly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSubtle),
              ),
              if (_reference != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Reference: $_reference',
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _form() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Reach thousands of construction professionals and decision-makers '
            'across Kenya through Mjengo Hub.',
            style: GoogleFonts.montserrat(fontSize: 12.5, height: 1.5, color: AppColors.textSubtle),
          ),
          const SizedBox(height: 20),

          const FieldLabel('Company / brand name', required: true),
          AppTextField(
            controller: _companyName,
            hint: 'Your company or brand name',
            validator: (v) => requiredField(v, 'Company name'),
          ),
          const SizedBox(height: 14),

          const FieldLabel('Contact person', required: true),
          AppTextField(
            controller: _contactPerson,
            hint: 'Full name',
            validator: (v) => requiredField(v, 'Contact person'),
          ),
          const SizedBox(height: 14),

          const FieldLabel('Email', required: true),
          AppTextField(
            controller: _email,
            hint: 'you@company.com',
            keyboard: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            validator: emailField,
          ),
          const SizedBox(height: 14),

          const FieldLabel('Phone', required: true),
          AppTextField(
            controller: _phone,
            hint: '07xx xxx xxx',
            keyboard: TextInputType.phone,
            validator: (v) => requiredField(v, 'Phone'),
          ),
          const SizedBox(height: 14),

          const FieldLabel('Industry'),
          AppDropdown<String>(
            value: _industry,
            items: _industries.keys.toList(),
            labelOf: (k) => _industries[k]!,
            hint: 'Select industry',
            onChanged: (v) => setState(() => _industry = v),
          ),
          const SizedBox(height: 14),

          const FieldLabel('Campaign objectives'),
          AppTextField(
            controller: _campaignObjectives,
            hint: 'e.g. brand awareness, lead generation, product launch',
            maxLines: 3,
          ),
          const SizedBox(height: 14),

          const FieldLabel('Target audience'),
          AppTextField(
            controller: _targetAudience,
            hint: 'e.g. contractors, architects, project managers, specific regions',
            maxLines: 3,
          ),
          const SizedBox(height: 14),

          const FieldLabel('Budget range'),
          AppDropdown<String>(
            value: _budgetRange,
            items: _budgetRanges.keys.toList(),
            labelOf: (k) => _budgetRanges[k]!,
            hint: 'Select budget range',
            onChanged: (v) => setState(() => _budgetRange = v),
          ),
          const SizedBox(height: 14),

          const FieldLabel('Campaign duration'),
          AppDropdown<String>(
            value: _duration,
            items: _durations.keys.toList(),
            labelOf: (k) => _durations[k]!,
            hint: 'Select duration',
            onChanged: (v) => setState(() => _duration = v),
          ),
          const SizedBox(height: 14),

          const FieldLabel('Additional information'),
          AppTextField(
            controller: _additionalInfo,
            hint: 'Any additional details, requirements, or questions?',
            maxLines: 4,
          ),
          const SizedBox(height: 24),

          AppSubmitButton(
            label: 'Submit enquiry',
            busy: _submitting,
            onPressed: _submit,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
