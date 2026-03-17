import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocket_ledger/features/auth/presentation/auth_notifier.dart';

class AuthScreen extends HookConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sharp Technical Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFFFFF), width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.terminal_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 32),
              Text(
                'POCKET_LEDGER.EXE',
                style: GoogleFonts.jetbrainsMono(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SYSTEM_AUTH_REQUIRED',
                style: GoogleFonts.jetbrainsMono(
                  fontSize: 12,
                  color: const Color(0xFF888888),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 48),
              _TerminalField(
                controller: emailController,
                label: 'USER_ID',
                hint: 'ENTER_EMAIL',
              ),
              const SizedBox(height: 24),
              _TerminalField(
                controller: passwordController,
                label: 'ACCESS_KEY',
                hint: '********',
                isPassword: true,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () => ref.read(authProvider.notifier).signIn(
                            emailController.text.trim(),
                            passwordController.text.trim(),
                          ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'EXECUTE_LOGIN',
                          style: GoogleFonts.jetbrainsMono(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'MADE WITH ❤️ BY BHAWUK',
                  style: GoogleFonts.jetbrainsMono(
                    fontSize: 10,
                    color: const Color(0xFF1F1F1F),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TerminalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isPassword;

  const _TerminalField({
    required this.controller,
    required this.label,
    required this.hint,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '> $label',
          style: GoogleFonts.jetbrainsMono(
            color: const Color(0xFF888888),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: GoogleFonts.jetbrainsMono(color: Colors.white, fontSize: 14),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.jetbrainsMono(color: const Color(0xFF1F1F1F)),
            filled: true,
            fillColor: const Color(0xFF0A0A0A),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF1F1F1F)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFFFFFFF)),
            ),
          ),
        ),
      ],
    );
  }
}
