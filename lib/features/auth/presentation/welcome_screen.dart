import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Background #000000
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Mascot Card
                  _buildMascotCard(),

                  const SizedBox(height: 32),

                  // Headings
                  Text(
                    'Welcome to Oreo',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.0,
                      color: Colors.white,
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
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 32),

                  // Google Button
                  _buildGoogleButton(context),

                  const SizedBox(height: 32),

                  // Footer
                  Text(
                    'By continuing, you agree to our\nTerms of Service and Privacy Policy.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.4),
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

  Widget _buildMascotCard() {
    return AspectRatio(
      aspectRatio: 1.6, // Rectangular card
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          gradient: RadialGradient(
            colors: [
              const Color(0xFF9C27B0).withValues(alpha: 0.15), // Soft purple glow
              Colors.white.withValues(alpha: 0.02),
            ],
            center: Alignment.center,
            radius: 0.8,
          ),
          color: Colors.white.withValues(alpha: 0.03), // Subtle glass surface
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

  Widget _buildGoogleButton(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Authentication logic not implemented in this UI phase
        },
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
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
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
