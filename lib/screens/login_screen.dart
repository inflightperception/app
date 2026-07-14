import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ---- controllers ----
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _fullNameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // ---- stato ----
  bool _isLoading = false;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // ---- animation ----
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ---- colori (stessa palette di HomeScreen) ----
  static const _bgColor = Color(0xFFF2F4F7);
  static const _cardColor = Colors.white;
  static const _accentColor = Color(0xFF3B6FD4);
  static const _textPrimary = Color(0xFF1A1D23);
  static const _textSecondary = Color(0xFF6B7280);
  static const _darkBg = Color(0xFF0F1117);

  // ---- regex e-mail ----
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _fullNameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ---- validatori ----
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email required';
    if (!_emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validateFullName(String? v) {
    if (!_isRegisterMode) return null;
    if (v == null || v.trim().isEmpty) return 'Full name required';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ---- auth handler ----
  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final session = _isRegisterMode
          ? await AuthService.registerAndLogin(
              email: email,
              fullName: _fullNameController.text.trim(),
              password: password,
            )
          : await AuthService.login(email: email, password: password);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainShell(currentPilot: session.pilot),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Authentication failed. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- forgot password ----
  void _onForgotPassword() {
    // TODO: implementare reset password
    // Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset not yet implemented.')),
    );
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _errorMessage = null;
    });
  }

  // ---- build ----
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;

    return Scaffold(
      backgroundColor: _bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isLandscape ? _buildLandscape() : _buildPortrait(),
      ),
    );
  }

  // ---- PORTRAIT ----
  Widget _buildPortrait() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLogoRow(),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: _buildFormSection(),
            ),
          ],
        ),
      ),
    );
  }

  // ---- LANDSCAPE ----
  Widget _buildLandscape() {
    return Row(
      children: [
        Expanded(child: _buildBrandPanel()),
        Expanded(
          child: Container(
            color: _cardColor,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 32,
                ),
                child: _buildFormSection(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- pannello brand (landscape sinistra) ----
  Widget _buildBrandPanel() {
    return Container(
      color: _darkBg,
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // logo
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A84F0), Color(0xFF2A5CC0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flight_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Overflow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Fuel Intelligence Platform',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          // product positioning
          const Text(
            'Fuel decisions with sharper context.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Overflow helps pilots and operations teams analyze OFP data, '
            'weather conditions, TAF/TREND reports and SIGWX charts to '
            'support more consistent extra fuel decisions.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const Spacer(),
          Text(
            '© 2026 Inflight Perception',
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ---- logo row (portrait) ----
  Widget _buildLogoRow() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A84F0), Color(0xFF2A5CC0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.flight_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Overflow',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  // ---- form section (condivisa portrait/landscape) ----
  Widget _buildFormSection() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isRegisterMode ? 'Create pilot account' : 'Welcome back',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isRegisterMode
                ? 'Register for local OFP analysis access'
                : 'Sign in to your operations account',
            style: TextStyle(fontSize: 14, color: _textSecondary),
          ),
          const SizedBox(height: 28),

          // email
          _buildFieldLabel('Email'),
          const SizedBox(height: 6),
          _buildEmailField(),
          const SizedBox(height: 18),

          if (_isRegisterMode) ...[
            _buildFieldLabel('Full name'),
            const SizedBox(height: 6),
            _buildFullNameField(),
            const SizedBox(height: 18),
          ],

          // password
          _buildFieldLabel('Password'),
          const SizedBox(height: 6),
          _buildPasswordField(),
          const SizedBox(height: 8),

          // forgot
          if (!_isRegisterMode)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _onForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 13,
                    color: _accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // error banner
          if (_errorMessage != null) ...[
            _buildErrorBanner(_errorMessage!),
            const SizedBox(height: 16),
          ],

          // sign-in / register
          _buildSignInButton(),
          const SizedBox(height: 20),

          _buildDivider(),
          const SizedBox(height: 20),

          _buildModeToggleButton(),
          const SizedBox(height: 20),

          Center(
            child: Text(
              _isRegisterMode
                  ? 'Already have an account? Sign in instead'
                  : 'New user? Create an account now',
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _textPrimary,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enabled: !_isLoading,
      validator: _validateEmail,
      onFieldSubmitted: (_) => FocusScope.of(
        context,
      ).requestFocus(_isRegisterMode ? _fullNameFocus : _passwordFocus),
      decoration: _inputDecoration(
        hint: 'you@airline.com',
        prefixIcon: Icons.alternate_email_rounded,
      ),
    );
  }

  Widget _buildFullNameField() {
    return TextFormField(
      controller: _fullNameController,
      focusNode: _fullNameFocus,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      enabled: !_isLoading,
      validator: _validateFullName,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(_passwordFocus),
      decoration: _inputDecoration(
        hint: 'Test Pilot',
        prefixIcon: Icons.person_outline_rounded,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      enabled: !_isLoading,
      validator: _validatePassword,
      onFieldSubmitted: (_) => _signIn(),
      decoration: _inputDecoration(
        hint: '••••••••',
        prefixIcon: Icons.lock_outline_rounded,
        suffix: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: _textSecondary,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _textSecondary.withOpacity(0.5),
        fontSize: 14,
      ),
      prefixIcon: Icon(prefixIcon, size: 18, color: _textSecondary),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accentColor, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
      ),
      errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accentColor.withOpacity(0.5),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _isRegisterMode ? 'Create account' : 'Sign in',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: _textSecondary.withOpacity(0.2), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 13,
              color: _textSecondary.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: Divider(color: _textSecondary.withOpacity(0.2), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildModeToggleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _toggleMode,
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isRegisterMode ? 'Back to sign in' : 'Create pilot account',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
