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
  int _currentStep = 0;
  final int _totalSteps = 5;

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _dobController = TextEditingController();
  
  // Step 2 Astrology
  final _tobController = TextEditingController();
  final _pobController = TextEditingController();

  // Step 3 Cultural & Professional
  final _subCasteController = TextEditingController();
  final _gothramController = TextEditingController();
  final _rasiController = TextEditingController();
  final _starController = TextEditingController();
  final _educationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _familyController = TextEditingController();

  DateTime? _selectedDob;
  String _selectedGender = 'MAN';
  String _selectedInterestedIn = 'WOMAN';

  // Step 4 Photos List
  final List<File> _selectedPhotos = [];
  final ImagePicker _imagePicker = ImagePicker();

  // Step 5 Face verification
  File? _selfieImage;
  bool _isScanning = false;
  bool _faceVerifiedLocal = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _dobController.dispose();
    _tobController.dispose();
    _pobController.dispose();
    _subCasteController.dispose();
    _gothramController.dispose();
    _rasiController.dispose();
    _starController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    _familyController.dispose();
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
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: PremiumTheme.goldAccent,
              onPrimary: PremiumTheme.primaryBgBlack,
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
        _dobController.text = DateFormat('yyyy-MM-DD').format(picked);
      });
    }
  }

  // Pick Time of birth
  Future<void> _selectTob(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: PremiumTheme.goldAccent,
              onPrimary: PremiumTheme.primaryBgBlack,
              surface: PremiumTheme.surfaceCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tobController.text = picked.format(context);
      });
    }
  }

  // Add onboarding photo
  Future<void> _pickPhoto() async {
    if (_selectedPhotos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload a maximum of 5 photos.')),
      );
      return;
    }

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (image != null) {
      setState(() {
        _selectedPhotos.add(File(image.path));
      });
    }
  }

  // Trigger selfie scan (Step 5)
  Future<void> _triggerSelfieScan() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (image == null) return;

    setState(() {
      _selfieImage = File(image.path);
      _isScanning = true;
    });

    // Mock progress delay for scanning animation
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final success = await ref.read(authProvider.notifier).verifyFace(_selfieImage!);
      setState(() {
        _isScanning = false;
        _faceVerifiedLocal = success;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face matched successfully with primary profile photo!'),
            backgroundColor: PremiumTheme.activeBlue,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Advance steps
  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty ||
          _cityController.text.trim().isEmpty ||
          _selectedDob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all details in Bio Step.')),
        );
        return;
      }
    }

    if (_currentStep == 3) {
      if (_selectedPhotos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload at least 1 primary profile photo.')),
        );
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _submitOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _submitOnboarding() {
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
          tob: _tobController.text.trim(),
          pob: _pobController.text.trim(),
          subCaste: _subCasteController.text.trim(),
          gothram: _gothramController.text.trim(),
          rasi: _rasiController.text.trim(),
          star: _starController.text.trim(),
          education: _educationController.text.trim(),
          occupation: _occupationController.text.trim(),
          familyDetails: {
            'family_status': _familyController.text.trim(),
          },
          photos: _selectedPhotos,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: PremiumTheme.primaryBgBlack,
      appBar: AppBar(
        title: Text(
          'ONBOARDING',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, color: PremiumTheme.textWhite),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: PremiumTheme.crimsonRed),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          )
        ],
      ),
      body: Column(
        children: [
          // Step progress indicator bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: List.generate(_totalSteps, (index) {
                final isDone = index < _currentStep;
                final isCurrent = index == _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? PremiumTheme.goldAccent
                          : isCurrent
                              ? PremiumTheme.crimsonRed
                              : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Main Step View Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildActiveStepView(),
            ),
          ),

          // Navigation buttons bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PremiumTheme.surfaceCard,
              border: Border(top: BorderSide(color: Colors.grey.shade900)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                if (_currentStep > 0)
                  TextButton.icon(
                    onPressed: isLoading ? null : _prevStep,
                    icon: const Icon(Icons.arrow_back, color: PremiumTheme.textSilver),
                    label: Text(
                      'Back',
                      style: GoogleFonts.inter(color: PremiumTheme.textSilver, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  const SizedBox(),

                // Next / Finish Button
                SizedBox(
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: PremiumTheme.goldGradient,
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                      ),
                      child: Text(
                        _currentStep == _totalSteps - 1 ? 'Complete Setup' : 'Continue',
                        style: GoogleFonts.outfit(
                          color: PremiumTheme.primaryBgBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStepView() {
    switch (_currentStep) {
      case 0:
        return _buildBioStep();
      case 1:
        return _buildAstrologyStep();
      case 2:
        return _buildCulturalStep();
      case 3:
        return _buildPhotosStep();
      case 4:
        return _buildVerificationStep();
      default:
        return const SizedBox();
    }
  }

  // Step 1: Bio details
  Widget _buildBioStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Bio Details', 'Tell us about your core traits'),
        const SizedBox(height: 24),
        _buildTextField('Full Name', _nameController, Icons.person_outline_rounded),
        const SizedBox(height: 18),
        _buildTextField('Current City', _cityController, Icons.location_city_outlined),
        const SizedBox(height: 18),
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
          style: const TextStyle(color: Colors.white),
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
      ],
    );
  }

  // Step 2: Astrology
  Widget _buildAstrologyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Astrology Details', 'Vedic birth parameters for matchmaking score calculations'),
        const SizedBox(height: 24),
        Text(
          'Time of Birth (TOB)',
          style: GoogleFonts.inter(fontSize: 14, color: PremiumTheme.textSilver, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tobController,
          readOnly: true,
          onTap: () => _selectTob(context),
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Select Time of Birth', Icons.access_time_rounded),
        ),
        const SizedBox(height: 20),
        _buildTextField('Place of Birth (POB)', _pobController, Icons.map_outlined),
        const SizedBox(height: 12),
        Text(
          '*These coordinates help compute precise circular compatibility points matching out of 36.',
          style: GoogleFonts.inter(fontSize: 12, color: PremiumTheme.textMuted, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  // Step 3: Cultural & Family
  Widget _buildCulturalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Cultural & Family', 'Traditional parameters details'),
        const SizedBox(height: 24),
        _buildTextField('Sub-caste / Caste', _subCasteController, Icons.palette_outlined),
        const SizedBox(height: 18),
        _buildTextField('Gothram', _gothramController, Icons.auto_stories_outlined),
        const SizedBox(height: 18),
        _buildTextField('Rasi (Moon Sign)', _rasiController, Icons.nights_stay_outlined),
        const SizedBox(height: 18),
        _buildTextField('Star / Nakshatram', _starController, Icons.star_border_rounded),
        const SizedBox(height: 18),
        _buildTextField('Education Degree', _educationController, Icons.school_outlined),
        const SizedBox(height: 18),
        _buildTextField('Occupation', _occupationController, Icons.work_outline),
        const SizedBox(height: 18),
        _buildTextField('Family Status details (e.g. Rich, Middle-class)', _familyController, Icons.group_outlined),
      ],
    );
  }

  // Step 4: Photos
  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Profile Photos', 'Upload up to 5 pictures to showcase yourself. Primary image is first.'),
        const SizedBox(height: 24),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            final hasPhoto = index < _selectedPhotos.length;
            if (hasPhoto) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_selectedPhotos[index], fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPhotos.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: PremiumTheme.crimsonRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        alignment: Alignment.center,
                        child: Text(
                          'PRIMARY',
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: PremiumTheme.goldAccent),
                        ),
                      ),
                    ),
                ],
              );
            } else {
              return GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  decoration: BoxDecoration(
                    color: PremiumTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800, style: BorderStyle.solid),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: PremiumTheme.goldAccent, size: 28),
                      SizedBox(height: 6),
                      Text('Add Photo', style: TextStyle(color: PremiumTheme.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  // Step 5: Face verification camera UI
  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildSectionHeader('Face Verification', 'Verify identity to display gold verification trust badge'),
        const SizedBox(height: 32),

        // Scanning UI Box
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PremiumTheme.surfaceCard,
              border: Border.all(
                color: _faceVerifiedLocal 
                    ? PremiumTheme.goldAccent 
                    : _isScanning 
                        ? PremiumTheme.crimsonRed 
                        : Colors.grey.shade800,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  if (_selfieImage != null)
                    Image.file(_selfieImage!, fit: BoxFit.cover)
                  else
                    const Icon(Icons.face_unlock_rounded, size: 100, color: PremiumTheme.goldAccent),

                  // Scanning line animation simulation
                  if (_isScanning)
                    const ScanningLineAnimation(),

                  if (_faceVerifiedLocal)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: Icon(Icons.verified_rounded, size: 72, color: PremiumTheme.goldAccent),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        if (_faceVerifiedLocal)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: PremiumTheme.goldAccent, size: 20),
              const SizedBox(width: 6),
              Text(
                'Trust Profile Verified!',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: PremiumTheme.goldAccent, fontSize: 16),
              ),
            ],
          )
        else if (_isScanning)
          Text(
            'Analyzing facial keypoints via AI...',
            style: GoogleFonts.inter(color: PremiumTheme.textWhite, fontStyle: FontStyle.italic),
          )
        else
          Text(
            'Place your face in the circular box and capture.',
            style: GoogleFonts.inter(color: PremiumTheme.textSilver),
          ),
        const SizedBox(height: 36),

        if (!_faceVerifiedLocal)
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _triggerSelfieScan,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(_selfieImage == null ? 'Take Live Selfie' : 'Retake Selfie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumTheme.crimsonRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ),
      ],
    );
  }

  // Utilities
  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cormorantGaramond(fontSize: 30, fontWeight: FontWeight.bold, color: PremiumTheme.textWhite),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 14, color: PremiumTheme.textMuted),
        ),
      ],
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
          style: const TextStyle(color: Colors.white),
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
      fillColor: PremiumTheme.surfaceCard,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade900),
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
          color: isSelected ? PremiumTheme.goldAccent.withOpacity(0.1) : PremiumTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? PremiumTheme.goldAccent : Colors.grey.shade900,
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

// Scanning line animation simulation widget
class ScanningLineAnimation extends StatefulWidget {
  const ScanningLineAnimation({super.key});

  @override
  State<ScanningLineAnimation> createState() => _ScanningLineAnimationState();
}

class _ScanningLineAnimationState extends State<ScanningLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: _animController.value * 240,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: const BoxDecoration(
                  color: PremiumTheme.goldAccent,
                  boxShadow: [
                    BoxShadow(
                      color: PremiumTheme.goldAccent,
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
