import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../theme/premium_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _dobController = TextEditingController();

  DateTime? _selectedDob;
  String _selectedGender = 'MAN';
  String _selectedInterestedIn = 'WOMAN';

  // Primary photo
  File? _selectedPhoto;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Pick DOB
  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: PremiumTheme.goldAccent,
              onPrimary: Colors.white,
              surface: PremiumTheme.surfaceCard,
              onSurface: PremiumTheme.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Pick primary photo
  Future<void> _pickPhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (image != null) {
      setState(() {
        _selectedPhoto = File(image.path);
      });
    }
  }

  void _submitOnboarding() {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your full name.');
      return;
    }
    if (_cityController.text.trim().isEmpty) {
      _showSnackBar('Please enter your city.');
      return;
    }
    if (_selectedDob == null) {
      _showSnackBar('Please select your Date of Birth.');
      return;
    }
    if (_selectedPhoto == null) {
      _showSnackBar('Please upload a profile photo.');
      return;
    }

    final today = DateTime.now();
    int age = today.year - _selectedDob!.year;
    if (today.month < _selectedDob!.month ||
        (today.month == _selectedDob!.month && today.day < _selectedDob!.day)) {
      age--;
    }

    ref.read(authProvider.notifier).submitOnboarding(
          name: _nameController.text.trim(),
          city: _cityController.text.trim(),
          age: age,
          dob: _selectedDob!,
          gender: _selectedGender,
          interestedIn: _selectedInterestedIn,
          photos: [_selectedPhoto!],
        );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: PremiumTheme.crimsonRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: PremiumTheme.primaryBgLight,
      appBar: AppBar(
        title: Text(
          'PROFILE SETUP',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, color: PremiumTheme.textWhite),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: PremiumTheme.crimsonRed),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Picker Card
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PremiumTheme.surfaceCard,
                          border: Border.all(
                            color: _selectedPhoto != null ? PremiumTheme.goldAccent : PremiumTheme.goldBorder,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _selectedPhoto != null
                              ? Image.file(_selectedPhoto!, fit: BoxFit.cover)
                              : const Icon(Icons.add_a_photo_outlined, size: 36, color: PremiumTheme.goldAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedPhoto == null ? 'Upload Profile Photo' : 'Change Photo',
                      style: GoogleFonts.inter(color: PremiumTheme.textSilver, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField('Full Name', _nameController, Icons.person_outline_rounded),
              const SizedBox(height: 20),

              _buildTextField('Current City / Place', _cityController, Icons.location_city_outlined),
              const SizedBox(height: 20),

              // DOB selector field
              Text(
                'Date of Birth',
                style: GoogleFonts.inter(fontSize: 14, color: PremiumTheme.textSilver, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: () => _selectDob(context),
                style: GoogleFonts.inter(color: PremiumTheme.textWhite),
                decoration: _buildInputDecoration('Select Date of Birth', Icons.calendar_today_outlined),
              ),
              const SizedBox(height: 24),

              // Gender Choice
              Text(
                'Gender',
                style: GoogleFonts.inter(fontSize: 14, color: PremiumTheme.textSilver, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildChoiceButton('Man', 'MAN', _selectedGender == 'MAN', (val) => setState(() => _selectedGender = val))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildChoiceButton('Woman', 'WOMAN', _selectedGender == 'WOMAN', (val) => setState(() => _selectedGender = val))),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Looking For',
                style: GoogleFonts.inter(fontSize: 14, color: PremiumTheme.textSilver, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildChoiceButton('Men', 'MAN', _selectedInterestedIn == 'MAN', (val) => setState(() => _selectedInterestedIn = val))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildChoiceButton('Women', 'WOMAN', _selectedInterestedIn == 'WOMAN', (val) => setState(() => _selectedInterestedIn = val))),
                ],
              ),

              const SizedBox(height: 48),

              // Complete Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27),
                    gradient: PremiumTheme.goldGradient,
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submitOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Complete Setup',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: PremiumTheme.textSilver, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(color: PremiumTheme.textWhite),
          decoration: _buildInputDecoration(label, icon),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: PremiumTheme.textMuted),
      prefixIcon: Icon(icon, color: PremiumTheme.goldAccent),
      filled: true,
      fillColor: PremiumTheme.surfaceElevated,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PremiumTheme.goldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PremiumTheme.goldAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  Widget _buildChoiceButton(String label, String value, bool isSelected, Function(String) onTap) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? PremiumTheme.goldAccent.withOpacity(0.12) : PremiumTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? PremiumTheme.goldAccent : PremiumTheme.goldBorder,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? PremiumTheme.goldAccent : PremiumTheme.textSilver,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
