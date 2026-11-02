import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'features/analytics/reportes/presentation/screens/reports_screen.dart';
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
import 'features/auth/presentation/widgets/patient_only_route.dart';
import 'features/communications/presentation/screens/communications_screen.dart';
import 'features/medical_records/presentation/providers/clinical_documents_provider.dart';
import 'features/medical_records/presentation/providers/ficha_provider.dart';
import 'features/medical_records/presentation/providers/patient_provider.dart';
import 'features/medical_records/presentation/providers/prescription_provider.dart';
import 'features/medical_records/presentation/screens/book_ficha_screen.dart';
import 'features/medical_records/presentation/screens/documents_list_screen.dart';
import 'features/medical_records/presentation/screens/fichas_screen.dart';
import 'features/medical_records/presentation/screens/home_screen.dart';
import 'features/medical_records/presentation/screens/mis_recetas_screen.dart';
import 'features/medical_records/presentation/screens/patient_profile_screen.dart';
import 'features/medical_records/presentation/session/prescription_session_coordinator.dart';
import 'features/treatments/data/services/dose_operation_recovery_service.dart';
import 'features/treatments/presentation/providers/treatment_provider.dart';
import 'features/treatments/presentation/screens/avisos_inbox_screen.dart';
import 'features/treatments/presentation/screens/cronograma_screen.dart';
import 'features/treatments/presentation/screens/treatment_detail_screen.dart';
import 'features/treatments/presentation/screens/treatments_list_screen.dart';
import 'features/treatments/presentation/session/treatment_session_coordinator.dart';
import 'features/treatments/presentation/session/android_push_session_coordinator.dart';

import 'features/appointments/presentation/screens/mis_citas_screen.dart';
import 'features/cola_virtual/presentation/providers/cola_provider.dart';
import 'features/cola_virtual/presentation/screens/cola_operativa_screen.dart';
import 'features/cola_virtual/presentation/screens/mi_turno_screen.dart';
import 'features/teleconsulta/presentation/providers/teleconsulta_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebasePushReady = false;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Firebase.initializeApp();
      firebasePushReady = true;
    } catch (_) {
      // La atención clínica y la bandeja siguen disponibles sin push.
    }
  }

  // Set status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(TelemedicinaApp(firebasePushReady: firebasePushReady));
}

class TelemedicinaApp extends StatelessWidget {
  final bool firebasePushReady;

