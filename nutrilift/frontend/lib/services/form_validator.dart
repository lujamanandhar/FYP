import 'dart:async';
import 'package:flutter/material.dart';

/// Form validation service with real-time validation capabilities
class FormValidator {
  static final FormValidator _instance = FormValidator._internal();
  factory FormValidator() => _instance;
  FormValidator._internal();

  // Email validation regex
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  
  // Password validation regex (at least 8 chars, 1 uppercase, 1 lowercase, 1 number)
  static final RegExp _strongPasswordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$');

  /// Validate email address
  ValidationResult validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return ValidationResult(isValid: false, error: 'Email is required');
    }
    
    if (!_emailRegex.hasMatch(email)) {
      return ValidationResult(isValid: false, error: 'Please enter a valid email address');
    }
    
    return ValidationResult(isValid: true);
  }

  /// Validate password with strength requirements
  ValidationResult validatePassword(String? password, {bool requireStrong = false}) {
    if (password == null || password.isEmpty) {
      return ValidationResult(isValid: false, error: 'Password is required');
    }
    
    if (password.length < 8) {
      return ValidationResult(isValid: false, error: 'Password must be at least 8 characters long');
    }
    
    if (requireStrong && !_strongPasswordRegex.hasMatch(password)) {
      return ValidationResult(
        isValid: false, 
        error: 'Password must contain uppercase, lowercase, and number'
      );
    }
    
    return ValidationResult(isValid: true);
  }

  /// Validate password confirmation
  ValidationResult validatePasswordConfirmation(String? password, String? confirmation) {
    if (confirmation == null || confirmation.isEmpty) {
      return ValidationResult(isValid: false, error: 'Please confirm your password');
    }
    
    if (password != confirmation) {
      return ValidationResult(isValid: false, error: 'Passwords do not match');
    }
    
    return ValidationResult(isValid: true);
  }

  /// Validate name
  ValidationResult validateName(String? name) {
    if (name == null || name.isEmpty) {
      return ValidationResult(isValid: false, error: 'Name is required');
    }
    
    if (name.trim().length < 2) {
      return ValidationResult(isValid: false, error: 'Name must be at least 2 characters long');
    }
    
    if (name.trim().length > 50) {
      return ValidationResult(isValid: false, error: 'Name must be less than 50 characters');
    }
    
    return ValidationResult(isValid: true);
  }

  /// Validate height
  ValidationResult validateHeight(String? height) {
    if (height == null || height.isEmpty) {
      return ValidationResult(isValid: false, error: 'Height is required');
    }
    
    final heightValue = double.tryParse(height);
    if (heightValue == null) {
      return ValidationResult(isValid: false, error: 'Please enter a valid height');
    }
    
    if (heightValue <= 0 || heightValue > 300) {
      return ValidationResult(isValid: false, error: 'Height must be between 1 and 300 cm');
    }
    
    return ValidationResult(isValid: true);
  }

  /// Validate weight
  ValidationResult validateWeight(String? weight) {
    if (weight == null || weight.isEmpty) {
      return ValidationResult(isValid: false, error: 'Weight is required');
    }
    
    final weightValue = double.tryParse(weight);
    if (weightValue == null) {
      return ValidationResult(isValid: false, error: 'Please enter a valid weight');
    }
    
    if (weightValue <= 0 || weightValue > 500) {
      return ValidationResult(isValid: false, error: 'Weight must be between 1 and 500 kg');
    }
    
    return ValidationResult(isValid: true);
  }

  /// Validate required field
  ValidationResult validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult(isValid: false, error: '$fieldName is required');
    }
    
    return ValidationResult(isValid: true);
  }

  /// Get password strength score (0-4)
  PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength(score: 0, label: 'Too weak', color: const Color(0xFFE53E3E));
    }
    
    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    // Normalize to 0-4 scale
    score = (score * 4 / 6).round().clamp(0, 4);
    
    switch (score) {
      case 0:
      case 1:
        return PasswordStrength(score: score, label: 'Too weak', color: const Color(0xFFE53E3E));
      case 2:
        return PasswordStrength(score: score, label: 'Weak', color: const Color(0xFFFF8C00));
      case 3:
        return PasswordStrength(score: score, label: 'Good', color: const Color(0xFF38A169));
      case 4:
        return PasswordStrength(score: score, label: 'Strong', color: const Color(0xFF2D3748));
      default:
        return PasswordStrength(score: 0, label: 'Too weak', color: const Color(0xFFE53E3E));
    }
  }
}

/// Real-time form field validator
class RealTimeValidator {
  final FormValidator _validator = FormValidator();
  Timer? _debounceTimer;
  final Duration _debounceDuration;
  
  RealTimeValidator({Duration debounceDuration = const Duration(milliseconds: 500)})
      : _debounceDuration = debounceDuration;

  /// Validate field with debouncing
  void validateField(
    String? value,
    ValidationResult Function(String?) validator,
    Function(ValidationResult) onResult,
  ) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      final result = validator(value);
      onResult(result);
    });
  }

  /// Dispose timer
  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// Validation result model
class ValidationResult {
  final bool isValid;
  final String? error;
  final String? warning;

  ValidationResult({
    required this.isValid,
    this.error,
    this.warning,
  });

  static ValidationResult valid() => ValidationResult(isValid: true);
  static ValidationResult invalid(String error) => ValidationResult(isValid: false, error: error);
}

/// Password strength model
class PasswordStrength {
  final int score;
  final String label;
  final Color color;

  PasswordStrength({
    required this.score,
    required this.label,
    required this.color,
  });
}

