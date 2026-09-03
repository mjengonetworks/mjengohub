// lib/projects/screens/submit_project_screen.dart
//
// Native "Submit a Project" form — replaces the old in-app-browser redirect
// to mjengohub.co.ke/projects/submit. Hits `POST /projects` directly
// (ProjectsService.submitProject); submissions land unapproved pending admin
// review, same as the website form. Pops with `true` on success so callers
// can refresh their list.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../shared/data/kenya_counties.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/responsive.dart';
import '../models/project_model.dart';
import '../services/projects_service.dart';
import '../widgets/projects_map_view.dart';

const _kStatusOptions = ['planned', 'ongoing', 'completed', 'stalled'];
const _kProjectTypeOptions = ['infrastructure', 'private_development'];

String _projectTypeLabel(String t) =>
    t == 'private_development' ? 'Private Development' : 'Infrastructure';

class SubmitProjectScreen extends StatefulWidget {
  /// Pre-selects the project type to match whichever tracker the user came
  /// from (Infrastructure Tracker vs Private Projects) — still changeable.
  final String initialProjectType;

  const SubmitProjectScreen({super.key, this.initialProjectType = 'infrastructure'});

  @override
  State<SubmitProjectScreen> createState() => _SubmitProjectScreenState();
}

class _SubmitProjectScreenState extends State<SubmitProjectScreen> {
  final _api = ProjectsService();
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  String? _county;
  String _status = 'planned';
  late String _projectType = widget.initialProjectType;
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_title, _summary, _description, _location, _latitude, _longitude]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _numberField(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return null;
    return double.tryParse(value) == null ? 'Enter a valid number' : null;
  }

  Future<void> _pickOnMap() async {
    final picked = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MapPickerSheet(),
    );
    if (picked == null) return;
    setState(() {
      _latitude.text = picked.latitude.toStringAsFixed(6);
      _longitude.text = picked.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final lat = double.tryParse(_latitude.text.trim());
    final lng = double.tryParse(_longitude.text.trim());

    final res = await _api.submitProject({
      'title': _title.text.trim(),
      if (_summary.text.trim().isNotEmpty) 'summary': _summary.text.trim(),
      if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
      if (_location.text.trim().isNotEmpty) 'location': _location.text.trim(),
      if (_county != null) 'county': _county,
      'status': _status,
      'project_type': _projectType,
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
    });

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      Get.back(result: true);
      Get.snackbar(
        'Thanks!',
        res['message'] as String? ?? 'Project submitted for admin review',
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
          'Submit a Project',
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
                'Know an infrastructure or private-development project we should '
                'be tracking? Submit it below — it goes live once an admin reviews it.',
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
                hint: 'e.g. Nairobi Expressway Phase 2',
                validator: (v) => requiredField(v, 'Title'),
              ),
              const SizedBox(height: 14),

              const FieldLabel('Project Type', required: true),
              AppDropdown<String>(
                value: _projectType,
                items: _kProjectTypeOptions,
                labelOf: _projectTypeLabel,
                hint: 'Select a project type',
                onChanged: (v) => setState(() => _projectType = v ?? _projectType),
              ),
              const SizedBox(height: 14),

              const FieldLabel('Status', required: true),
              AppDropdown<String>(
                value: _status,
                items: _kStatusOptions,
                labelOf: Project.labelForStatus,
                hint: 'Select a status',
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 14),

              const FieldLabel('County'),
              AppDropdown<String>(
                value: _county,
                items: kKenyaCounties,
                labelOf: (c) => c,
                hint: 'Select a county (optional)',
                onChanged: (v) => setState(() => _county = v),
              ),
              const SizedBox(height: 14),

              const FieldLabel('Location'),
              AppTextField(
                controller: _location,
                hint: 'Road, estate or landmark (optional)',
              ),
              const SizedBox(height: 14),

              const FieldLabel('Summary'),
              AppTextField(
                controller: _summary,
                hint: 'A one- or two-sentence overview (optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              const FieldLabel('Description'),
              AppTextField(
                controller: _description,
                hint: 'Full details about the project (optional)',
                maxLines: 5,
              ),

              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Map coordinates (optional)',
                    style: GoogleFonts.montserrat(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickOnMap,
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: Text('Pick on map', style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _latitude,
                      hint: 'Latitude',
                      keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: _numberField,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _longitude,
                      hint: 'Longitude',
                      keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: _numberField,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              AppSubmitButton(
                label: 'Submit project',
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

/// Tap-to-pick location sheet, reusing the same OSM tiles as ProjectsMapView.
class _MapPickerSheet extends StatefulWidget {
  const _MapPickerSheet();

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  LatLng _picked = kKenyaMapCenter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tap the map to set the location',
                  style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_picked),
                  child: Text('Use this location', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _picked,
                    initialZoom: 6,
                    onTap: (_, point) => setState(() => _picked = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'ke.co.mjengohub.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _picked,
                          width: 34,
                          height: 34,
                          child: const Icon(Icons.location_on, color: AppColors.danger, size: 34),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}
