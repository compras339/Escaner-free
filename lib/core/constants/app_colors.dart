import 'package:flutter/material.dart';

/// Paleta de colores sobria, moderna y accesible para el escáner de documentos
class AppColors {
  AppColors._();

  // Colores primarios (Verde esmeralda / azul profesional tipo escáner de documentos)
  static const Color primary = Color(0xFF0F766E); // Teal 700
  static const Color primaryLight = Color(0xFF14B8A6); // Teal 500
  static const Color primaryDark = Color(0xFF115E59); // Teal 800
  static const Color primaryContainer = Color(0xFFCCFBF1); // Teal 100

  // Colores secundarios y acentos
  static const Color secondary = Color(0xFF0284C7); // Sky 600
  static const Color secondaryContainer = Color(0xFFE0F2FE); // Sky 100
  static const Color accent = Color(0xFFF59E0B); // Amber 500

  // Superficies y fondos
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color cardDark = Color(0xFF1E293B);

  // Textos y contrastes
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Estados
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Guías y superposiciones de cámara
  static const Color cameraOverlay = Color(0x8A000000);
  static const Color cropHandle = Color(0xFF14B8A6);
  static const Color cropHandleBorder = Color(0xFFFFFFFF);
  static const Color cropGrid = Color(0x80FFFFFF);
}
