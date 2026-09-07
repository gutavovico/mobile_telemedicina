import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
<<<<<<< Updated upstream
=======
import 'features/medical_records/presentation/providers/patient_provider.dart';
import 'features/medical_records/presentation/screens/patient_profile_screen.dart';
import 'features/appointments/presentation/providers/appointment_provider.dart';
import 'features/appointments/presentation/screens/appointments_screen.dart';
>>>>>>> Stashed changes

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const TelemedicinaApp());
}

class TelemedicinaApp extends StatelessWidget {
  const TelemedicinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
<<<<<<< Updated upstream
=======
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
>>>>>>> Stashed changes
      ],
      child: MaterialApp(
        title: 'Hospital San Juan de Dios - Telemedicina',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
<<<<<<< Updated upstream
=======
          '/patient-profile': (context) => const PatientProfileScreen(),
          '/appointments': (context) => const AppointmentsScreen(),
>>>>>>> Stashed changes
        },
      ),
    );
  }
}
