import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFFF48C25); // Naranja Luigi's
  static const primaryDark = Color(0xFFD4760D);
  static const primaryLight = Color(0xFFFFA94D);
  static const background = Color(0xFFF8F7F5); // Crema suave
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF2D2D2D);
  static const textSecondary = Color(0xFF6B7280);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Status colors
  static const statusNuevo = Color(0xFF3B82F6);
  static const statusPrep = Color(0xFFF59E0B);
  static const statusArmado = Color(0xFF8B5CF6);
  static const statusHorno = Color(0xFFEF4444);
  static const statusListo = Color(0xFF10B981);
  static const statusRetirado = Color(0xFF06B6D4);
  static const statusEnCamino = Color(0xFF6366F1);
  static const statusEntregado = Color(0xFF059669);
  static const statusEliminado = Color(0xFF9CA3AF);

  static Color getStatusColor(String status) {
    switch (status) {
      case 'NUEVO':
        return statusNuevo;
      case 'PREP':
        return statusPrep;
      case 'ARMADO':
        return statusArmado;
      case 'HORNO':
        return statusHorno;
      case 'LISTO':
        return statusListo;
      case 'RETIRADO':
        return statusRetirado;
      case 'EN_CAMINO':
        return statusEnCamino;
      case 'ENTREGADO':
        return statusEntregado;
      case 'ELIMINADO':
        return statusEliminado;
      default:
        return textSecondary;
    }
  }

  static String getStatusLabel(String status) {
    switch (status) {
      case 'NUEVO':
        return 'Nuevo';
      case 'PREP':
        return 'Preparando';
      case 'ARMADO':
        return 'Armado';
      case 'HORNO':
        return 'En Horno';
      case 'LISTO':
        return 'Listo';
      case 'RETIRADO':
        return 'Retirado';
      case 'EN_CAMINO':
        return 'En Camino';
      case 'ENTREGADO':
        return 'Entregado';
      case 'ELIMINADO':
        return 'Eliminado';
      default:
        return status;
    }
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
