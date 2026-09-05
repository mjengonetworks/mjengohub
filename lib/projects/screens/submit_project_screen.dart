// lib/projects/screens/submit_project_screen.dart
//
// Native "Submit a Project" form — replaces the old in-app-browser redirect
// to mjengohub.co.ke/projects/submit. Hits `POST /projects` directly
// (ProjectsService.submitProject); submissions land unapproved pending admin
// review, same as the website form. Pops with `true` on success so callers
// can refresh their list.
//
// Tracker picker: Infrastructure / Private Development map onto
// Project.project_type; Built History / Africa & World are additional flags
// on the same row (is_built_history / geo_scope), not separate project
// types — see models.py's own comments on those columns. Picking one of the
// latter two here just sets project_type to 'infrastructure' underneath
// (matching how most curated Built History/Africa & World entries already
// are, admin-side) while surfacing that tracker's own fields.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_location_code/open_location_code.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

import '../../shared/data/kenya_counties.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/responsive.dart';
import '../models/project_model.dart';
import '../services/location_search_service.dart';
import '../services/media_pipeline.dart';
import '../services/projects_service.dart';
import '../widgets/projects_map_view.dart';

const _kStatusOptions = ['planned', 'ongoing', 'completed', 'stalled'];

enum _TrackerKind { infrastructure, privateDevelopment, builtHistory, africaWorld }

extension on _TrackerKind {
  String get label => switch (this) {
        _TrackerKind.infrastructure => 'Infrastructure',
        _TrackerKind.privateDevelopment => 'Private Development',
        _TrackerKind.builtHistory => 'Built History',
        _TrackerKind.africaWorld => 'Africa & World',
      };
}

const _kDecades = ['pre-1960s', '1960s', '1970s', '1980s', '1990s', '2000s', '2010s', '2020s+'];
const _kHeritageCategories = <String, String>{
  'public_landmarks': 'Public Landmarks',
  'transport_civil_infrastructure': 'Transport & Civil Infrastructure',
  'commercial_banking_heritage': 'Commercial & Banking Heritage',
  'residential_estates': 'Residential & Estates',
  'religious_cultural': 'Religious & Cultural',
};
const _kRegions = <String, String>{
  'east_africa': 'East Africa',
  'africa': 'Africa',
  'europe': 'Europe',
  'asia': 'Asia',
  'north_america': 'North America',
  'south_america': 'South America',
  'oceania': 'Oceania',
};

class SubmitProjectScreen extends StatefulWidget {
  /// Pre-selects the project type to match whichever tracker the user came
  /// from (Infrastructure Tracker vs Private Projects) — still changeable.
  final String initialProjectType;

  /// When set, this screen runs in edit mode (Admin/Editor/Moderator only —
  /// enforced server-side by `PUT /projects/{id}`): every field is
  /// pre-filled from [existingProject] and submitting calls
  /// `ProjectsService.updateProject` instead of `submitProject`. Media
  /// upload still works the same way (existing media isn't touched; new
  /// picks are appended).
  final Project? existingProject;

  const SubmitProjectScreen({super.key, this.initialProjectType = 'infrastructure', this.existingProject});

  @override
  State<SubmitProjectScreen> createState() => _SubmitProjectScreenState();
}

class _SubmitProjectScreenState extends State<SubmitProjectScreen> {
  final _api = ProjectsService();
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _location = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _plusCode = TextEditingController();

  // Built History fields
  final _architect = TextEditingController();
  final _commissioningAuthority = TextEditingController();
  final _renovationTimeline = TextEditingController();
  String? _decade;
  String? _heritageCategory;
  String _ownership = 'public';

  // Africa & World fields
  final _country = TextEditingController();
  String? _region;

  late final quill.QuillController _descriptionController;

  String? _county;
  String _status = 'planned';
  late _TrackerKind _tracker;
  bool _submitting = false;

  bool get _isEditing => widget.existingProject != null;

  final List<PickedMedia> _progressMedia = [];
  final List<PickedMedia> _renderMedia = [];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProject;
    if (existing == null) {
      _descriptionController = quill.QuillController.basic();
      _tracker = widget.initialProjectType == 'private_development' ? _TrackerKind.privateDevelopment : _TrackerKind.infrastructure;
      return;
    }

