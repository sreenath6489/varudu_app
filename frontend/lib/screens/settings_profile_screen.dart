import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../theme/premium_theme.dart';
import '../widgets/aesthetic_background.dart';
import '../widgets/glassmorphic_container.dart';



class SettingsProfileScreen extends ConsumerStatefulWidget {
  const SettingsProfileScreen({super.key});

  @override
  ConsumerState<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends ConsumerState<SettingsProfileScreen> {
  final _aadhaarController = TextEditingController();

  // Profile fields controllers
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _dobController;
  late TextEditingController _tobController;
  late TextEditingController _pobController;
  late TextEditingController _subCasteController;
  late TextEditingController _gothramController;
  late TextEditingController _rasiController;
  late TextEditingController _starController;
  late TextEditingController _educationController;
  late TextEditingController _occupationController;
  late TextEditingController _familyController;
  late TextEditingController _serverUrlController;

  DateTime? _selectedDob;
  String _selectedGender = 'MAN';
  String _selectedInterestedIn = 'WOMAN';

  // Photo & Face scanning states
  final ImagePicker _imagePicker = ImagePicker();
  File? _selfieImage;
  bool _isScanning = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _cityController = TextEditingController();
    _dobController = TextEditingController();
    _tobController = TextEditingController();
    _pobController = TextEditingController();
    _subCasteController = TextEditingController();
    _gothramController = TextEditingController();
    _rasiController = TextEditingController();
    _starController = TextEditingController();
    _educationController = TextEditingController();
    _occupationController = TextEditingController();
    _familyController = TextEditingController();
    _serverUrlController = TextEditingController(text: ApiService.baseUrl);
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
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
    _serverUrlController.dispose();
    super.dispose();
  }

  void _initFieldsIfNeeded(Map<String, dynamic> profile) {
    if (_initialized) return;
    final family = profile['family_details'] ?? {};
    _nameController.text = profile['name'] ?? '';
    _cityController.text = profile['city'] ?? '';
    _dobController.text = profile['dob'] ?? '';
    _tobController.text = profile['tob'] ?? '';
    _pobController.text = profile['pob'] ?? '';
    _subCasteController.text = family['subCaste'] ?? '';
    _gothramController.text = family['gothram'] ?? '';
    _rasiController.text = family['rasi'] ?? '';
    _starController.text = family['star'] ?? '';
    _educationController.text = family['education'] ?? '';
    _occupationController.text = family['occupation'] ?? '';
    _familyController.text = family['family_status'] ?? '';

    _selectedGender = profile['gender'] == 'WOMAN' ? 'WOMAN' : 'MAN';
    _selectedInterestedIn = profile['interestedIn'] == 'WOMAN' ? 'WOMAN' : 'MAN';

    if (profile['dob'] != null) {
      try {
        _selectedDob = DateFormat('yyyy-MM-dd').parse(profile['dob']);
      } catch (e) {}
    }
    _initialized = true;
  }

  // DOB selector
  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
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
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // TOB selector
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

  // Take selfie scan for face verification
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

