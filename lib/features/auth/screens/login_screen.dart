import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Placeholder login screen.
/// Replace the body with real authentication UI when ready.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Shield logo
                Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.blueGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blueGlow40,
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AppColors.textPrimary,
                        size: 40,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 32),

                // App name
                Text(
                  'VPI SECURE',
                  style: AppTextStyles.overlineLarge,
                  textAlign: TextAlign.center,
                ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 12),

                Text(
                      'Welcome Back',
                      style: AppTextStyles.display3,
                      textAlign: TextAlign.center,
                    )
                    .animate(delay: 250.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Sign in to your secure account',
                  style: AppTextStyles.bodyLarge,
                  textAlign: TextAlign.center,
                ).animate(delay: 350.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 48),

                // Email field
                _buildTextField(
                      label: 'Email address',
                      hint: 'you@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.1, end: 0),

                const SizedBox(height: 16),

                // Password field
                _buildTextField(
                      label: 'Password',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                    )
                    .animate(delay: 480.ms)
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.1, end: 0),

                const SizedBox(height: 12),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot password?',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primaryBright,
                      ),
                    ),
                  ),
                ).animate(delay: 550.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // Sign in button
                SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: AppColors.blueGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blueGlow40,
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(16),
                            splashColor: Colors.white12,
                            child: Center(
                              child: Text(
                                'Sign In',
                                style: AppTextStyles.buttonLarge,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Register prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodySmall,
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Create one',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryBright,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primaryBright, size: 20),
          ),
        ),
      ],
    );
  }
}
