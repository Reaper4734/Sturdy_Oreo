import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import '../../../app/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Oreo Logo Placeholder
                  Text(
                    'Oreo',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.0,
                      color: colors.fgPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Mascot Card
                  _buildMascotCard(colors),

                  const SizedBox(height: 32),

                  // Headings
                  Text(
                    'Welcome to Oreo',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.0,
                      color: colors.fgPrimary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your AI learning workspace\nthat builds real skills.',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: colors.fgSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 32),

                  if (authState.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        authState.error!,
                        style: GoogleFonts.inter(color: Colors.red),
                      ),
                    ),

                  if (authState.isLoading)
                    const CircularProgressIndicator()
                  else if (kIsWeb)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: web.renderButton(),
                    )
                  else
                    _buildGoogleButton(context, ref, colors),

                  const SizedBox(height: 32),

                  // Footer
                  Text(
                    'By continuing, you agree to our\nTerms of Service and Privacy Policy.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colors.fgMuted,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMascotCard(AppColorsExtension colors) {
    return AspectRatio(
      aspectRatio: 1.6, // Rectangular card
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: colors.borderSubtle,
            width: 1,
          ),
          gradient: RadialGradient(
            colors: [
              const Color(0xFF9C27B0).withValues(alpha: 0.12), // Soft purple glow
              colors.bgSurface.withValues(alpha: 0.5),
            ],
            center: Alignment.center,
            radius: 0.8,
          ),
          color: colors.bgSurface,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.05),
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: SvgPicture.asset(
            'assets/mascots/oreo_mascot.svg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .moveY(begin: -6, end: 6, duration: 2000.ms, curve: Curves.easeInOut),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context, WidgetRef ref, AppColorsExtension colors) {
    return Material(
      color: colors.bgSurface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ref.read(authProvider.notifier).loginWithGoogle();
        },
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderDefault, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/logos/google/google_g_logo.svg',
                height: 24,
                width: 24,
              ),
              const SizedBox(width: 16),
              Text(
                'Continue with Google',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.fgPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
