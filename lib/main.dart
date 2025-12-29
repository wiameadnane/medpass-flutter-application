import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/constants.dart';
import 'models/medical_file_model.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'firebase_options.dart';

// Imports des écrans
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/billing/billing_screen.dart';
import 'screens/billing/payment_screen.dart';
import 'screens/emergency/emergency_screen.dart';
import 'screens/emergency/emergency_mode_screen.dart';
import 'screens/files/file_viewer_screen.dart';
import 'screens/files/my_files_screen.dart';
import 'screens/files/upload_file_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/personal_card_screen.dart';
import 'screens/home/qr_code_screen.dart';
import 'screens/ocr_scan_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/personal_info_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/settings/settings_screen.dart';

bool get isDemoMode => dotenv.env['DEMO_MODE']?.toLowerCase() == 'true';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Config error: $e');
  }

  String? firebaseError;
  if (!isDemoMode) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e) {
      firebaseError = e.toString();
    }
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MedPassApp(firebaseInitError: firebaseError));
}

class MedPassApp extends StatelessWidget {
  final String? firebaseInitError;
  const MedPassApp({super.key, this.firebaseInitError});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Med-Pass',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.flutterThemeMode,
            home: AuthWrapper(firebaseInitError: firebaseInitError),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/': return _buildPageRoute(const AuthWrapper());
            case '/login': return _buildPageRoute(const LoginScreen());
            case '/signup': return _buildPageRoute(const SignUpScreen());
            case '/home': return _buildPageRoute(const HomeScreen());
            case '/profile': return _buildPageRoute(const ProfileScreen());
            case '/personal-info': return _buildPageRoute(const PersonalInfoScreen());
            case '/edit-profile': return _buildPageRoute(const EditProfileScreen());
            case '/create-profile': return _buildPageRoute(const EditProfileScreen(isCreating: true));
            case '/my-files': return _buildPageRoute(const MyFilesScreen());

            case '/upload-file':
            // Utilise widget.initialFile comme défini dans ton UploadFileScreen
              final file = settings.arguments as PlatformFile;
              return _buildPageRoute(UploadFileScreen(initialFile: file));

            case '/files-list':
            // Correction : On appelle le constructeur sans argument
            // car FileViewerScreen récupère la catégorie via ModalRoute
              return _buildPageRoute(const FileViewerScreen());

            case '/important-files':
              return _buildPageRoute(const FileViewerScreen(showImportantOnly: true));
            case '/qr-code':
              return _buildPageRoute(const QrCodeScreen());
            case '/emergency':
              return _buildPageRoute(const EmergencyScreen());
            case '/emergency-mode':
              return _buildPageRoute(const EmergencyModeScreen());
            case '/personal-card':
              return _buildPageRoute(const PersonalCardScreen());
            case '/billing':
              return _buildPageRoute(const BillingScreen());
            case '/payment':
              return _buildPageRoute(const PaymentScreen());
            case '/settings':
              return _buildPageRoute(const SettingsScreen());
            case '/scan-document':
              return _buildPageRoute(const OCRScanScreen());
            case '/search':
              return _buildPageRoute(const SearchScreen());
            default:
              return _buildPageRoute(const AuthWrapper());
          }
        },
          );
        },
      ),
    );
  }

  static PageRouteBuilder _buildPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: anim.drive(Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut))),
        child: child,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final String? firebaseInitError;
  const AuthWrapper({super.key, this.firebaseInitError});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _init();
  }
  _init() async {
    await context.read<ThemeProvider>().initialize();
    await context.read<UserProvider>().initialize();
    if (mounted) setState(() => _loading = false);
  }
  @override
  Widget build(BuildContext context) {
    if (widget.firebaseInitError != null && !isDemoMode) return Scaffold(body: Center(child: Text(widget.firebaseInitError!)));
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return context.watch<UserProvider>().isLoggedIn ? const HomeScreen() : const OnboardingScreen();
  }
}