    // Mock scanning progress animation delay
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final success = await ref.read(authProvider.notifier).verifyFace(_selfieImage!);
      setState(() {
        _isScanning = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face Verification Successful!'),
            backgroundColor: PremiumTheme.goldAccent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: PremiumTheme.crimsonRed,
        ),
      );
    }
  }

  // Pick extra gallery photo
  Future<void> _addGalleryPhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (image != null) {
      try {
        final currentProfile = ref.read(authProvider).profile ?? {};
        final dobStr = currentProfile['dob'];
        final dob = dobStr != null ? DateFormat('yyyy-MM-dd').parse(dobStr) : DateTime.now();
        final age = currentProfile['age'] ?? 25;

        // Perform submitOnboarding with the new photo file appended to standard params
        await ref.read(authProvider.notifier).submitOnboarding(
              name: _nameController.text.trim(),
              city: _cityController.text.trim(),
              age: age,
              dob: dob,
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
              photos: [File(image.path)], // Send this file to append or save
            );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery photo uploaded successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: PremiumTheme.crimsonRed),
        );
      }
    }
  }

  // Save changes callback
  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Name is required.');
      return;
    }
    if (_cityController.text.trim().isEmpty) {
      _showSnackBar('City is required.');
      return;
    }
    if (_selectedDob == null) {
      _showSnackBar('DOB is required.');
      return;
    }

    final today = DateTime.now();
    int age = today.year - _selectedDob!.year;
    if (today.month < _selectedDob!.month ||
        (today.month == _selectedDob!.month && today.day < _selectedDob!.day)) {
      age--;
    }

    try {
      await ref.read(authProvider.notifier).submitOnboarding(
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
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile details saved successfully!'),
          backgroundColor: PremiumTheme.goldAccent,
        ),
      );
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: PremiumTheme.crimsonRed),
    );
  }

  void _triggerAadhaarVerify() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumTheme.surfaceCard,
        title: Text('Aadhaar Verification', style: GoogleFonts.cormorantGaramond(color: PremiumTheme.goldAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter your 12-digit Aadhaar number for mock OTP check:', style: GoogleFonts.inter(color: PremiumTheme.textSilver)),
            const SizedBox(height: 12),
            TextField(
              controller: _aadhaarController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: PremiumTheme.textWhite, fontSize: 14),
              decoration: const InputDecoration(
                hintText: '0000 0000 0000',
                hintStyle: TextStyle(color: PremiumTheme.textMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: PremiumTheme.goldBorder)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: PremiumTheme.goldAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: PremiumTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final num = _aadhaarController.text.trim();
              if (num.length >= 12) {
                final success = await ref.read(authProvider.notifier).verifyAadhaar(num);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aadhaar Verified Successfully!'), backgroundColor: PremiumTheme.activeBlue),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: PremiumTheme.goldAccent, foregroundColor: Colors.white),
            child: const Text('Verify'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile ?? {};
    final photos = profile['photos'] as List<dynamic>? ?? [];
    final hasPhoto = photos.isNotEmpty;
    
    final isAadhaarVerified = profile['aadhaar_verified'] == true;
    final isFaceVerified = profile['face_verified'] == true;
    final isPhoneVisible = profile['phone_visible'] == true;

    _initFieldsIfNeeded(profile);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AestheticBackground(
        verticalText: 'ACCOUNT',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // User profile header card
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: PremiumTheme.goldAccent, width: 2),
                      ),
                      child: ClipOval(
                        child: hasPhoto
                            ? CachedNetworkImage(
                                imageUrl: photos[0].startsWith('http') ? photos[0] : '${ApiService.baseUrl}${photos[0]}',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, err) => Container(color: Colors.grey.shade900),
                              )
                            : Container(color: Colors.grey.shade900),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          profile['name'] ?? 'User Name',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: PremiumTheme.textWhite,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isFaceVerified)
                          const Icon(Icons.verified, color: PremiumTheme.goldAccent, size: 20),
                      ],
                    ),
                    Text(
                      profile['email'] ?? '',
                      style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Trust & Verifications Card
              Text(
                'Trust & Verifications',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 12),
              GlassmorphicContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                child: Column(
                  children: [
                    // Aadhaar Verification status
                    ListTile(
                      leading: Icon(
                        isAadhaarVerified ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                        color: isAadhaarVerified ? PremiumTheme.activeBlue : PremiumTheme.textMuted,
                      ),
                      title: Text('Aadhaar Verified Badge', style: GoogleFonts.inter(color: PremiumTheme.textWhite)),
                      subtitle: Text(
                        isAadhaarVerified ? 'Identity verified successfully' : 'Provide Aadhaar to gain trust score',
                        style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 12),
                      ),
                      trailing: isAadhaarVerified
                          ? const Icon(Icons.verified, color: PremiumTheme.activeBlue)
                          : TextButton(
                              onPressed: _triggerAadhaarVerify,
                              child: Text('Verify Now', style: GoogleFonts.inter(color: PremiumTheme.goldAccent)),
                            ),
                    ),
                    const Divider(color: PremiumTheme.goldBorder),

                    // Selfie Face Verification status
                    ListTile(
                      leading: Icon(
                        isFaceVerified ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                        color: isFaceVerified ? PremiumTheme.activeBlue : PremiumTheme.textMuted,
                      ),
                      title: Text('Face Verification Selfie', style: GoogleFonts.inter(color: PremiumTheme.textWhite)),
                      subtitle: Text(
                        isFaceVerified ? 'Facial features verified via Rekognition' : 'Take live selfie comparison check',
                        style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 12),
                      ),
                      trailing: isFaceVerified
                          ? const Icon(Icons.verified, color: PremiumTheme.goldAccent)
                          : TextButton(
                              onPressed: _isScanning ? null : _triggerSelfieScan,
                              child: Text(
                                _isScanning ? 'Scanning...' : 'Verify Selfie',
                                style: GoogleFonts.inter(color: PremiumTheme.goldAccent, fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),

                    if (_isScanning) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: PremiumTheme.crimsonRed, width: 2),
                          ),
                          child: const ClipOval(
                            child: ScanningLineAnimation(),
                          ),
                        ),
                      )
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Visibility settings controls
              Text(
                'Visibility Configurations',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 12),
              GlassmorphicContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                borderRadius: 16,
                child: SwitchListTile(
                  value: isPhoneVisible,
                  onChanged: (val) {
                    ref.read(authProvider.notifier).togglePhoneVisibility(val);
                  },
                  activeColor: PremiumTheme.goldAccent,
                  inactiveThumbColor: PremiumTheme.textMuted,
                  inactiveTrackColor: Colors.black38,
                  title: Text('Phone Visibility', style: GoogleFonts.inter(color: PremiumTheme.textWhite)),
                  subtitle: Text(
                    'Allow mutual matches to request or view your phone number (requires Rose unlock)',
                    style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Profile Gallery
              Text(
                'Your Profile Gallery',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 12),
              GlassmorphicContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: photos.length + (photos.length < 5 ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < photos.length) {
                          final photoUrl = photos[index].startsWith('http') ? photos[index] : '${ApiService.baseUrl}${photos[index]}';
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: PremiumTheme.surfaceCard),
                            ),
                          );
                        } else {
                          return GestureDetector(
                            onTap: _addGalleryPhoto,
                            child: Container(
                              decoration: BoxDecoration(
                                color: PremiumTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: PremiumTheme.goldBorder, style: BorderStyle.solid),
                              ),
                              child: const Icon(Icons.add_a_photo_outlined, color: PremiumTheme.goldAccent),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Edit details form section
              Text(
                'Edit Profile Details',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 12),
              GlassmorphicContainer(
                padding: const EdgeInsets.all(18),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Full Name', _nameController, Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField('City', _cityController, Icons.location_city),
                    const SizedBox(height: 16),
                    
                    // DOB Field
                    Text('Date of Birth', style: GoogleFonts.inter(fontSize: 13, color: PremiumTheme.textSilver)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: () => _selectDob(context),
                      style: GoogleFonts.inter(color: PremiumTheme.textWhite, fontSize: 14),
                      decoration: _buildInputDecoration('Date of Birth', Icons.calendar_today),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Astrological Coordinates',
                      style: GoogleFonts.cormorantGaramond(fontSize: 18, fontWeight: FontWeight.bold, color: PremiumTheme.goldAccent),
                    ),
                    const SizedBox(height: 12),
                    
                    // TOB Field
                    Text('Time of Birth (TOB)', style: GoogleFonts.inter(fontSize: 13, color: PremiumTheme.textSilver)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _tobController,
                      readOnly: true,
                      onTap: () => _selectTob(context),
                      style: GoogleFonts.inter(color: PremiumTheme.textWhite, fontSize: 14),
                      decoration: _buildInputDecoration('Time of Birth', Icons.access_time),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Place of Birth (POB)', _pobController, Icons.map_outlined),
                    const SizedBox(height: 16),
                    _buildTextField('Gothram', _gothramController, Icons.auto_stories),
                    const SizedBox(height: 16),
                    _buildTextField('Rasi (Moon Sign)', _rasiController, Icons.nights_stay),
                    const SizedBox(height: 16),
                    _buildTextField('Star / Nakshatram', _starController, Icons.star_border),
                    
                    const SizedBox(height: 24),

                    Text(
                      'Cultural & Family Details',
                      style: GoogleFonts.cormorantGaramond(fontSize: 18, fontWeight: FontWeight.bold, color: PremiumTheme.goldAccent),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField('Sub-Caste / Caste', _subCasteController, Icons.palette),
                    const SizedBox(height: 16),
                    _buildTextField('Education Degree', _educationController, Icons.school),
                    const SizedBox(height: 16),
                    _buildTextField('Occupation', _occupationController, Icons.work),
                    const SizedBox(height: 16),
                    _buildTextField('Family Status (e.g. Middle class, Rich)', _familyController, Icons.group),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Save Profile Details Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: PremiumTheme.goldGradient,
                  ),
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: Text(
                      'Save Profile Details',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(color: PremiumTheme.goldBorder, height: 48),

              Text(
                'DEVELOPER API SETTINGS',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.goldAccent,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              GlassmorphicContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                border: Border.all(color: PremiumTheme.goldAccent.withOpacity(0.15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Server URL',
                      style: GoogleFonts.inter(fontSize: 13, color: PremiumTheme.textSilver),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _serverUrlController,
                      style: GoogleFonts.inter(color: PremiumTheme.textWhite, fontSize: 14),
                      decoration: _buildInputDecoration('https://example.ngrok-free.dev', Icons.link_rounded),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newUrl = _serverUrlController.text.trim();
                          if (newUrl.isNotEmpty) {
                            await ApiService.saveBaseUrl(newUrl);
                            final authState = ref.read(authProvider);
                            if (authState.profile != null) {
                              ref.read(chatProvider.notifier).disconnectSocket();
                              ref.read(chatProvider.notifier).initSocket(authState.profile!['id']);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('API Server URL updated & Socket reconnected! 🚀'),
                                backgroundColor: PremiumTheme.goldAccent,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumTheme.goldAccent,
                          foregroundColor: PremiumTheme.primaryBgBlack,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Save & Reconnect Socket',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    foregroundColor: PremiumTheme.crimsonRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
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
          style: GoogleFonts.inter(fontSize: 13, color: PremiumTheme.textSilver),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(color: PremiumTheme.textWhite, fontSize: 14),
          decoration: _buildInputDecoration(label, icon),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: PremiumTheme.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: PremiumTheme.goldAccent, size: 18),
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
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
              top: _animController.value * 140,
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

