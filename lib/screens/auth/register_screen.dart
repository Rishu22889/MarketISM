import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../theme/modern_theme.dart';
import '../../utils/animations.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/modern_text_field.dart';

/// 📝 Modern Register Screen
/// Beautiful registration form with modern design and animations
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    debugPrint('🔥🔥🔥 REGISTER BUTTON PRESSED! 🔥🔥🔥');
    print('🔥🔥🔥 REGISTER BUTTON PRESSED! 🔥🔥🔥');
    
    // Show immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Register button pressed! Processing...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (!_acceptTerms) {
      debugPrint('❌ Terms not accepted');
      setState(() {
        _errorMessage = '⚠️ Please accept the Terms of Service and Privacy Policy to continue';
      });
      // Show a snackbar as well for better visibility
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the Terms of Service and Privacy Policy'),
          backgroundColor: ModernTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('📝 Starting registration process...');
      debugPrint('👤 Name: ${_nameController.text.trim()}');
      debugPrint('📧 Email: ${_emailController.text.trim()}');
      debugPrint('🔒 Password length: ${_passwordController.text.length}');
      
      final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
      debugPrint('✅ Got auth provider: ${authProvider.runtimeType}');
      
      final success = await authProvider.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      
      debugPrint('📝 Registration result: $success');
      
      if (!success) {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Registration failed. Please try again.';
        });
        debugPrint('❌ Registration failed: ${authProvider.errorMessage}');
      } else {
        debugPrint('✅ Registration successful!');
      }
      
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateBack() {
    Navigator.of(context).pop();
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
              ModernTheme.primaryPurple.withOpacity(0.1),
              ModernTheme.accentTeal.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ModernTheme.spacing24),
            child: Column(
              children: [
                const SizedBox(height: ModernTheme.spacing20),
                
                // Header section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildHeader(),
                ),
                
                const SizedBox(height: ModernTheme.spacing40),
                
                // Form section
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildForm(),
                  ),
                ),
                
                const SizedBox(height: ModernTheme.spacing24),
                
                // Register button
                AppAnimations.staggeredListItem(
                  index: 0,
                  child: _buildRegisterButton(),
                ),
                
                const SizedBox(height: ModernTheme.spacing24),
                
                // Divider
                AppAnimations.staggeredListItem(
                  index: 1,
                  child: _buildDivider(),
                ),
                
                const SizedBox(height: ModernTheme.spacing24),
                
                // Social register buttons
                AppAnimations.staggeredListItem(
                  index: 2,
                  child: _buildSocialButtons(),
                ),
                
                const SizedBox(height: ModernTheme.spacing32),
                
                // Login link
                AppAnimations.staggeredListItem(
                  index: 3,
                  child: _buildLoginLink(),
                ),
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
        // Back button
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: _navigateBack,
            icon: const Icon(Icons.arrow_back_ios),
            style: IconButton.styleFrom(
              backgroundColor: ModernTheme.surfaceColor.withOpacity(0.8),
              foregroundColor: ModernTheme.primaryTextColor,
            ),
          ),
        ),
        
        const SizedBox(height: ModernTheme.spacing20),
        
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ModernTheme.primaryPurple, ModernTheme.accentTeal],
            ),
            borderRadius: BorderRadius.circular(ModernTheme.radiusXL),
            boxShadow: [
              BoxShadow(
                color: ModernTheme.primaryPurple.withOpacity(0.3),
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
          'Create Account',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: ModernTheme.primaryTextColor,
          ),
        ),
        
        const SizedBox(height: ModernTheme.spacing8),
        
        Text(
          'Join MarketISM and start trading',
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
          // Name field
          ModernTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            keyboardType: TextInputType.name,
            prefixIcon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              if (value.length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: ModernTheme.spacing20),
          
          // Email field
          ModernTextField(
            controller: _emailController,
            label: 'IIT ISM Email',
            hint: 'Enter your @iitism.ac.in email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.school_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your IIT ISM email';
              }
              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@iitism\.ac\.in$').hasMatch(value)) {
                return 'Please use your official IIT ISM email (@iitism.ac.in)';
              }
              return null;
            },
          ),
          
          const SizedBox(height: ModernTheme.spacing20),
          
          // Password field
          ModernTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Create a password',
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
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: ModernTheme.spacing20),
          
          // Confirm Password field
          ModernTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Confirm your password',
            obscureText: _obscureConfirmPassword,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: ModernTheme.hintTextColor,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          
          const SizedBox(height: ModernTheme.spacing20),
          
          // Terms and conditions
          Container(
            padding: const EdgeInsets.all(ModernTheme.spacing12),
            decoration: BoxDecoration(
              color: _acceptTerms 
                ? ModernTheme.primaryBlue.withOpacity(0.05)
                : ModernTheme.errorRed.withOpacity(0.05),
              borderRadius: BorderRadius.circular(ModernTheme.radiusM),
              border: Border.all(
                color: _acceptTerms 
                  ? ModernTheme.primaryBlue.withOpacity(0.2)
                  : ModernTheme.errorRed.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptTerms = value ?? false;
                    });
                  },
                  activeColor: ModernTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _acceptTerms = !_acceptTerms;
                      });
                    },
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ModernTheme.secondaryTextColor,
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: ModernTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: ModernTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

  Widget _buildRegisterButton() {
    return ModernButton(
      text: 'Create Account',
      onPressed: _isLoading ? null : _handleRegister,
      isLoading: _isLoading,
      width: double.infinity,
      gradient: LinearGradient(
        colors: [ModernTheme.primaryPurple, ModernTheme.accentTeal],
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
            'or sign up with',
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
              // TODO: Implement Google sign up
            },
          ),
        ),
        const SizedBox(width: ModernTheme.spacing16),
        Expanded(
          child: _buildSocialButton(
            icon: Icons.facebook,
            label: 'Facebook',
            onPressed: () {
              // TODO: Implement Facebook sign up
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

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ModernTheme.secondaryTextColor,
          ),
        ),
        TextButton(
          onPressed: _navigateBack,
          child: Text(
            'Sign In',
            style: TextStyle(
              color: ModernTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}