import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/theme/app_theme.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({Key? key}) : super(key: key);

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _severity = 'Medium';
  String _incidentType = 'Site Hazard';

  static const _draftKey = 'mjengo_incident_draft';

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw != null && raw.isNotEmpty) {
      final data = jsonDecode(raw);
      _titleCtrl.text = data['title'] ?? '';
      _locationCtrl.text = data['location'] ?? '';
      _descCtrl.text = data['desc'] ?? '';
      _severity = data['severity'] ?? 'Medium';
      _incidentType = data['incidentType'] ?? 'Site Hazard';
      setState(() {});
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'title': _titleCtrl.text,
      'location': _locationCtrl.text,
      'desc': _descCtrl.text,
      'severity': _severity,
      'incidentType': _incidentType,
    };
    await prefs.setString(_draftKey, jsonEncode(data));
  }

  void _submitReport() async {
    if (_titleCtrl.text.trim().isEmpty || _locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a title and location')),
      );
      return;
    }

    final message = '''
*SAFETY INCIDENT REPORT - MJENGO HUB*
*Type:* $_incidentType
*Severity:* $_severity
*Location:* ${_locationCtrl.text.trim()}
*Title:* ${_titleCtrl.text.trim()}
*Details:* ${_descCtrl.text.trim()}
''';

    final waUrl = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
      if (mounted) {
        Get.back();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report dispatched successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColors.textDark),
                ),
                const SizedBox(width: 12),
                Text(
                  'Report Safety Incident',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _titleCtrl,
                  onChanged: (_) => _saveDraft(),
                  decoration: InputDecoration(
                    labelText: 'Incident Title / Summary',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _locationCtrl,
                  onChanged: (_) => _saveDraft(),
                  decoration: InputDecoration(
                    labelText: 'Location (Site / County / Road)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _incidentType,
                  decoration: InputDecoration(
                    labelText: 'Incident Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Site Hazard', child: Text('Site Hazard')),
                    DropdownMenuItem(value: 'Structural Failure', child: Text('Structural Failure')),
                    DropdownMenuItem(value: 'Equipment Accident', child: Text('Equipment Accident')),
                    DropdownMenuItem(value: 'Worker Injury', child: Text('Worker Injury')),
                    DropdownMenuItem(value: 'Near Miss', child: Text('Near Miss')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _incidentType = val);
                      _saveDraft();
                    }
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _severity,
                  decoration: InputDecoration(
                    labelText: 'Severity Level',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Low', child: Text('Low - Precautionary')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium - Urgent Attention')),
                    DropdownMenuItem(value: 'Critical', child: Text('Critical - Emergency')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _severity = val);
                      _saveDraft();
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  onChanged: (_) => _saveDraft(),
                  decoration: InputDecoration(
                    labelText: 'Detailed Description',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _submitReport,
                  icon: const Icon(Icons.send_rounded),
                  label: Text('Submit & Dispatch Report',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
