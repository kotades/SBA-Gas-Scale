import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/contacts/presentation/emergency_contacts_screen.dart';
import 'features/hardware/presentation/hardware_config_screen.dart';

void main() {
  runApp(const ProviderScope(child: SbaGasScaleApp()));
}

class SbaGasScaleApp extends StatefulWidget {
  const SbaGasScaleApp({super.key});

  @override
  State<SbaGasScaleApp> createState() => _SbaGasScaleAppState();
}

class _SbaGasScaleAppState extends State<SbaGasScaleApp> {
  int _currentTab = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    EmergencyContactsScreen(),
    HardwareConfigScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SBA Gas Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.cyanAccent,
          surface: AppColors.surface,
        ),
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _currentTab,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentTab,
          onDestinationSelected: (index) => setState(() => _currentTab = index),
          backgroundColor: const Color(0xFF121829),
          indicatorColor: AppColors.cyanAccent.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppColors.cyanAccent),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.contact_phone_outlined),
              selectedIcon: Icon(Icons.contact_phone, color: AppColors.cyanAccent),
              label: 'Contacts',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: AppColors.cyanAccent),
              label: 'Hardware',
            ),
          ],
        ),
      ),
    );
  }
}
