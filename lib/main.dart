import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/audio/audio_cue_service.dart';
import 'core/constants/app_colors.dart';
import 'core/services/foreground_service_manager.dart';
import 'core/services/wakelock_service.dart';
import 'data/datasources/database/app_database.dart';
import 'data/repositories/race_session_repository_impl.dart';
import 'data/repositories/vehicle_repository_impl.dart';
import 'domain/repositories/race_session_repository.dart';
import 'domain/repositories/vehicle_repository.dart';
import 'presentation/bloc/history/history_bloc.dart';
import 'presentation/bloc/settings/settings_cubit.dart';
import 'presentation/bloc/timer/race_timer_bloc.dart';
import 'presentation/bloc/timer/race_timer_event.dart';
import 'presentation/bloc/vehicle/vehicle_bloc.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preferred device orientations for motorcycle handlebar mount
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize DB & Audio
  final database = AppDatabase();
  final audioCue = AudioCueService();
  await audioCue.init();
  await WakelockService.enable();
  await ForegroundServiceManager.init();

  final sessionRepo = RaceSessionRepositoryImpl(database);
  final vehicleRepo = VehicleRepositoryImpl(database);

  runApp(RaceBoxApp(
    sessionRepo: sessionRepo,
    vehicleRepo: vehicleRepo,
    audioCue: audioCue,
  ));
}

class RaceBoxApp extends StatelessWidget {
  final RaceSessionRepository sessionRepo;
  final VehicleRepository vehicleRepo;
  final AudioCueService audioCue;

  const RaceBoxApp({
    super.key,
    required this.sessionRepo,
    required this.vehicleRepo,
    required this.audioCue,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<RaceSessionRepository>.value(value: sessionRepo),
        RepositoryProvider<VehicleRepository>.value(value: vehicleRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>(
            create: (_) => SettingsCubit(),
          ),
          BlocProvider<VehicleBloc>(
            create: (_) => VehicleBloc(vehicleRepo: vehicleRepo),
          ),
          BlocProvider<HistoryBloc>(
            create: (_) => HistoryBloc(sessionRepo: sessionRepo),
          ),
          BlocProvider<RaceTimerBloc>(
            create: (_) => RaceTimerBloc(
              sessionRepo: sessionRepo,
              vehicleRepo: vehicleRepo,
              audioCue: audioCue,
            )..add(const InitTelemetryServices()),
          ),
        ],
        child: MaterialApp(
          title: 'RaceBox Mobile Telemetry',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.background,
            primaryColor: AppColors.cyan,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.cyan,
              secondary: AppColors.green,
              surface: AppColors.surface,
              error: AppColors.red,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.surface,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
              iconTheme: IconThemeData(color: AppColors.textPrimary),
            ),
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
