import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/theme.dart';
import 'app/routes.dart';
import 'providers/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Connect to Supabase ───────────────────────────────────────
  await Supabase.initialize(
    url: 'https://nndetsjvsqjegkawyoox.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5uZGV0c2p2c3FqZWdrYXd5b294Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxNDM4NTQsImV4cCI6MjA5NDcxOTg1NH0.RyY-KPftB6iPfuMBQKbp41C7Czca5os71BKvZx_IrEc',
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const KarigarApp(),
    ),
  );
}

class KarigarApp extends StatelessWidget {
  const KarigarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<AppState, ThemeMode>((s) => s.themeMode);
    final lang = context.select<AppState, String>((s) => s.language);
    final isUrdu = lang == 'urdu';
    return MaterialApp(
      title: 'Karigar AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Locale flips RTL when Urdu is picked. Roman-Urdu + English stay LTR.
      locale: isUrdu ? const Locale('ur', 'PK') : const Locale('en', 'US'),
      supportedLocales: const [Locale('en', 'US'), Locale('ur', 'PK')],
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      builder: (context, child) => Directionality(
        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
    );
  }
}
