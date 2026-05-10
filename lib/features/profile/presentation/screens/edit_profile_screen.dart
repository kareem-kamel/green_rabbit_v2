import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import 'country_selection_screen.dart';



class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class CountryModel {
  final String code;
  final String name;
  final String flag;
  CountryModel({required this.code, required this.name, required this.flag});
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  late String _selectedCountryName;
  late String _selectedCountryCode;
  late String _selectedCountryFlag;
  late String _avatarUrl;

  final List<CountryModel> _countries = [
    CountryModel(code: 'EG', name: 'Egypt', flag: '🇪🇬'),
    CountryModel(code: 'SA', name: 'Saudi Arabia', flag: '🇸🇦'),
    CountryModel(code: 'AE', name: 'UAE', flag: '🇦🇪'),
    CountryModel(code: 'QA', name: 'Qatar', flag: '🇶🇦'),
    CountryModel(code: 'KW', name: 'Kuwait', flag: '🇰🇼'),
    CountryModel(code: 'BH', name: 'Bahrain', flag: '🇧🇭'),
    CountryModel(code: 'OM', name: 'Oman', flag: '🇴🇲'),
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileCubit>().state;
    if (state is ProfileLoaded) {
      final user = state.user;
      _nameController = TextEditingController(text: user.fullName);
      _emailController = TextEditingController(text: user.email);
      _phoneController = TextEditingController(text: user.phone ?? '');
      _selectedCountryName = user.country ?? 'Select Country';
      _avatarUrl = user.avatarUrl ?? 'https://i.pravatar.cc/150?u=green_rabbit';
      
      // Find country mapping for flag/code if it exists (or keep default)
      final countryMatch = _countries.firstWhere(
        (c) => c.name.toLowerCase() == _selectedCountryName.toLowerCase() || c.code.toLowerCase() == _selectedCountryName.toLowerCase(),
        orElse: () => _countries.first,
      );
      _selectedCountryFlag = countryMatch.flag;
      _selectedCountryCode = countryMatch.code;
      if (_selectedCountryName == 'Select Country' || _selectedCountryName.length == 2) {
         _selectedCountryName = countryMatch.name;
      }
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _phoneController = TextEditingController();
      _selectedCountryName = 'Select Country';
      _selectedCountryCode = 'EG';
      _selectedCountryFlag = '🇪🇬';
      _avatarUrl = 'https://i.pravatar.cc/150?u=green_rabbit';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // --- Avatar Section ---
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showAvatarPicker(context),
                    child: BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (context, state) {
                        String currentAvatar = _avatarUrl;
                        bool isLoading = false;
                        
                        if (state is ProfileLoaded) {
                          currentAvatar = state.user.avatarUrl ?? 'https://i.pravatar.cc/150?u=green_rabbit';
                        } else if (state is ProfileLoading) {
                          isLoading = true;
                        }

                        return Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                              ),
                              child: CircleAvatar(
                                radius: 52,
                                backgroundImage: NetworkImage(currentAvatar),
                                child: isLoading ? const CircularProgressIndicator(color: Colors.white) : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4C3BC9), // specific indigo/blue from theme
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showAvatarPicker(context),
                    child: Text(
                      'Change Avatar',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            // --- Form Fields ---
            _buildFieldLabel('Name'),
            _buildTextField(_nameController),
            const SizedBox(height: 20),
            
            _buildFieldLabel('Email'),
            _buildTextField(_emailController),
            const SizedBox(height: 20),
            
            _buildFieldLabel('Phone number'),
            _buildTextField(_phoneController),
            const SizedBox(height: 20),
            
            _buildFieldLabel('Country'),
            _buildCountryDropdown(),
            
            const SizedBox(height: 32),
            
            // --- Add Account Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Color(0xFF4C3BC9), size: 18),
                label: const Text(
                  'Add Account',
                  style: TextStyle(
                    color: Color(0xFF4C3BC9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5E7EB), // light grey/off-white
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // --- Delete Account Text ---
            InkWell(
              onTap: () => _showDeleteAccountBottomSheet(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // --- Save Changes Button ---
            SizedBox(
              width: double.infinity,
              child: BlocConsumer<ProfileCubit, ProfileState>(
                listener: (context, state) {
                  if (state is ProfileLoaded) {
                    _showSuccessAlert(context, 'Profile updated successfully');
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) Navigator.pop(context);
                    });
                  } else if (state is ProfileError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                    );
                  }
                },
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is ProfileLoading 
                      ? null 
                      : () {
                        context.read<ProfileCubit>().updateProfile(
                          fullName: _nameController.text,
                          phone: _phoneController.text,
                          country: _selectedCountryCode,
                        );
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C3BC9),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: state is ProfileLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }


  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF11141B) : Colors.grey.shade100, // dark or light surface
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4C3BC9)),
        ),
      ),
    );
  }


  Widget _buildCountryDropdown() {
    return InkWell(
      onTap: () => _showCountryPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF11141B) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Text(_selectedCountryFlag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              _selectedCountryName,
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 16),
            ),
            const Spacer(),
            Icon(Icons.keyboard_arrow_down, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
          ],
        ),
      ),
    );
  }


  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image != null && mounted) {
        // Upload immediately
        context.read<ProfileCubit>().updateAvatar(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showAvatarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F111A) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Change Avatar',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _avatarChoiceItem(
                    context,
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _avatarChoiceItem(
                    context,
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _avatarChoiceItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF4C3BC9), size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker(BuildContext context) async {

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountrySelectionScreen(
          countries: _countries,
          currentCountryName: _selectedCountryName,
        ),
      ),
    );
    if (result != null && result is Map<String, String>) {
      setState(() {
        _selectedCountryName = result['name']!;
        _selectedCountryCode = result['code']!;
        _selectedCountryFlag = result['flag']!;
      });
    }
  }

  void _showDeleteAccountBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          decoration: const BoxDecoration(
            color: Color(0xFF0E1117), // Deep background
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top strip handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Warning icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Are you sure you want to delete your account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "You'll lose all AI data, preferences, and premium access. This cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Keep Account button with gradient
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4C3BC9), Color(0xFF1B1E2B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Keep Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Delete Account outlined button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                   // This would trigger DELETE /users/me API
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Delete My Account',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void _showSuccessAlert(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1E2B), // Dark surface color
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: Color(0xFF16A34A), width: 6), // Green border as in image
            ),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

