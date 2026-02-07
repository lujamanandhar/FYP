import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/form_validator.dart';
import '../services/error_handler.dart';
import '../widgets/nutrilift_header.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  
  String? _selectedGender;
  String? _selectedAgeGroup;
  String? _selectedFitnessLevel;
  File? _profileImage;
  
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.red),
                  ),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.red),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_profileImage != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    title: const Text('Remove Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _profileImage = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'Edit Profile',
      showBackButton: true,
      showDrawer: false,
      body: Container(
        color: Colors.grey[50],
        child: Form(
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

                // Profile Photo Section
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              border: Border.all(
                                color: Colors.red,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.file(
                                      _profileImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to change photo',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

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