/// Enhanced text form field with real-time validation
class ValidatedTextFormField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValidationResult Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool enabled;
  final Function(String)? onChanged;
  final bool showValidationIcon;
  final bool realTimeValidation;
  final String? serverError; // Server-side validation error
  final bool showSuccessIcon;

  const ValidatedTextFormField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.showValidationIcon = true,
    this.realTimeValidation = true,
    this.serverError,
    this.showSuccessIcon = true,
  });

  @override
  State<ValidatedTextFormField> createState() => _ValidatedTextFormFieldState();
}

class _ValidatedTextFormFieldState extends State<ValidatedTextFormField> {
  ValidationResult? _validationResult;
  RealTimeValidator? _realTimeValidator;

  @override
  void initState() {
    super.initState();
    if (widget.realTimeValidation) {
      _realTimeValidator = RealTimeValidator();
    }
  }

  @override
  void dispose() {
    _realTimeValidator?.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged?.call(value);
    
    if (widget.realTimeValidation && _realTimeValidator != null) {
      _realTimeValidator!.validateField(
        value,
        widget.validator,
        (result) {
          if (mounted) {
            setState(() {
              _validationResult = result;
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prioritize server error over client-side validation
    final displayError = widget.serverError ?? _validationResult?.error;
    final hasError = widget.serverError != null || (_validationResult?.isValid == false);
    final isValid = widget.serverError == null && _validationResult?.isValid == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.showValidationIcon ? _buildValidationIcon() : widget.suffixIcon,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? Colors.red : (isValid ? Colors.green : Colors.grey),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? Colors.red : (isValid ? Colors.green : Colors.grey.shade300),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? Colors.red : (isValid ? Colors.green : Colors.blue),
                width: 2,
              ),
            ),
            errorText: displayError,
            errorStyle: const TextStyle(fontSize: 12),
          ),
          validator: (value) {
            // Server errors take precedence
            if (widget.serverError != null) {
              return widget.serverError;
            }
            final result = widget.validator(value);
            return result.isValid ? null : result.error;
          },
        ),
        if (_validationResult?.warning != null) ...[
          const SizedBox(height: 4),
          Text(
            _validationResult!.warning!,
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 12,
            ),
          ),
        ],
        if (isValid && widget.showSuccessIcon) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              Text(
                'Valid',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget? _buildValidationIcon() {
    if (widget.serverError != null) {
      return const Icon(Icons.error, color: Colors.red);
    }
    
    if (_validationResult == null) return widget.suffixIcon;
    
    if (_validationResult!.isValid) {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else {
      return const Icon(Icons.error, color: Colors.red);
    }
  }
}

/// Password field with strength indicator
class PasswordFieldWithStrength extends StatefulWidget {
  final String? label;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final bool enabled;
  final bool showStrengthIndicator;

  const PasswordFieldWithStrength({
    super.key,
    this.label = 'Password',
    this.controller,
    this.onChanged,
    this.enabled = true,
    this.showStrengthIndicator = true,
  });

  @override
  State<PasswordFieldWithStrength> createState() => _PasswordFieldWithStrengthState();
}

class _PasswordFieldWithStrengthState extends State<PasswordFieldWithStrength> {
  bool _obscureText = true;
  PasswordStrength? _strength;
  final FormValidator _validator = FormValidator();

  void _onChanged(String value) {
    widget.onChanged?.call(value);
    
    if (widget.showStrengthIndicator) {
      setState(() {
        _strength = _validator.getPasswordStrength(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValidatedTextFormField(
          label: widget.label,
          controller: widget.controller,
          validator: (value) => _validator.validatePassword(value, requireStrong: false),
          obscureText: _obscureText,
          enabled: widget.enabled,
          onChanged: _onChanged,
          prefixIcon: const Icon(Icons.lock_outlined),
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
          showValidationIcon: false,
        ),
        if (widget.showStrengthIndicator && _strength != null) ...[
          const SizedBox(height: 8),
          _buildStrengthIndicator(),
        ],
      ],
    );
  }

  Widget _buildStrengthIndicator() {
    if (_strength == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _strength!.score / 4,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(_strength!.color),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _strength!.label,
              style: TextStyle(
                color: _strength!.color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Server validation error display widget
class ServerValidationErrorDisplay extends StatelessWidget {
  final Map<String, dynamic>? errors;
  final String? generalError;
  final VoidCallback? onDismiss;

  const ServerValidationErrorDisplay({
    super.key,
    this.errors,
    this.generalError,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (errors == null && generalError == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  generalError ?? 'Please fix the following errors:',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red[700], size: 18),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (errors != null) ...[
            const SizedBox(height: 8),
            ...errors!.entries.map((entry) {
              final fieldName = _formatFieldName(entry.key);
              final errorMessages = entry.value is List 
                  ? (entry.value as List).cast<String>()
                  : [entry.value.toString()];
              
              return Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errorMessages.map((error) => Text(
                    '• $fieldName: $error',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 13,
                    ),
                  )).toList(),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  String _formatFieldName(String fieldName) {
    // Convert snake_case to Title Case
    return fieldName
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

/// Success message display widget
class SuccessMessageDisplay extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback? onDismiss;

  const SuccessMessageDisplay({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 4),
    this.onDismiss,
  });

  @override
  State<SuccessMessageDisplay> createState() => _SuccessMessageDisplayState();
}

class _SuccessMessageDisplayState extends State<SuccessMessageDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.green[700], size: 18),
                onPressed: _dismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading overlay widget
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingMessage;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (loadingMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        loadingMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}