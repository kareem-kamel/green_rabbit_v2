import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

/// A globally reusable dialog that blocks user interaction when there is no internet.
///
/// The dialog is dark themed according to the app design system:
///   • Background color: 0xFF121212 (dark gray)
///   • Primary action color: 0xFF8B5CF6 (brand purple)
///   • Text color: white
///
/// It is shown with `barrierDismissible: false` and wrapped in a `PopScope`
/// to prevent Android back‑button dismissal.
class NoInternetDialog extends StatelessWidget {
  const NoInternetDialog({super.key});

  static bool _isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (_isShowing) return;
    _isShowing = true;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const NoInternetDialog(),
    ).then((_) => _isShowing = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: const Color(0xFF121212),
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.wifi_off,
                size: 48,
                color: Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please check your network settings and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  // Attempt a lightweight connectivity check by calling a silent endpoint.
                  // The AuthCubit will emit a new state; on success the dialog will be dismissed.
                  final authCubit = BlocProvider.of<AuthCubit>(context);
                  await authCubit.checkAuth();
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