    _title.text = existing.title;
    _summary.text = existing.summary ?? '';
    _location.text = existing.location ?? '';
    _latitude.text = existing.latitude?.toStringAsFixed(6) ?? '';
    _longitude.text = existing.longitude?.toStringAsFixed(6) ?? '';
    _plusCode.text = existing.plusCode ?? '';
    _county = existing.county;
    _status = existing.status;
    _architect.text = existing.originalArchitect ?? '';
    _commissioningAuthority.text = existing.commissioningAuthority ?? '';
    _renovationTimeline.text = existing.renovationTimeline ?? '';
    _decade = existing.completionDecade;
    _heritageCategory = existing.heritageCategory;
    _ownership = existing.ownershipType ?? 'public';
    _country.text = existing.country ?? '';
    _region = existing.region;

    _tracker = existing.isBuiltHistory
        ? _TrackerKind.builtHistory
        : existing.geoScope == 'global'
            ? _TrackerKind.africaWorld
            : existing.projectType == 'private_development'
                ? _TrackerKind.privateDevelopment
                : _TrackerKind.infrastructure;

    final html = existing.descriptionOverview ?? existing.description ?? '';
    _descriptionController = html.trim().isEmpty
        ? quill.QuillController.basic()
        : quill.QuillController(
            document: quill.Document.fromDelta(HtmlToDelta().convert(html)),
            selection: const TextSelection.collapsed(offset: 0),
          );
  }

  @override
  void dispose() {
    for (final c in [_title, _summary, _location, _latitude, _longitude, _plusCode, _architect, _commissioningAuthority, _renovationTimeline, _country]) {
      c.dispose();
    }
    _descriptionController.dispose();
    super.dispose();
  }

  String? _numberField(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return null;
    return double.tryParse(value) == null ? 'Enter a valid number' : null;
  }

  void _applyLatLng(LatLng point) {
    setState(() {
      _latitude.text = point.latitude.toStringAsFixed(6);
      _longitude.text = point.longitude.toStringAsFixed(6);
      _plusCode.text = PlusCode.encode(point).toString();
    });
  }

  Future<void> _pickOnMap() async {
    final picked = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MapPickerSheet(),
    );
    if (picked == null) return;
    _applyLatLng(picked);
  }

  Future<void> _useCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        Get.snackbar('Location permission needed', 'Enable location access to use this feature.', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        Get.snackbar('Location services off', 'Turn on location services to use this feature.', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      _applyLatLng(LatLng(position.latitude, position.longitude));
    } catch (e) {
      Get.snackbar('Could not get location', 'Please try again or pick on the map instead.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _pickProgressMedia() async {
    final picked = await MediaPipeline.pickMultiple();
    if (picked.isNotEmpty) setState(() => _progressMedia.addAll(picked));
  }

  Future<void> _pickRenderMedia() async {
    final picked = await MediaPipeline.pickMultiple(imagesOnly: true);
    if (picked.isNotEmpty) setState(() => _renderMedia.addAll(picked));
  }

  String _descriptionHtml() {
    final ops = _descriptionController.document.toDelta().toJson();
    if (ops.isEmpty) return '';
    return QuillDeltaToHtmlConverter(
      List<Map<String, dynamic>>.from(ops.map((o) => Map<String, dynamic>.from(o as Map))),
      ConverterOptions.forEmail(),
    ).convert();
  }

  Map<String, dynamic> _buildPayload() {
    final lat = double.tryParse(_latitude.text.trim());
    final lng = double.tryParse(_longitude.text.trim());
    final isBuiltHistory = _tracker == _TrackerKind.builtHistory;
    final isAfricaWorld = _tracker == _TrackerKind.africaWorld;
    final projectType = _tracker == _TrackerKind.privateDevelopment ? 'private_development' : 'infrastructure';

    return {
      'title': _title.text.trim(),
      if (_summary.text.trim().isNotEmpty) 'summary': _summary.text.trim(),
      'description_overview': _descriptionHtml(),
      if (_location.text.trim().isNotEmpty) 'location': _location.text.trim(),
      if (_county != null) 'county': _county,
      'status': _status,
      'project_type': projectType,
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
      if (_plusCode.text.trim().isNotEmpty) 'plus_code': _plusCode.text.trim(),
      'is_built_history': isBuiltHistory,
      if (isBuiltHistory) ...{
        if (_decade != null) 'completion_decade': _decade,
        if (_heritageCategory != null) 'heritage_category': _heritageCategory,
        'ownership_type': _ownership,
        if (_architect.text.trim().isNotEmpty) 'original_architect': _architect.text.trim(),
        if (_commissioningAuthority.text.trim().isNotEmpty) 'commissioning_authority': _commissioningAuthority.text.trim(),
        if (_renovationTimeline.text.trim().isNotEmpty) 'renovation_timeline': _renovationTimeline.text.trim(),
      },
      'geo_scope': isAfricaWorld ? 'global' : 'local',
      if (isAfricaWorld) ...{
        if (_region != null) 'region': _region,
        if (_country.text.trim().isNotEmpty) 'country': _country.text.trim(),
      },
    };
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final payload = _buildPayload();
    final res = _isEditing ? await _api.updateProject(widget.existingProject!.id, payload) : await _api.submitProject(payload);

    if (!mounted) return;

    if (res['success'] == true) {
      final projectId = _isEditing ? widget.existingProject!.id : res['id'] as int?;
      if (projectId != null) await _uploadAllMedia(projectId);
      if (!mounted) return;
      setState(() => _submitting = false);
      Get.back(result: true);
      Get.snackbar(
        _isEditing ? 'Saved' : 'Thanks!',
        res['message'] as String? ?? (_isEditing ? 'Project updated' : 'Project submitted for admin review'),
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } else {
      setState(() => _submitting = false);
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

  Future<void> _uploadAllMedia(int projectId) async {
    for (final m in _progressMedia) {
      await _api.uploadProjectMedia(projectId: projectId, bytes: m.bytes, filename: m.filename, mediaKind: 'progress');
    }
    for (final m in _renderMedia) {
      await _api.uploadProjectMedia(projectId: projectId, bytes: m.bytes, filename: m.filename, mediaKind: 'render');
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
          _isEditing ? 'Edit Project' : 'Submit a Project',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w500,
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
                _isEditing
                    ? 'Editing this project updates it directly — changes are visible immediately.'
                    : 'Know a project we should be tracking? Submit it below — it goes live once an admin reviews it.',
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

              const FieldLabel('Tracker', required: true),
              AppDropdown<_TrackerKind>(
                value: _tracker,
                items: _TrackerKind.values,
                labelOf: (t) => t.label,
                hint: 'Select a tracker',
                onChanged: (v) => setState(() => _tracker = v ?? _tracker),
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
              _RichTextEditorField(controller: _descriptionController),

              // ── Tracker-specific fields ─────────────────────────────────
              if (_tracker == _TrackerKind.builtHistory) ...[
                const SizedBox(height: 20),
                _sectionTitle('Built History Details'),
                const SizedBox(height: 10),
                const FieldLabel('Decade Completed'),
                AppDropdown<String>(
                  value: _decade,
                  items: _kDecades,
                  labelOf: (d) => d == 'pre-1960s' ? 'Pre-1960s' : d,
                  hint: 'Select a decade (optional)',
                  onChanged: (v) => setState(() => _decade = v),
                ),
                const SizedBox(height: 14),
                const FieldLabel('Heritage Category'),
                AppDropdown<String>(
                  value: _heritageCategory,
                  items: _kHeritageCategories.keys.toList(),
                  labelOf: (k) => _kHeritageCategories[k]!,
                  hint: 'Select a category (optional)',
                  onChanged: (v) => setState(() => _heritageCategory = v),
                ),
                const SizedBox(height: 14),
                const FieldLabel('Ownership', required: true),
                AppDropdown<String>(
                  value: _ownership,
                  items: const ['public', 'private'],
                  labelOf: (o) => o == 'public' ? 'Public Heritage' : 'Private Heritage',
                  hint: 'Select ownership',
                  onChanged: (v) => setState(() => _ownership = v ?? _ownership),
                ),
                const SizedBox(height: 14),
                const FieldLabel('Original Architect'),
                AppTextField(controller: _architect, hint: 'Optional'),
                const SizedBox(height: 14),
                const FieldLabel('Commissioning Authority'),
                AppTextField(controller: _commissioningAuthority, hint: 'Optional'),
                const SizedBox(height: 14),
                const FieldLabel('Renovation Timeline'),
                AppTextField(controller: _renovationTimeline, hint: 'Optional', maxLines: 3),
              ],
              if (_tracker == _TrackerKind.africaWorld) ...[
                const SizedBox(height: 20),
                _sectionTitle('Africa & World Details'),
                const SizedBox(height: 10),
                const FieldLabel('Region', required: true),
                AppDropdown<String>(
                  value: _region,
                  items: _kRegions.keys.toList(),
                  labelOf: (k) => _kRegions[k]!,
                  hint: 'Select a region',
                  onChanged: (v) => setState(() => _region = v),
                ),
                const SizedBox(height: 14),
                const FieldLabel('Country'),
                AppTextField(controller: _country, hint: 'Optional'),
              ],

              const SizedBox(height: 26),
              _sectionTitle('Map Location (optional)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _pickOnMap,
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: Text('Pick on map', style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _useCurrentLocation,
                      icon: const Icon(Icons.my_location_rounded, size: 16),
                      label: Text('Use current location', style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w500)),
                    ),
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
              const SizedBox(height: 8),
              AppTextField(controller: _plusCode, hint: 'Plus Code (auto-filled from map)'),

              const SizedBox(height: 26),
              _sectionTitle('Photos & Videos (optional)'),
              const SizedBox(height: 10),
              _MediaPickerRow(
                label: 'Progress photos/video',
                items: _progressMedia,
                onAdd: _pickProgressMedia,
                onRemove: (i) => setState(() => _progressMedia.removeAt(i)),
              ),
              const SizedBox(height: 14),
              _MediaPickerRow(
                label: 'Project Renders (3D visualizations/walkthroughs)',
                items: _renderMedia,
                onAdd: _pickRenderMedia,
                onRemove: (i) => setState(() => _renderMedia.removeAt(i)),
              ),

              const SizedBox(height: 24),
              AppSubmitButton(
                label: _isEditing ? 'Save changes' : 'Submit project',
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

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.textDark),
      );
}

/// Unified rich-text editor (headings, bold, italics, bullets, links) — the
/// single field the submit/edit form writes to (`description_overview`),
/// replacing the old separate overview/architecture/engineering/
/// environmental fields.
class _RichTextEditorField extends StatelessWidget {
  final quill.QuillController controller;
  const _RichTextEditorField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          quill.QuillSimpleToolbar(
            controller: controller,
            config: const quill.QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showSubscript: false,
              showSuperscript: false,
              showSearchButton: false,
              showClearFormat: false,
              showBackgroundColorButton: false,
              showColorButton: false,
              showCodeBlock: false,
              showInlineCode: false,
              showIndent: false,
              showAlignmentButtons: false,
              multiRowsDisplay: false,
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          SizedBox(
            height: 180,
            child: quill.QuillEditor.basic(
              controller: controller,
              config: const quill.QuillEditorConfig(
                padding: EdgeInsets.all(10),
                placeholder: 'Full details about the project (optional)',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaPickerRow extends StatelessWidget {
  final String label;
  final List<PickedMedia> items;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _MediaPickerRow({required this.label, required this.items, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textDark))),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
              label: Text('Add', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        if (items.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(items.length, (i) {
              final m = items[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(m.isVideo ? Icons.videocam_rounded : Icons.image_rounded, size: 14, color: AppColors.textSubtle),
                    const SizedBox(width: 6),
                    Text(m.filename, style: GoogleFonts.montserrat(fontSize: 10.5, color: AppColors.textSubtle)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onRemove(i),
                      child: const Icon(Icons.close_rounded, size: 14, color: AppColors.danger),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}

/// Tap-to-pick location sheet, reusing the same OSM tiles as ProjectsMapView.
/// Includes a Nominatim search bar above the map — selecting a result pans
/// the map to that point.
class _MapPickerSheet extends StatefulWidget {
  const _MapPickerSheet();

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  LatLng _picked = kKenyaMapCenter;
  final _mapController = MapController();
  final _searchService = LocationSearchService();
  final _searchController = TextEditingController();
  List<LocationSearchResult> _results = [];
  bool _searching = false;

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    final results = await _searchService.search(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  void _selectResult(LocationSearchResult result) {
    setState(() {
      _picked = result.point;
      _results = [];
      _searchController.text = result.displayName;
    });
    _mapController.move(result.point, 14);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                  'Tap the map or search a location',
                  style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textDark),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_picked),
                  child: Text('Use this location', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Location search bar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                AppTextField(
                  controller: _searchController,
                  hint: 'Search for a place, road or landmark',
                  onSubmitted: _search,
                ),
                if (_searching)
                  const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(minHeight: 2)),
                if (_results.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 160),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(10)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        title: Text(_results[i].displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: 12)),
                        onTap: () => _selectResult(_results[i]),
                      ),
                    ),
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
                  mapController: _mapController,
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
