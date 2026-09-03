import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../navigation/app_header.dart';
import '../../shared/theme/app_theme.dart';

class LocalPrivateProject {
  final String id;
  final String title;
  final String location;
  final String category;
  final double budget;
  final List<String> completedPhases;

  LocalPrivateProject({
    required this.id,
    required this.title,
    required this.location,
    required this.category,
    required this.budget,
    required this.completedPhases,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'location': location,
        'category': category,
        'budget': budget,
        'completedPhases': completedPhases,
      };

  factory LocalPrivateProject.fromJson(Map<String, dynamic> json) =>
      LocalPrivateProject(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        location: json['location'] ?? '',
        category: json['category'] ?? 'Residential',
        budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
        completedPhases: List<String>.from(json['completedPhases'] ?? []),
      );
}

class PrivateProjectsScreen extends StatefulWidget {
  const PrivateProjectsScreen({Key? key}) : super(key: key);

  @override
  State<PrivateProjectsScreen> createState() => _PrivateProjectsScreenState();
}

class _PrivateProjectsScreenState extends State<PrivateProjectsScreen> {
  static const _storageKey = 'mjengo_local_private_projects';
  final List<LocalPrivateProject> _projects = [];
  bool _loading = true;

  static const List<String> _standardPhases = [
    'Site Preparation & Substructure',
    'Superstructure / Walling',
    'Roofing & Framing',
    'Plumbing & Electrical Rough-in',
    'Finishing & Interior Works',
  ];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final List decoded = jsonDecode(raw);
      _projects.clear();
      _projects.addAll(decoded.map((e) => LocalPrivateProject.fromJson(e)));
    }
    setState(() => _loading = false);
  }

  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_projects.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
    setState(() {});
  }

  void _showAddProjectDialog() {
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    String category = 'Residential';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Private Project',
                style: GoogleFonts.montserrat(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(
                  labelText: 'Location / County',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Estimated Budget (KES)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final project = LocalPrivateProject(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleCtrl.text.trim(),
                      location: locationCtrl.text.trim(),
                      category: category,
                      budget: double.tryParse(budgetCtrl.text) ?? 0.0,
                      completedPhases: [],
                    );
                    _projects.insert(0, project);
                    _saveProjects();
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'Save Project',
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppHeader(),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColors.textDark),
                ),
                const SizedBox(width: 12),
                Text(
                  'Private Projects',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      color: const Color(0xFF2563EB), size: 26),
                  onPressed: _showAddProjectDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _projects.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.apartment_rounded,
                                  size: 64, color: const Color(0xFF8888AA)),
                              const SizedBox(height: 16),
                              Text(
                                'No Private Projects Yet',
                                style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Track private construction budgets, milestones, and site progress locally.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    color: const Color(0xFF8888AA)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Your First Project'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _showAddProjectDialog,
                              )
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _projects.length,
                        itemBuilder: (ctx, index) {
                          final p = _projects[index];
                          final progress = _standardPhases.isEmpty
                              ? 0.0
                              : p.completedPhases.length /
                                  _standardPhases.length;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.title,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                            color: Colors.redAccent),
                                        onPressed: () {
                                          _projects.removeAt(index);
                                          _saveProjects();
                                        },
                                      ),
                                    ],
                                  ),
                                  if (p.location.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 14,
                                            color: const Color(0xFF8888AA)),
                                        const SizedBox(width: 4),
                                        Text(
                                          p.location,
                                          style: GoogleFonts.montserrat(
                                              fontSize: 12,
                                              color: const Color(0xFF8888AA)),
                                        ),
                                      ],
                                    ),
                                  if (p.budget > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Budget: KES ${p.budget.toStringAsFixed(0)}',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              const Color(0xFF2563EB)),
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${(progress * 100).toInt()}% Completed (${p.completedPhases.length}/${_standardPhases.length} Phases)',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF8888AA)),
                                  ),
                                  const Divider(height: 20),
                                  ..._standardPhases.map((phase) {
                                    final done =
                                        p.completedPhases.contains(phase);
                                    return InkWell(
                                      onTap: () {
                                        if (done) {
                                          p.completedPhases.remove(phase);
                                        } else {
                                          p.completedPhases.add(phase);
                                        }
                                        _saveProjects();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              done
                                                  ? Icons.check_circle_rounded
                                                  : Icons
                                                      .radio_button_unchecked_rounded,
                                              size: 18,
                                              color: done
                                                  ? const Color(0xFF2563EB)
                                                  : Colors.grey.shade400,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                phase,
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 12,
                                                  color: done
                                                      ? AppColors.textDark
                                                      : const Color(0xFF8888AA),
                                                  decoration: done
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

