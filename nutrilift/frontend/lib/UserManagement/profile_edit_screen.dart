import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/form_validator.dart';
import '../services/error_handler.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserProfile userProfile;

  const ProfileEditScreen({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> with ErrorHandlingMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FormValidator _formValidator = FormValidator();
  
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  
  String? _selectedGender;
  String? _selectedAgeGroup;
  String? _selectedFitnessLevel;
  
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _ageGroupOptions = ['Adult', 'Mid-Age Adult', 'Older Adult'];
  final List<String> _fitnessLevelOptions = ['Beginner', 'Intermediate', 'Advance'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.userProfile.name ?? '');
    _heightController = TextEditingController(
      text: widget.userProfile.height?.toStringAsFixed(1) ?? '',
    );
    _weightController = TextEditingController(
      text: widget.userProfile.weight?.toStringAsFixed(1) ?? '',
    );
    
    _selectedGender = widget.userProfile.gender;
    _selectedAgeGroup = widget.userProfile.ageGroup;
    _selectedFitnessLevel = widget.userProfile.fitnessLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await executeWithErrorHandling(
      () async {
        final request = ProfileUpdateRequest(
          name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
          gender: _selectedGender,
          ageGroup: _selectedAgeGroup,
          height: _heightController.text.trim().isEmpty ? null : double.tryParse(_heightController.text.trim()),
          weight: _weightController.text.trim().isEmpty ? null : double.tryParse(_weightController.text.trim()),
          fitnessLevel: _selectedFitnessLevel,
        );

        return await _authService.updateProfile(request);
      },
      successMessage: 'Profile updated successfully!',
      showLoading: false, // We handle loading state manually
    );

    setState(() {
      _isLoading = false;
    });

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Name Field
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 12),
              ValidatedTextFormField(
                controller: _nameController,
                label: 'Full Name',
                validator: _formValidator.validateName,
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: Colors.red, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Gender Selection
              _buildDropdownField(
                label: 'Gender',
                icon: Icons.wc,
                value: _selectedGender,
                items: _genderOptions,
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 16),

              // Age Group Selection
              _buildDropdownField(
                label: 'Age Group',
                icon: Icons.cake,
                value: _selectedAgeGroup,
                items: _ageGroupOptions,
                onChanged: (value) => setState(() => _selectedAgeGroup = value),
              ),
              const SizedBox(height: 24),

              // Physical Information
              _buildSectionTitle('Physical Information'),
              const SizedBox(height: 12),
              ValidatedTextFormField(
                controller: _heightController,
                label: 'Height (cm)',
                validator: _formValidator.validateHeight,
                keyboardType: TextInputType.number,
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.height, color: Colors.red, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              ValidatedTextFormField(
                controller: _weightController,
                label: 'Weight (kg)',
                validator: _formValidator.validateWeight,
                keyboardType: TextInputType.number,
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.monitor_weight, color: Colors.red, size: 20),
                ),
              ),
              const SizedBox(height: 24),

              // Fitness Information
              _buildSectionTitle('Fitness Information'),
              const SizedBox(height: 12),
              _buildDropdownField(
                label: 'Fitness Level',
                icon: Icons.fitness_center,
                value: _selectedFitnessLevel,
                items: _fitnessLevelOptions,
                onChanged: (value) => setState(() => _selectedFitnessLevel = value),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D2D2D),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
      ),
    );
  }
}