  const TelemedicinaApp({super.key, this.firebasePushReady = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => DoctorController()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => TeleconsultaProvider()),
        ChangeNotifierProvider(create: (_) => ColaProvider()),
        ChangeNotifierProvider(create: (_) => FichaProvider()),
        ChangeNotifierProvider(create: (_) => ClinicalDocumentsProvider()),
        // CU16: el provider emite `sessionExpired` una sola vez por ciclo ante 401.
        // El coordinador reutiliza AuthController.logout (limpieza segura) y
        // redirige a /login sin navegar desde Domain/Data.
        // Sincronización explícita del ciclo de autenticación (sin JWT):
        // solo false -> true re-arma el evento 401; un éxito nunca lo limpia.
        ChangeNotifierProxyProvider<AuthController, PrescriptionProvider>(
          create: (_) => PrescriptionProvider(),
          update: (_, auth, prescription) {
            final provider = prescription ?? PrescriptionProvider();
            provider.onSessionExpired = () => handlePrescriptionSessionExpired(
              authController: auth,
              navigatorKey: prescriptionNavigatorKey,
            );
            provider.syncAuthSession(isAuthenticated: auth.isAuthenticated);
            return provider;
          },
        ),
        // CU17: Gestión y Monitoreo de Tratamientos Médicos.
        // Sincroniza la sesión con AuthController y maneja 401 de forma desacoplada.
        ChangeNotifierProxyProvider<AuthController, TreatmentProvider>(
          create: (_) => TreatmentProvider(
            recoveryService: DoseOperationRecoveryService(),
          ),
          update: (_, auth, treatment) {
            final provider =
                treatment ??
                TreatmentProvider(
                  recoveryService: DoseOperationRecoveryService(),
                );
            provider.onSessionExpired = () => handlePrescriptionSessionExpired(
              authController: auth,
              navigatorKey: prescriptionNavigatorKey,
            );
            provider.syncAuthSession(
              isAuthenticated: auth.isAuthenticated,
              userId: auth.currentUser?.idUsuario,
              clinicId: auth.currentUser?.idClinica,
            );
            return provider;
          },
        ),
        // Coordinador de ciclo de vida de sesión y reconciliación de tomas CU17
        ChangeNotifierProxyProvider2<
          AuthController,
          TreatmentProvider,
          TreatmentSessionCoordinator
        >(
          lazy: false,
          create: (context) {
            final treatment = Provider.of<TreatmentProvider>(
              context,
              listen: false,
            );
            final auth = Provider.of<AuthController>(context, listen: false);
            final recovery = treatment.recoveryService;
            return TreatmentSessionCoordinator(
              recoveryService: recovery,
              treatmentProvider: treatment,
              authController: auth,
            );
          },
          update: (_, auth, treatment, coordinator) {
            final recovery = treatment.recoveryService;
            final coord =
                coordinator ??
                TreatmentSessionCoordinator(
                  recoveryService: recovery,
                  treatmentProvider: treatment,
                  authController: auth,
                );
            coord.attachTreatmentProvider(treatment);
            coord.onSessionStateChanged(
              userId: auth.currentUser?.idUsuario,
              clinicId: auth.currentUser?.idClinica,
            );
            return coord;
          },
        ),
        ProxyProvider<AuthController, AndroidPushSessionCoordinator>(
          lazy: false,
          update: (_, auth, coordinator) {
            final push =
                coordinator ??
                AndroidPushSessionCoordinator(
                  tokenSource: firebasePushReady
                      ? FirebaseAndroidPushTokenSource()
                      : null,
                );
            auth.onBeforeLogout = push.beforeLogout;
            push.syncSession(
              isPatient:
                  auth.isPatient &&
                  (auth.currentUser?.notificacionesPush ?? false),
              isProfileVerified: auth.isProfileVerified,
              userId: auth.currentUser?.idUsuario,
              clinicId: auth.currentUser?.idClinica,
            );
            return push;
          },
          dispose: (_, coordinator) => coordinator.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'Hospital San Juan de Dios - Telemedicina',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: prescriptionNavigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
          '/home': (context) => const HomeScreen(),
          '/patient-profile': (context) =>
              const PatientOnlyRoute(child: PatientProfileScreen()),
          '/doctors': (context) => const DoctorCatalogScreen(),
          '/appointments': (context) => const AppointmentsScreen(),
          '/citas': (context) => const MisCitasScreen(),
          '/mis-citas': (context) => const MisCitasScreen(),
          '/mi-cola': (context) => const MiTurnoScreen(),
          '/cola': (context) => const ColaOperativaScreen(),
          '/fichas': (context) => const FichasScreen(),
          '/fichas/nueva': (context) => const BookFichaScreen(),
          '/documentos': (context) =>
              const PatientOnlyRoute(child: DocumentsListScreen()),
          '/mis-documentos': (context) =>
              const PatientOnlyRoute(child: DocumentsListScreen()),
          '/recetas': (context) =>
              const PatientOnlyRoute(child: MisRecetasScreen()),
          // Rutas CU17 protegidas por PatientOnlyRoute
          '/tratamientos': (context) =>
              const PatientOnlyRoute(child: TreatmentsListScreen()),
          '/tratamientos/detalle': (context) =>
              const PatientOnlyRoute(child: TreatmentDetailScreen()),
          '/tratamientos/cronograma': (context) =>
              const PatientOnlyRoute(child: CronogramaScreen()),
          '/tratamientos/avisos': (context) =>
              const PatientOnlyRoute(child: AvisosInboxScreen()),
          '/communications': (context) => const CommunicationsScreen(),
          '/analytics': (context) => const ReportsScreen(),
          '/ai-assistant': (context) => const AiAssistantScreen(),
        },
      ),
    );
  }
}
