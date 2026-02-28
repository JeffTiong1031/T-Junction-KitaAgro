import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../features/auth/auth_service.dart';
import '../../main_layout.dart';
import '../../core/services/app_localizations.dart';

class CompleteProfileScreen extends StatefulWidget {
  final UserModel user;
  const CompleteProfileScreen({super.key, required this.user});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _townController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedRole = 'Farmer';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if any
    if (widget.user.age > 0) _ageController.text = widget.user.age.toString();
    if (widget.user.town != 'Not Specified')
      _townController.text = widget.user.town;
    if (widget.user.state != 'Not Specified')
      _stateController.text = widget.user.state;
    if (widget.user.country != 'Not Specified')
      _countryController.text = widget.user.country;
  }

  Future<void> _saveProfile() async {
    final loc = AppLocalizations.of(context);

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserModel updatedUser = UserModel(
          uid: widget.user.uid,
          email: widget.user.email,
          username: widget.user.username,
          fullName: widget.user.fullName,
          age: int.tryParse(_ageController.text) ?? 0,
          gender: _selectedGender,
          town: _townController.text.trim(),
          state: _stateController.text.trim(),
          country: _countryController.text.trim(),
          role: _selectedRole,
          createdAt: widget.user.createdAt,
        );

        await AuthService().updateUserProfile(updatedUser);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${loc.errorUpdatingProfile}: $e")),
          );
        }
      } finally {
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.completeProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(loc.completeProfileMessage),
              const SizedBox(height: 20),

              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: loc.age),
                validator: (value) {
                  if (value == null || value.isEmpty) return loc.pleaseEnterAge;
                  if (int.tryParse(value) == null)
                    return loc.pleaseEnterValidNumber;
                  return null;
                },
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                items: [loc.male, loc.female, loc.other].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedGender = newValue!;
                  });
                },
                decoration: InputDecoration(labelText: loc.gender),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _townController,
                decoration: InputDecoration(labelText: loc.town),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return loc.pleaseEnterTown;
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _stateController,
                decoration: InputDecoration(labelText: loc.state),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return loc.pleaseEnterState;
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _countryController,
                decoration: InputDecoration(labelText: loc.country),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return loc.pleaseEnterCountry;
                  return null;
                },
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                items: [loc.farmer, loc.buyer, loc.investor, loc.researcher]
                    .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    })
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
                decoration: InputDecoration(labelText: loc.role),
              ),
              const SizedBox(height: 20),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      child: Text(loc.saveAndContinue),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
