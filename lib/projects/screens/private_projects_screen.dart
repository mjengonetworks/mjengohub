// lib/projects/screens/private_projects_screen.dart
//
// Thin wrapper around the real, API-backed ProjectsScreen filtered to
// project_type=private_development — mirrors the website's "Private Projects
// Tracker" (templates/private_developments.html), which is the same Project
// model as the Infrastructure Tracker, just filtered differently.
//
// This used to be a completely separate screen backed by shared_preferences
// (`LocalPrivateProject`), with zero connection to `/api/v1` — every project
// shown was device-local, invisible to anyone else and unrelated to the real
// Project rows admins manage on the website. Replaced entirely rather than
// patched, since none of that state was salvageable or ever matched a real
// backend row.
import 'package:flutter/material.dart';

import 'projects_screen.dart';

class PrivateProjectsScreen extends StatelessWidget {
  const PrivateProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProjectsScreen(
        projectType: 'private_development',
        title: "Private Projects",
        subtitle: 'Malls, business parks, estates & mixed-use developments',
      );
}
