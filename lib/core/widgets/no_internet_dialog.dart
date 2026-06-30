import 'dart:io';
import 'package:flutter/material.dart';

/// A globally reusable dialog that blocks user interaction when there is no internet.
///
/// The dialog is dark themed according to the app design system:
///   • Background color: 0xFF121212 (dark gray)
///   • Primary action color: 0xFF8B5CF6 (brand purple)
///   • Text color: white
///
/// It is shown with `barrierDismissible: false` and wrapped in a `PopScope`
/// to prevent Android back‑button dismissal.
///
/// Retry behaviour:
///   • Tapping "Try Again" shows a loading indicator on the button.
///   • The dialog only closes after a successful connectivity check.
///   • If the check fails the button resets to "Try Again" and the dialog
///     stays visible.
class NoInternetDialog extends StatefulWidget {
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
  State<NoInternetDialog> createState() => _NoInternetDialogState();
}

class _NoInternetDialogState extends State<NoInternetDialog> {
  bool _isLoading = false;

  /// Performs a lightweight DNS lookup to confirm that the device has internet
  /// access without going through Dio / the app's interceptor stack.
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onRetry() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final hasInternet = await _checkConnectivity();

    if (!mounted) return;

    if (hasInternet) {
      // Connectivity is restored — dismiss the dialog.
      Navigator.of(context).pop();
    } else {
      // Still offline — reset the button so the user can try again.
      setState(() => _isLoading = false);
    }
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
                // Disable the button while a retry is in progress.
                onPressed: _isLoading ? null : _onRetry,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
