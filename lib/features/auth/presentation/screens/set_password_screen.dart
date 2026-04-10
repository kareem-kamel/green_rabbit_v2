import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/core/widgets/primary_button.dart'; // Adjust your path
import 'package:green_rabbit/features/auth/presentation/cubit/set_password_cubit.dart';
import 'package:green_rabbit/features/auth/presentation/cubit/set_password_state.dart';
import 'package:green_rabbit/features/auth/presentation/screens/password_updated_dialog.dart';


class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Variables to handle the show/hide password eye icon
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Reusable method for the custom dark theme text fields
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '********',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6)), // Purple focus
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: toggleVisibility,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SetPasswordCubit(),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Set a new password',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          titleSpacing: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: BlocConsumer<SetPasswordCubit, SetPasswordState>(
              listener: (context, state) {
                // Handle Success
                if (state is SetPasswordSuccess) {
                  // Show the beautiful custom dialog!
                  showDialog(
                    context: context,
                    barrierDismissible: false, // Prevents closing the dialog by tapping outside it
                    builder: (BuildContext context) {
                      return const PasswordUpdatedDialog(); // 👈 Call your new widget here
                    },
                  );
                } 
                // Handle Error
                else if (state is SetPasswordError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message), 
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      "Choose a strong password to secure your account.",
                      style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    // New Password Field
                    _buildPasswordField(
                      label: 'New password',
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      toggleVisibility: () {
                        setState(() => _obscureNewPassword = !_obscureNewPassword);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Confirm Password Field
                    _buildPasswordField(
                      label: 'Confirm password',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      toggleVisibility: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    
                    const SizedBox(height: 40),

                    // Reusable Primary Button
                    PrimaryButton(
                      text: 'Change Password',
                      isLoading: state is SetPasswordLoading,
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        context.read<SetPasswordCubit>().changePassword(
                          _newPasswordController.text,
                          _confirmPasswordController.text,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}