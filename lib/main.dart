import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/localization/language_provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/soil_sensor_repository.dart';
import 'ui/viewmodels/soil_sensor_viewmodel.dart';
import 'ui/views/home_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Support all orientations (Portrait, Landscape, Tablets & Foldables)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Dark navigation bar and status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SoilParameterApp());
}

class SoilParameterApp extends StatelessWidget {
  const SoilParameterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LanguageProvider()..loadPreferences(),
        ),
        ChangeNotifierProvider(
          create: (_) => SoilSensorViewModel(
            repository: SoilSensorRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'SOIL AI ANALYZER',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeDashboardScreen(),
      ),
    );
  }
}
