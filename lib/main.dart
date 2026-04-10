import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'widgets/nav_bar.dart';
import 'sections/hero_section.dart';
import 'sections/about_section.dart';
import 'sections/projects_section.dart';
import 'sections/contact_section.dart';
import 'sections/footer_section.dart';

void main() {
  runApp(const PureBlancheApp());
}

class PureBlancheApp extends StatelessWidget {
  const PureBlancheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blanche',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();

  final _aboutKey = GlobalKey();
  final _projectsKey = GlobalKey();
  final _contactKey = GlobalKey();

  void _scrollTo(String section) {
    final key = switch (section) {
      'about' => _aboutKey,
      'projects' => _projectsKey,
      'contact' => _contactKey,
      _ => null,
    };
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.abyss,
      body: Column(
        children: [
          NavBar(onNavigate: _scrollTo),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  const HeroSection(),
                  _divider(),
                  KeyedSubtree(
                    key: _aboutKey,
                    child: const Center(child: AboutSection()),
                  ),
                  _divider(),
                  KeyedSubtree(
                    key: _projectsKey,
                    child: const Center(child: ProjectsSection()),
                  ),
                  _divider(),
                  KeyedSubtree(
                    key: _contactKey,
                    child: const Center(child: ContactSection()),
                  ),
                  const FooterSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: Divider(
        color: AppColors.warmCharcoal.withValues(alpha: 0.5),
        height: 1,
      ),
    );
  }
}
