import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/widgets/inactivity_warning_listener.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/medical_records/presentation/providers/clinical_documents_provider.dart';
import 'features/medical_records/presentation/screens/documents_list_screen.dart';

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
        // CU12: las pantallas de documentos clinicos leen este provider, por lo
        // que debe registrarse o `context.read` falla en tiempo de ejecucion.
        ChangeNotifierProvider(create: (_) => ClinicalDocumentsProvider()),
      ],
      child: MaterialApp(
        title: 'Hospital San Juan de Dios - Telemedicina',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        // CU23: el aviso de inactividad se monta aqui, sobre el Navigator, para
        // que aparezca este donde este el usuario. Se suscribe a la cuenta
        // atras del AuthController, asi que no necesita saber que ruta es la
        // actual ni interferir con la navegacion.
        builder: (context, child) => InactivityWarningListener(
          child: child ?? const SizedBox.shrink(),
        ),
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
          '/home': (context) => const HomeScreen(),
          // CU12 - solo accesible con sesion iniciada.
          '/mis-documentos': (context) =>
              const _AuthenticatedGate(child: DocumentsListScreen()),
        },
      ),
    );
  }
}

/// Redirige a `/login` si no hay sesion activa (CU12, CU23).
///
/// La app usa el enrutador clasico de MaterialApp (`routes:`), que no admite
/// guards; este wrapper centraliza la comprobacion en lugar de duplicarla en
/// cada pantalla. Espera a que AuthController termine de restaurar la sesion
/// para no expulsar al usuario antes de tiempo.
class _AuthenticatedGate extends StatefulWidget {
  final Widget child;

  const _AuthenticatedGate({required this.child});

  @override
  State<_AuthenticatedGate> createState() => _AuthenticatedGateState();
}

class _AuthenticatedGateState extends State<_AuthenticatedGate> {
  @override
  void initState() {
    super.initState();
    // `SplashScreen` restaura la sesion al arrancar, pero en Flutter Web se
    // puede entrar directo por URL (o recargar) sin pasar por `/`. En ese caso
    // `isCheckingAuth` seguiria en true y el gate se quedaria cargando, asi que
    // se fuerza la comprobacion al montar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      if (auth.isCheckingAuth) {
        auth.checkAuthStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (auth.isCheckingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isAuthenticated) {
      // `replace` evita que el usuario vuelva a la ruta protegida con el boton
      // atras del navegador.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return widget.child;
  }
}
