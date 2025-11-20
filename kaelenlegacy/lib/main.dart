import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/providers/settings_config_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsConfigProvider(),
      child: MaterialApp(
        home: HomeScreen(),
        theme: ThemeData(useMaterial3: true),
      ),
    ),
  );
}
