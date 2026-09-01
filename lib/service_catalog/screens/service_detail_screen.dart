// lib/service_catalog/screens/service_detail_screen.dart
//
// Service detail + enquiry form, mirroring the website's service page
// (overview, why-choose/benefits, features, process, then the request form).
// Expects the service slug via `Get.arguments`.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/net_image.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/responsive.dart';
import '../models/service_model.dart';
import '../services/service_catalog_service.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, this.slug});

  final String? slug;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final _api = ServiceCatalogService();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _projectTitle = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _timeline = TextEditingController();

  /// Matches the website's budget bands.
  static const _budgets = [
    'Under KES 500k',
    'KES 500k - 2M',
    'KES 2M - 10M',
    'KES 10M - 50M',
    'Over KES 50M',
  ];
  String? _budget;

  ServiceOffering? _service;
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;

  String get _slug => widget.slug ?? (Get.arguments is String ? Get.arguments as String : '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _name, _email, _phone, _company,
      _projectTitle, _description, _location, _timeline,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final s = _slug.isEmpty ? null : await _api.getService(_slug);
    if (!mounted) return;
    setState(() {
      _service = s;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final res = await _api.submitRequest(
      slug: _slug,
      clientName: _name.text.trim(),
      clientEmail: _email.text.trim(),
      clientPhone: _phone.text.trim(),
      projectDescription: _description.text.trim(),
      company: _company.text.trim(),
      projectTitle: _projectTitle.text.trim(),
      location: _location.text.trim(),
      budgetRange: _budget,
      timeline: _timeline.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      setState(() => _submitted = true);
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
    final s = _service;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          s?.name ?? 'Service',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : s == null
              ? _notFound()
              : ContentWidth(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      if (s.image != null && s.image!.isNotEmpty)
                        NetImage(url: s.image, height: 180, width: double.infinity),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (s.basePrice != null && s.basePrice!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'From KES ${s.basePrice}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if ((s.detailedDescription ?? s.description) != null)
                              Text(
                                (s.detailedDescription ?? s.description)!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 13.5,
                                  height: 1.6,
                                  color: AppColors.textDark,
                                ),
                              ),
                            _bullets(s.whyChooseTitle ?? 'Why choose us', s.benefits),
                            _bullets('What is included', s.features),
                            _bullets('How it works', s.process, numbered: true),
                            const SizedBox(height: 24),
                            if (_submitted) _success() else _form(s),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _notFound() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'This service could not be loaded.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 14, color: AppColors.textSubtle),
          ),
        ),
      );

  Widget _bullets(String title, List<String> items, {bool numbered = false}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        ...items.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    numbered
                        ? Text(
                            '${e.key + 1}. ',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue,
                            ),
                          )
                        : const Padding(
                            padding: EdgeInsets.only(top: 5, right: 8),
                            child: Icon(Icons.check_circle,
                                size: 14, color: AppColors.primaryBlue),
                          ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _success() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 34),
            const SizedBox(height: 10),
            Text(
              'Request received',
              style: GoogleFonts.montserrat(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Our team will get back to you shortly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSubtle),
            ),
          ],
        ),
      );

  Widget _form(ServiceOffering s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request this service',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            if (s.formIntro != null && s.formIntro!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                s.formIntro!,
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.textSubtle,
                ),
              ),
            ],
            const SizedBox(height: 18),

            const FieldLabel('Full name', required: true),
            AppTextField(
              controller: _name,
              hint: 'Your name',
              validator: (v) => requiredField(v, 'Name'),
            ),
            const SizedBox(height: 14),

            const FieldLabel('Email', required: true),
            AppTextField(
              controller: _email,
              hint: 'you@example.com',
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

            const FieldLabel('Company'),
            AppTextField(controller: _company, hint: 'Optional'),
            const SizedBox(height: 14),

            const FieldLabel('Project title'),
            AppTextField(controller: _projectTitle, hint: 'Optional'),
            const SizedBox(height: 14),

            const FieldLabel('Project description', required: true),
            AppTextField(
              controller: _description,
              hint: 'Tell us what you need',
              maxLines: 5,
              validator: (v) => requiredField(v, 'Project description'),
            ),
            const SizedBox(height: 14),

            const FieldLabel('Location'),
            AppTextField(controller: _location, hint: 'County / town'),
            const SizedBox(height: 14),

            const FieldLabel('Budget range'),
            AppDropdown<String>(
              value: _budget,
              items: _budgets,
              labelOf: (e) => e,
              hint: 'Select a range',
              onChanged: (v) => setState(() => _budget = v),
            ),
            const SizedBox(height: 14),

            const FieldLabel('Timeline'),
            AppTextField(controller: _timeline, hint: 'e.g. within 3 months'),
            const SizedBox(height: 22),

            AppSubmitButton(
              label: 'Submit request',
              busy: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
