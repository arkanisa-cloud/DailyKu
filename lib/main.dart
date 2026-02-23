import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();
  
  // Refresh notifications (to handle reboot or missed schedules)
  await notificationService.refreshNotifications();

  await initializeDateFormatting(
      'id_ID', null); // Inisialisasi untuk locale Indonesia
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dailyku",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF34729C),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
