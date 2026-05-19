import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app/routes.dart';
import '../providers/app_state.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});
  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  static const _teal  = Color(0xFF075E54);
  static const _green = Color(0xFF25D366);

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();

  bool _isLoading   = false;
  bool _isSignUp    = false;
  bool _obscure     = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    setState(() { _isLoading = true; _error = null; });

    try {
      if (_isSignUp) {
        final res = await Supabase.instance.client.auth.signUp(
          email: email, 
          password: password,
          data: {'full_name': _nameCtrl.text.trim()},
        );
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email, 
          password: password
        );
      }
      if (mounted) {
        Provider.of<AppState>(context, listen: false).setAuthenticated(true);
        // Honor a post-auth destination passed by role select (e.g. workerProfile).
        // Otherwise: new sign-ups → language select, returning users → home.
        final routeArg = ModalRoute.of(context)?.settings.arguments as String?;
        final dest = routeArg ?? (_isSignUp ? AppRoutes.languageSelect : AppRoutes.home);
        Navigator.pushReplacementNamed(context, dest);
      }
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() { _isLoading = false; _error = 'Something went wrong. Try again.'; });
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':       return 'No account found with this email.';
      case 'wrong-password':       return 'Incorrect password. Try again.';
      case 'invalid-credential':   return 'Invalid email or password.';
      case 'email-already-in-use': return 'Email already registered. Sign in instead.';
      case 'weak-password':        return 'Password must be at least 6 characters.';
      case 'invalid-email':        return 'Please enter a valid email address.';
      case 'too-many-requests':    return 'Too many attempts. Please wait and try again.';
      default:                     return 'Error: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // Logo
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Image.asset(
                    'assets/images/karigar_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.handyman, color: _teal, size: 40),
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              Text(
                _isSignUp ? 'Create Account' : 'Welcome Back',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF111B21),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 6),

              Text(
                _isSignUp
                    ? 'Sign up to book trusted professionals'
                    : 'Sign in to continue to Karigar AI',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF8696A0)),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 36),

              // Name field (sign up only)
              if (_isSignUp) ...[
                _Field(
                  controller: _nameCtrl,
                  hint: 'Full Name',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                const SizedBox(height: 14),
              ],

              // Email
              _Field(
                controller: _emailCtrl,
                hint: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 14),

              // Password
              _Field(
                controller: _passwordCtrl,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF8696A0), size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ).animate().fadeIn(delay: 480.ms).slideY(begin: 0.1),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
                  ]),
                ),
              ],

              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isSignUp ? 'Create Account' : 'Sign In',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ).animate().fadeIn(delay: 560.ms),

              const SizedBox(height: 20),

              // Toggle sign in / sign up
              Center(
                child: GestureDetector(
                  onTap: () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
                        style: const TextStyle(color: Color(0xFF8696A0), fontSize: 14),
                      ),
                      TextSpan(
                        text: _isSignUp ? 'Sign In' : 'Sign Up',
                        style: const TextStyle(
                          color: _green, fontSize: 14, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ]),
                  ),
                ),
              ).animate().fadeIn(delay: 650.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.suffix,
  });

  static const _fieldBg   = Color(0xFFF7F8FA);
  static const _fieldText = Color(0xFF111B21);
  static const _hintColor = Color(0xFF8696A0);
  static const _iconColor = Color(0xFF075E54);
  static const _border    = Color(0xFFE4E6EB);

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Isolate this field from the app's dark inputDecorationTheme entirely
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: _fieldBg,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          cursorColor: _iconColor,
          style: const TextStyle(fontSize: 15, color: _fieldText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _hintColor, fontSize: 15),
            prefixIcon: Icon(icon, color: _iconColor, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: _fieldBg,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _iconColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }
}
