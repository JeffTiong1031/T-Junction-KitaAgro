// Needed for User? handling
import 'package:flutter/material.dart';
import '../../features/auth/auth_service.dart';
import '../../main_layout.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/complete_profile_screen.dart';
import '../../core/models/user_model.dart';
import '../../features/auth/welcome_screen.dart';
import '../../core/services/language_service.dart';
import '../../core/services/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _login() async {
    final loc = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = loc.emailAndPasswordRequired;
        _isLoading = false;
      });
      return;
    }

    String? error = await _authService.signIn(email: email, password: password);

    setState(() {
      _isLoading = false;
    });

    if (error == null) {
      // Success
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } else {
      setState(() {
        _errorMessage = error;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    final loc = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Returns UserModel, allowing us to check if profile is complete
    UserModel? userModel = await _authService.signInWithGoogle();

    setState(() {
      _isLoading = false;
    });

    if (userModel != null) {
      if (mounted) {
        if (userModel.town == 'Not Specified' || userModel.age == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(user: userModel),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
          );
        }
      }
    } else {
      setState(() {
        _errorMessage = loc.googleSignInFailed;
      });
    }
  }

  // Alias for tutorial consistency
  Future<void> _handleGoogleLogin() async {
    await _loginWithGoogle();
  }

  void _showLanguageSelector() {
    final languageService = LanguageServiceProvider.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.language, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context).selectLanguage,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Language options
                ...AppLanguage.values.map((lang) {
                  final isSelected = languageService.currentLanguage == lang;
                  return ListTile(
                    leading: Text(
                      lang.flag,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      lang.displayName,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.green : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      languageService.setLanguage(lang);
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final languageService = LanguageServiceProvider.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              );
            }
          },
        ),
        actions: [
          // 🌐 Language Selector Button
          TextButton.icon(
            onPressed: _showLanguageSelector,
            icon: const Icon(Icons.language, color: Colors.green, size: 22),
            label: Text(
              languageService.currentLanguage.flag,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.agriculture, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              Text(
                loc.loginTitle,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 50),

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: loc.email,
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: loc.password,
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 30),

              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _login,
                          icon: const Icon(Icons.login),
                          label: Text(loc.login),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        OutlinedButton.icon(
                          onPressed: _loginWithGoogle,
                          icon: Image.asset(
                            'assets/images/google_logo.png',
                            height: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.public),
                          ),
                          label: Text(loc.signInWithGoogle),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(loc.dontHaveAccount),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(loc.register),
                            ),
                          ],
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
