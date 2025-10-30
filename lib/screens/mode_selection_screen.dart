import 'package:flutter/material.dart';
import '../services/lock_manager.dart';
import '../models/business_mode.dart';
import '../services/app_settings.dart';
import '../widgets/tutorial_overlay.dart';
import 'table_selection_screen.dart';
import 'retail_pos_screen.dart';
import 'cafe_pos_screen.dart';
import 'settings_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    await AppSettings.instance.init();

    if (!AppSettings.instance.hasSeenTutorial && mounted) {
      // Show tutorial after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showTutorial = true;
          });
        }
      });
    }
  }

  void _selectMode(BuildContext context, BusinessMode mode) {
    if (_showTutorial) return; // Prevent selection during tutorial

    Widget screen;

    switch (mode) {
      case BusinessMode.restaurant:
        screen = const TableSelectionScreen();
        break;
      case BusinessMode.cafe:
        screen = const CafePOSScreen();
        break;
      case BusinessMode.retail:
        screen = const RetailPOSScreen();
        break;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _showTutorialDialog() {
    setState(() {
      _showTutorial = true;
    });
  }

  void _completeTutorial() {
    AppSettings.instance.markTutorialAsSeen();
    setState(() {
      _showTutorial = false;
    });
  }

  void _skipTutorial() {
    AppSettings.instance.markTutorialAsSeen();
    setState(() {
      _showTutorial = false;
    });
  }

  List<TutorialStep> _getTutorialSteps() {
    return [
      TutorialStep(
        title: 'Welcome to ExtroPOS!',
        description:
            'Your complete Point of Sale solution for retail, cafe, and restaurant businesses. Let\'s get you started with a quick tour.',
        icon: Icons.waving_hand,
      ),
      TutorialStep(
        title: 'Training Mode',
        description:
            'Use Training Mode to practice without affecting real data. Perfect for learning the system or training new staff members.',
        icon: Icons.school,
      ),
      TutorialStep(
        title: 'Choose Your Business Type',
        description:
            'Select Retail for product sales, Cafe for quick service, or Restaurant for table service. You can switch between modes anytime.',
        icon: Icons.business,
      ),
      TutorialStep(
        title: 'Settings & Configuration',
        description:
            'Access Settings to configure categories, items, printers, users, and more. Customize ExtroPOS to fit your business needs.',
        icon: Icons.settings,
      ),
      TutorialStep(
        title: 'Ready to Start!',
        description:
            'You\'re all set! Select a business mode to begin. Need help? Look for the guide icon throughout the app.',
        icon: Icons.check_circle,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-right logout button
        Positioned(
          top: 8,
          right: 8,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Lock / Logout',
              onPressed: () {
                // Lock the app and navigate to lock screen
                LockManager.instance.lock();
                Navigator.pushReplacementNamed(context, '/lock');
              },
            ),
          ),
        ),
        Scaffold(
          backgroundColor: const Color(0xFF2563EB),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.settings, color: Color(0xFF2563EB)),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo/Title
                    const Icon(Icons.store, size: 80, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'ExtroPOS',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select Business Mode',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Training Mode Toggle & Help Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'Training Mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedBuilder(
                            animation: AppSettings.instance,
                            builder: (context, child) {
                              return Switch(
                                value: AppSettings.instance.isTrainingMode,
                                onChanged: (value) {
                                  AppSettings.instance.setTrainingMode(value);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value
                                            ? 'Training Mode enabled - Practice safely!'
                                            : 'Training Mode disabled - Using real data',
                                      ),
                                      backgroundColor: value
                                          ? Colors.orange
                                          : Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                thumbColor: WidgetStateProperty.resolveWith(
                                  (states) =>
                                      states.contains(WidgetState.selected)
                                      ? Colors.orange
                                      : null,
                                ),
                                trackColor: WidgetStateProperty.resolveWith(
                                  (states) =>
                                      states.contains(WidgetState.selected)
                                      ? Colors.orange.shade200
                                      : null,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _showTutorialDialog,
                            icon: const Icon(Icons.help_outline),
                            color: Colors.white,
                            tooltip: 'Show Tutorial',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Training Mode Banner
                    AnimatedBuilder(
                      animation: AppSettings.instance,
                      builder: (context, child) {
                        if (!AppSettings.instance.isTrainingMode) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.info,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'TRAINING MODE ACTIVE - Data will not be saved',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Mode Cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Use Wrap for better responsiveness and to avoid overflow
                        return Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 24,
                          runSpacing: 24,
                          children: [
                            _ModeCard(
                              mode: BusinessMode.retail,
                              icon: Icons.shopping_bag,
                              onTap: () =>
                                  _selectMode(context, BusinessMode.retail),
                            ),
                            _ModeCard(
                              mode: BusinessMode.cafe,
                              icon: Icons.local_cafe,
                              onTap: () =>
                                  _selectMode(context, BusinessMode.cafe),
                            ),
                            _ModeCard(
                              mode: BusinessMode.restaurant,
                              icon: Icons.restaurant,
                              onTap: () =>
                                  _selectMode(context, BusinessMode.restaurant),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Tutorial Overlay
        if (_showTutorial)
          TutorialOverlay(
            steps: _getTutorialSteps(),
            onComplete: _completeTutorial,
            onSkip: _skipTutorial,
          ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final BusinessMode mode;
  final IconData icon;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 220),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: Text(
                  mode.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mode.subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
