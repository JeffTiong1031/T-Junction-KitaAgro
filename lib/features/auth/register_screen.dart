import 'package:flutter/material.dart';
import '../../features/auth/auth_service.dart';
import '../../main_layout.dart';
import '../../core/services/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();

  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isLoading = false;

  // step 1: Account
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // step 2: Personal
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;

  // step 3: Location
  final TextEditingController _townController = TextEditingController();
  final TextEditingController _stateController =
      TextEditingController(); // Or dropdown
  final TextEditingController _countryController = TextEditingController();

  // step 4: Role
  String? _selectedRole;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _townController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Regex for basic email validation
  bool _isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  Future<void> _nextPage() async {
    final loc = AppLocalizations.of(context);

    // Validation logic for each step
    if (_currentStep == 0) {
      String email = _emailController.text.trim();
      String username = _usernameController.text.trim();
      String password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        _showError(loc.pleaseFillAllFields);
        return;
      }
      if (!_isValidEmail(email)) {
        _showError(loc.pleaseEnterValidEmail);
        return;
      }
      if (password.length < 6) {
        _showError(loc.passwordMinLength);
        return;
      }

      // Check username uniqueness
      bool isAvailable = await _authService.isUsernameAvailable(username);
      if (!isAvailable) {
        _showError(loc.usernameTaken);
        return;
      }
    } else if (_currentStep == 1) {
      if (_nameController.text.isEmpty ||
          _ageController.text.isEmpty ||
          _selectedGender == null) {
        _showError(loc.pleaseFillAllFields);
        return;
      }
    } else if (_currentStep == 2) {
      if (_townController.text.isEmpty ||
          _stateController.text.isEmpty ||
          _countryController.text.isEmpty) {
        _showError(loc.pleaseFillAllFields);
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishRegistration();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _finishRegistration() async {
    final loc = AppLocalizations.of(context);

    if (_selectedRole == null) {
      _showError(loc.pleaseSelectRole);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<String> errors = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _usernameController.text.trim(),
      fullName: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      gender: _selectedGender!,
      town: _townController.text.trim(),
      state: _stateController.text.trim(),
      country: _countryController.text.trim(),
      role: _selectedRole!,
    );

    setState(() {
      _isLoading = false;
    });

    if (errors.isEmpty) {
      // Success
      if (mounted) {
        // Navigate to dashboard and remove history
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } else {
      _showError(errors.join("\n"));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _previousPage,
        ),
        title: LinearProgressIndicator(
          value: (_currentStep + 1) / _totalSteps,
          backgroundColor: Colors.grey[200],
          color: Colors.green,
          minHeight: 8,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Prevent swipe
        onPageChanged: (index) {
          setState(() {
            _currentStep = index;
          });
        },
        children: [
          _buildAccountPage(),
          _buildPersonalPage(),
          _buildLocationPage(),
          _buildRolePage(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    _currentStep == _totalSteps - 1 ? loc.finish : loc.next,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStepTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAccountPage() {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(loc.createAccount),
          const SizedBox(height: 30),
          _buildTextField(
            controller: _emailController,
            label: loc.email,
            icon: Icons.email,
            type: TextInputType.emailAddress,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _usernameController,
            label: loc.username,
            icon: Icons.person,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _passwordController,
            label: loc.password,
            icon: Icons.lock,
            obscure: true,
            action: TextInputAction.done,
            onSubmitted: (_) => _nextPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalPage() {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(loc.tellAboutYourself),
          const SizedBox(height: 30),
          _buildTextField(
            controller: _nameController,
            label: loc.fullName,
            icon: Icons.badge,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _ageController,
            label: loc.age,
            icon: Icons.calendar_today,
            type: TextInputType.number,
            action: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          _buildDropdown(
            items: [loc.male, loc.female, loc.preferNotToSay],
            value: _selectedGender,
            onChanged: (val) => setState(() => _selectedGender = val),
            hint: loc.selectGender,
            icon: Icons.people,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(loc.whereAreYou),
          const SizedBox(height: 30),
          _buildTextField(
            controller: _townController,
            label: loc.townCity,
            icon: Icons.location_city,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _stateController,
            label: loc.state,
            icon: Icons.map,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _countryController,
            label: loc.country,
            icon: Icons.flag,
            action: TextInputAction.done,
            onSubmitted: (_) => _nextPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePage() {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(loc.whatDescribesYou),
          const SizedBox(height: 30),
          _buildDropdown(
            items: [
              loc.farmer,
              loc.homeGrower,
              loc.agronomist,
              loc.businessCompany,
            ],
            value: _selectedRole,
            onChanged: (val) => setState(() => _selectedRole = val),
            hint: loc.selectRole,
            icon: Icons.work,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType type = TextInputType.text,
    TextInputAction action = TextInputAction.done,
    Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      textInputAction: action,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown({
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: Text(hint),
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
