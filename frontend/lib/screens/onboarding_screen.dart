import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../theme/premium_theme.dart';
import '../widgets/aesthetic_background.dart';

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

  // Primary photo (optional)
  File? _selectedPhoto;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Pick DOB with Light Theme
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
              primary: PremiumTheme.darkEspresso,
              onPrimary: Colors.white,
              surface: Colors.white,
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
          photos: _selectedPhoto != null ? [_selectedPhoto!] : null,
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
      backgroundColor: Colors.transparent,
      body: AestheticBackground(
        verticalText: 'WELCOME',
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: PremiumTheme.goldBorder.withOpacity(0.8)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x144A3728),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CREATE PROFILE',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: PremiumTheme.textSilver,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Personal Details',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: PremiumTheme.textWhite,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, color: PremiumTheme.textSilver, size: 20),
                            onPressed: () => ref.read(authProvider.notifier).logout(),
                            tooltip: 'Logout',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Photo Avatar Picker
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickPhoto,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFFAF6F0),
                                      border: Border.all(color: PremiumTheme.goldBorder, width: 2),
                                    ),
                                    child: ClipOval(
                                      child: _selectedPhoto != null
                                          ? Image.file(_selectedPhoto!, fit: BoxFit.cover)
                                          : Image.asset(
                                              'assets/sreenath.jpg',
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => const Icon(
                                                Icons.person_rounded,
                                                size: 50,
                                                color: PremiumTheme.darkEspresso,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: PremiumTheme.darkEspresso,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedPhoto == null ? 'Tap to change photo (Optional)' : 'Photo Selected',
                              style: GoogleFonts.inter(color: PremiumTheme.textSilver, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      _buildTextField('Full Name', _nameController, Icons.person_outline_rounded, 'e.g. Sreenath Reddy'),
                      const SizedBox(height: 18),

                      _buildTextField('Current City / Place', _cityController, Icons.location_on_outlined, 'e.g. Hyderabad'),
                      const SizedBox(height: 18),

                      // Date of Birth
                      Text(
                        'Date of Birth',
                        style: GoogleFonts.inter(fontSize: 13, color: PremiumTheme.textWhite, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: () => _selectDob(context),
                        style: GoogleFonts.inter(color: PremiumTheme.textWhite, fontSize: 14),
                        decoration: _buildInputDecoration('Select Date of Birth', Icons.calendar_today_outlined),
                      ),
                      const SizedBox(height: 20),

                      // Gender
                      Text(
                        'I Am A',
                        style: GoogleFonts.inter(fontSize: 13, color: PremiumTheme.textWhite, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildChoiceButton('Man', 'MAN', _selectedGender == 'MAN', (val) => setState(() => _selectedGender = val))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildChoiceButton('Woman', 'WOMAN', _selectedGender == 'WOMAN', (val) => setState(() => _selectedGender = val))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Looking For
                      Text(
                        'Looking For',
                        style: GoogleFonts.inter(fontSize: 13, color: PremiumTheme.textWhite, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildChoiceButton('Women', 'WOMAN', _selectedInterestedIn == 'WOMAN', (val) => setState(() => _selectedInterestedIn = val))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildChoiceButton('Men', 'MAN', _selectedInterestedIn == 'MAN', (val) => setState(() => _selectedInterestedIn = val))),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submitOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PremiumTheme.darkEspresso,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  'Complete Profile',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: PremiumTheme.textWhite, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(color: PremiumTheme.textWhite, fontSize: 14),
          decoration: _buildInputDecoration(hint, icon),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: PremiumTheme.textSilver, size: 18),
      filled: true,
      fillColor: const Color(0xFFFAF6F0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PremiumTheme.goldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PremiumTheme.darkEspresso, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Widget _buildChoiceButton(String label, String value, bool isSelected, Function(String) onTap) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? PremiumTheme.darkEspresso : const Color(0xFFFAF6F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? PremiumTheme.darkEspresso : PremiumTheme.goldBorder,
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : PremiumTheme.textSilver,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
