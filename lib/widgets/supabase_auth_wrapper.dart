import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main_screen_supabase.dart';
import '../theme/modern_theme.dart';

class SupabaseAuthWrapper extends StatelessWidget {
  const SupabaseAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseAuthProvider>(
      builder: (context, authProvider, child) {
        debugPrint('🔄 SupabaseAuthWrapper building with user: ${authProvider.user?.id}');
        
        if (authProvider.isLoading) {
          return const _LoadingScreen();
        }
        
        if (authProvider.user == null) {
          return const LoginScreen();
        }
        
        return const MainScreenSupabase();
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ModernTheme.primaryBlue.withOpacity(0.1),
              ModernTheme.primaryPurple.withOpacity(0.05),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ModernTheme.primaryBlue, ModernTheme.primaryPurple],
                  ),
                  borderRadius: BorderRadius.circular(ModernTheme.radiusXXL),
                  boxShadow: [
                    BoxShadow(
                      color: ModernTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // App name
              Text(
                'MarketISM',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.primaryTextColor,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Campus Marketplace',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ModernTheme.secondaryTextColor,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Loading indicator
              CircularProgressIndicator(
                color: ModernTheme.primaryBlue,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ModernTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}