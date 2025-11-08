import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../theme/modern_theme.dart';
import '../../utils/animations.dart';
// import '../../utils/debug_helpers.dart'; // DISABLED FOR SIMPLE AUTH
import '../../widgets/modern_button.dart';
import '../../widgets/modern_text_field.dart';
import 'register_screen.dart';

/// 🔐 Modern Login Screen
/// Beautiful, secure authentication with smooth animations
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.fastOutSlowIn,
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    debugPrint('🔐 Login button pressed!');
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔐 Starting login process...');
      debugPrint('📧 Email: ${_emailController.text.trim()}');
      debugPrint('🔒 Password length: ${_passwordController.text.length}');
      
      final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
      debugPrint('✅ Got auth provider: ${authProvider.runtimeType}');
      
      final success = await authProvider.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      debugPrint('🔐 Login result: $success');
      
      if (!success) {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Login failed. Please try again.';
        });
        debugPrint('❌ Login failed: ${authProvider.errorMessage}');
      } else {
        debugPrint('✅ Login successful!');
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      setState(() {
        _errorMessage = 'Login failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      AppAnimations.createRoute(
        page: const RegisterScreen(),
        type: PageTransitionType.slideFromRight,
      ),
    );
  }

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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ModernTheme.spacing24),
            child: Column(
              children: [
                const SizedBox(height: ModernTheme.spacing40),
                
                // Header section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildHeader(),
                ),
                
                const SizedBox(height: ModernTheme.spacing48),
                
                // Form section
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildForm(),
                  ),
                ),
                
                const SizedBox(height: ModernTheme.spacing32),
                
                // Login button
                AppAnimations.staggeredListItem(
                  index: 0,
                  child: _buildLoginButton(),
                ),
                
                const SizedBox(height: ModernTheme.spacing24),
                
                // Divider
                AppAnimations.staggeredListItem(
                  index: 1,
                  child: _buildDivider(),
                ),
                
                const SizedBox(height: ModernTheme.spacing24),
                
                // Social login buttons
                AppAnimations.staggeredListItem(
                  index: 2,
                  child: _buildSocialButtons(),
                ),
                
                const SizedBox(height: ModernTheme.spacing32),
                
                // Register link
                AppAnimations.staggeredListItem(
                  index: 3,
                  child: _buildRegisterLink(),
                ),
                
                // Debug helper in development mode
                if (kDebugMode) ...[
                  const SizedBox(height: ModernTheme.spacing24),
                  AppAnimations.staggeredListItem(
                    index: 4,
                    child: _buildDebugHelper(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ModernTheme.primaryBlue, ModernTheme.primaryPurple],
            ),
            borderRadius: BorderRadius.circular(ModernTheme.radiusXL),
            boxShadow: [
              BoxShadow(
                color: ModernTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.storefront_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: ModernTheme.spacing20),
        
        // Welcome text
        Text(
          'Welcome Back!',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: ModernTheme.primaryTextColor,
          ),
        ),
        
        const SizedBox(height: ModernTheme.spacing8),
        
        Text(
          'Sign in to continue to MarketISM',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: ModernTheme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email field
          ModernTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          
          const SizedBox(height: ModernTheme.spacing20),
          
          // Password field
          ModernTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: ModernTheme.hintTextColor,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: ModernTheme.spacing16),
          
          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement forgot password
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: ModernTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: ModernTheme.spacing16),
            Container(
              padding: const EdgeInsets.all(ModernTheme.spacing12),
              decoration: BoxDecoration(
                color: ModernTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                border: Border.all(
                  color: ModernTheme.errorRed.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: ModernTheme.errorRed,
                    size: 20,
                  ),
                  const SizedBox(width: ModernTheme.spacing8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: ModernTheme.errorRed,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return ModernButton(
      text: 'Sign In',
      onPressed: _isLoading ? null : _handleLogin,
      isLoading: _isLoading,
      width: double.infinity,
      gradient: LinearGradient(
        colors: [ModernTheme.primaryBlue, ModernTheme.primaryPurple],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: ModernTheme.borderColor,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ModernTheme.spacing16),
          child: Text(
            'or continue with',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ModernTheme.hintTextColor,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: ModernTheme.borderColor,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            icon: Icons.g_mobiledata,
            label: 'Google',
            onPressed: () {
              // TODO: Implement Google sign in
            },
          ),
        ),
        const SizedBox(width: ModernTheme.spacing16),
        Expanded(
          child: _buildSocialButton(
            icon: Icons.facebook,
            label: 'Facebook',
            onPressed: () {
              // TODO: Implement Facebook sign in
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: ModernTheme.spacing16),
        side: BorderSide(color: ModernTheme.borderColor),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ModernTheme.secondaryTextColor,
          ),
        ),
        TextButton(
          onPressed: _navigateToRegister,
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: ModernTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugHelper() {
    return Container(
      padding: const EdgeInsets.all(ModernTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ModernTheme.radiusM),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: ModernTheme.spacing8),
              Text(
                'Debug Mode - Test Credentials',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: ModernTheme.spacing12),
          Text(
            'Test Email: test@example.com\nPassword: password123',
            style: TextStyle(
              color: ModernTheme.secondaryTextColor,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: ModernTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _emailController.text = 'test@example.com';
                    _passwordController.text = 'password123';
                  },
                  child: const Text('Fill Form'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(width: ModernTheme.spacing8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    // Use real authentication with test credentials
                    _emailController.text = 'test@example.com';
                    _passwordController.text = 'password123';
                    await _handleLogin();
                  },
                  child: const Text('Mock Login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: BorderSide(color: Colors.orange),
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}