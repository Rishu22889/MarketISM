import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/supabase_auth_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/supabase_auth_wrapper.dart';
import 'theme/modern_theme.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  runApp(const MarketISMApp());
}

class MarketISMApp extends StatelessWidget {
  const MarketISMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => SupabaseAuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MarketISM',
            debugShowCheckedModeBanner: false,
            theme: ModernTheme.lightTheme,
            darkTheme: ModernTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SupabaseAuthWrapper(),
          );
        },
      ),
    );
  }
}