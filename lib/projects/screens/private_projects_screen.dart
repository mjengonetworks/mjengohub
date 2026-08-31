// lib/projects/screens/private_projects_screen.dart
//
// "Private Projects" tracker (renamed from "Private Developments" for
// terminology parity with the website). Reuses ProjectsScreen's layout,
// scoped to `project_type = private_development`.
import 'package:flutter/material.dart';

import 'projects_screen.dart';

class PrivateProjectsScreen extends StatelessWidget {
  const PrivateProjectsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ProjectsScreen(
      projectType: 'private_development',
      title: 'Private Projects',
      subtitle: 'Commercial & residential developments across Kenya',
    );
  }
}
