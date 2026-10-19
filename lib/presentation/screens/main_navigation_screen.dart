import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../../core/constants/app_colors.dart';
import '../bloc/history/history_bloc.dart';
import '../bloc/history/history_event.dart';
import '../bloc/vehicle/vehicle_bloc.dart';
import '../bloc/vehicle/vehicle_event.dart';
import 'history_screen.dart';
import 'race_hud_screen.dart';
import 'settings_screen.dart';
import 'vehicle_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RaceHudScreen(),
    HistoryScreen(),
    VehicleScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: WithForegroundTask(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 1) {
              context.read<HistoryBloc>().add(const LoadHistorySessions());
            } else if (index == 2) {
              context.read<VehicleBloc>().add(LoadVehicles());
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.cyan,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.0),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11.0),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.speed),
              activeIcon: Icon(Icons.speed, color: AppColors.cyan),
              label: 'RACE HUD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              activeIcon: Icon(Icons.history, color: AppColors.cyan),
              label: 'RIWAYAT',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.two_wheeler),
              activeIcon: Icon(Icons.two_wheeler, color: AppColors.cyan),
              label: 'GARASI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune),
              activeIcon: Icon(Icons.tune, color: AppColors.cyan),
              label: 'PENGATURAN',
            ),
          ],
        ),
      ),
    );
  }
}
