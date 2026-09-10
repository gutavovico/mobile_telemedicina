import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'features/analytics/presentation/screens/analytics_screen.dart';
import 'features/appointments/presentation/controllers/doctor_controller.dart';
import 'features/appointments/presentation/providers/appointment_provider.dart';
import 'features/appointments/presentation/screens/appointments_screen.dart';
import 'features/appointments/presentation/screens/doctor_catalog_screen.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/communications/presentation/screens/communications_screen.dart';
import 'features/medical_records/presentation/providers/clinical_documents_provider.dart';
import 'features/medical_records/presentation/providers/ficha_provider.dart';
import 'features/medical_records/presentation/providers/patient_provider.dart';
import 'features/medical_records/presentation/screens/book_ficha_screen.dart';
import 'features/medical_records/presentation/screens/documents_list_screen.dart';
import 'features/medical_records/presentation/screens/fichas_screen.dart';
import 'features/medical_records/presentation/screens/home_screen.dart';
import 'features/medical_records/presentation/screens/patient_profile_screen.dart';

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
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => DoctorController()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => FichaProvider()),
        ChangeNotifierProvider(create: (_) => ClinicalDocumentsProvider()),
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
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
          '/home': (context) => const HomeScreen(),
          '/patient-profile': (context) => const PatientProfileScreen(),
          '/doctors': (context) => const DoctorCatalogScreen(),
          '/appointments': (context) => const AppointmentsScreen(),
          '/citas': (context) => const AppointmentsScreen(),
          '/fichas': (context) => const FichasScreen(),
          '/fichas/nueva': (context) => const BookFichaScreen(),
          '/documentos': (context) => const DocumentsListScreen(),
          '/mis-documentos': (context) => const DocumentsListScreen(),
          '/communications': (context) => const CommunicationsScreen(),
          '/analytics': (context) => const AnalyticsScreen(),
          '/ai-assistant': (context) => const AiAssistantScreen(),
        },
      ),
    );
  }
}
