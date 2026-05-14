import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle orbitron(double size, {FontWeight fw = FontWeight.w700, Color? color, double ls = 0.5}) =>
      GoogleFonts.orbitron(
        fontSize: size,
        fontWeight: fw,
        color: color ?? AppColors.textPrimary,
        letterSpacing: ls,
      );

  static TextStyle ibmSans(double size, {FontWeight fw = FontWeight.w400, Color? color, double ls = 0}) =>
      GoogleFonts.ibmPlexSans(
        fontSize: size,
        fontWeight: fw,
        color: color ?? AppColors.textPrimary,
        letterSpacing: ls,
      );
}
