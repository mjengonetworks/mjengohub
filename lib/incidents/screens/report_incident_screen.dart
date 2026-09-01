// lib/incidents/screens/report_incident_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/incidents_service.dart';

const _kDark    = Color(0xFF1A1A2E);
const _kSubtext = Color(0xFF8888AA);
const _kDivider = Color(0xFFEEEEF5);
const _kBg      = Color(0xFFF8FAFC);

class ReportIncidentScreen extends StatefulWidget {
  final String incidentType; // 'road_safety' or 'site_safety'
  const ReportIncidentScreen({Key? key, required this.incidentType})
      : super(key: key);

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _service = IncidentsService();
  final _formKey = GlobalKey<FormState>();
  final _picker  = ImagePicker();

  final _titleCtrl       = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _locationCtrl    = TextEditingController();
  final _countyCtrl      = TextEditingController();
  final _lessonsCtrl     = TextEditingController();
  final _casualtiesCtrl  = TextEditingController(text: '0');
  final _injuriesCtrl    = TextEditingController(text: '0');

  String _severity = 'moderate';
  DateTime? _incidentDate;
  bool _submitting = false;
  bool _submitted = false;
  final _selectedImages = <XFile>[];

  bool get _isRoad => widget.incidentType == 'road_safety';
  Color get _primary => _isRoad ? const Color(0xFFDC2626) : const Color(0xFFF97316);
  Color get _dark    => _isRoad ? const Color(0xFF7F1D1D) : const Color(0xFF431407);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _countyCtrl.dispose();
    _lessonsCtrl.dispose();
    _casualtiesCtrl.dispose();
    _injuriesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _incidentDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_incidentDate == null) {
      Get.snackbar('Required', 'Please select the incident date.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _submitting = true);

    final dateStr =
        '${_incidentDate!.year}-${_incidentDate!.month.toString().padLeft(2, '0')}-${_incidentDate!.day.toString().padLeft(2, '0')}';

    try {
      final incidentId = await _service.submitNewIncident(
        incidentType: widget.incidentType,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        county: _countyCtrl.text.trim(),
        incidentDate: dateStr,
        severity: _severity,
        casualties: int.tryParse(_casualtiesCtrl.text) ?? 0,
        injuries: int.tryParse(_injuriesCtrl.text) ?? 0,
        lessonsLearned: _lessonsCtrl.text.trim(),
      );
      if (incidentId != null) {
        for (final img in _selectedImages) {
          await _service.uploadIncidentImage(
            incidentId: incidentId,
            imageFile: img,
          );
        }
        setState(() => _submitted = true);
      } else {
        Get.snackbar('Error', 'Could not submit. Please try again.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_dark, _primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report an Incident',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _isRoad
                              ? 'Road safety incident'
                              : 'Construction site incident',
                          style: GoogleFonts.montserrat(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _submitted ? _buildSuccess() : _buildForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF16A34A), size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              'Report Submitted!',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you. Your incident report is under review by our editors and will be published once verified.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 13.5, color: _kSubtext, height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Back to Incidents',
                    style: GoogleFonts.montserrat(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoBox(
              'Reports are reviewed by our team before appearing on the site. Provide as much detail as possible.',
            ),
            const SizedBox(height: 16),

            _label('Incident Title *'),
            _textField(
              controller: _titleCtrl,
              hint: 'e.g. Truck collision on Mombasa Road',
              validator: (v) =>
                  v == null || v.trim().length < 5 ? 'Too short' : null,
            ),
            const SizedBox(height: 14),

            _label('What Happened *'),
            _textField(
              controller: _descCtrl,
              hint: 'Describe the incident in detail…',
              maxLines: 5,
              validator: (v) =>
                  v == null || v.trim().length < 20 ? 'Please add more detail' : null,
            ),
            const SizedBox(height: 14),

            _label('Location *'),
            _textField(
              controller: _locationCtrl,
              hint: 'e.g. Mombasa Road near Syokimau',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            _label('County'),
            _textField(
              controller: _countyCtrl,
              hint: 'e.g. Machakos',
            ),
            const SizedBox(height: 14),

            // Date picker
            _label('Incident Date *'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kDivider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 18, color: _kSubtext),
                    const SizedBox(width: 10),
                    Text(
                      _incidentDate == null
                          ? 'Select date…'
                          : '${_incidentDate!.day}/${_incidentDate!.month}/${_incidentDate!.year}',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        color: _incidentDate == null
                            ? _kSubtext
                            : _kDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Severity
            _label('Severity'),
            DropdownButtonFormField<String>(
              value: _severity,
              items: const [
                DropdownMenuItem(value: 'minor', child: Text('Minor')),
                DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                DropdownMenuItem(value: 'serious', child: Text('Serious')),
                DropdownMenuItem(value: 'fatal', child: Text('Fatal')),
              ],
              onChanged: (v) => setState(() => _severity = v!),
              style: GoogleFonts.montserrat(fontSize: 13.5, color: _kDark),
              decoration: _inputDec('Severity'),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 14),

            // Casualties / Injuries row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Fatalities'),
                      _textField(
                        controller: _casualtiesCtrl,
                        hint: '0',
                        keyboard: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Injured'),
                      _textField(
                        controller: _injuriesCtrl,
                        hint: '0',
                        keyboard: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _label('Key Lessons Learned (optional)'),
            _textField(
              controller: _lessonsCtrl,
              hint: 'What could have prevented this?',
              maxLines: 3,
            ),
            const SizedBox(height: 14),

            _label('Photos (optional, up to 4)'),
            _buildImagePicker(),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        'Submit Report',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Reviewed by our team before publishing.',
                style: GoogleFonts.montserrat(
                    fontSize: 11.5, color: _kSubtext),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Image picker ──────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 4) return;

    // Web: go straight to the file picker — browsers block it after an async
    // bottom sheet dismissal, and camera is not reliably supported.
    if (kIsWeb) {
      final picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() {
          final remaining = 4 - _selectedImages.length;
          _selectedImages.addAll(picked.take(remaining));
        });
      }
      return;
    }

    // Mobile: ask Camera vs Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _kDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: _primary),
              title: Text('Camera',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: _primary),
              title: Text('Photo Library',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    if (source == ImageSource.gallery) {
      final picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() {
          final remaining = 4 - _selectedImages.length;
          _selectedImages.addAll(picked.take(remaining));
        });
      }
    } else {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked != null) setState(() => _selectedImages.add(picked));
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (_, i) => Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Image.network(_selectedImages[i].path,
                              fit: BoxFit.cover, width: 80, height: 80)
                          : Image.file(File(_selectedImages[i].path),
                              fit: BoxFit.cover, width: 80, height: 80),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImages.removeAt(i)),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_selectedImages.length < 4)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kDivider),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: _primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _selectedImages.isEmpty
                        ? 'Add photos (camera or gallery)'
                        : 'Add more (${_selectedImages.length}/4)',
                    style: GoogleFonts.montserrat(
                        fontSize: 13, color: _kSubtext),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: GoogleFonts.montserrat(
              fontSize: 12, fontWeight: FontWeight.w600, color: _kDark)),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      style: GoogleFonts.montserrat(fontSize: 13.5, color: _kDark),
      decoration: _inputDec(hint),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.montserrat(fontSize: 13, color: _kSubtext),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFDC2626), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      );

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    color: _primary,
                    fontWeight: FontWeight.w500,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}

