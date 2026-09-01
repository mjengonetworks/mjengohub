import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reviews & Testimonials',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_outline_rounded, size: 64, color: Color(0xFF8888AA)),
              const SizedBox(height: 16),
              Text(
                'Client Reviews Coming Soon',
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Feedback and verified ratings from Mjengo Hub users will appear here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF8888AA)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
