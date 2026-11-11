import 'package:flutter/material.dart';

class AppColors {
  // Required Centralized Core Colors (Observed from Figma)
  static const Color primary = Color(0xFF1E4DB7); // Core Royal Blue
  static const Color sidebar = Color(0xFF1E4DB7); // Sidebar Navy/Royal Blue
  static const Color background = Color(0xFFF4F7FC); // Canvas light grayish blue
  static const Color card = Color(0xFFFFFFFF); // Pure White Surface
  static const Color textPrimary = Color(0xFF1E293B); // Dark slate text
  static const Color textSecondary = Color(0xFF64748B); // Cool grey subtitle/secondary
  static const Color highRisk = Color(0xFFDC2626); // High / Critical risk red
  static const Color mediumRisk = Color(0xFFD97706); // Medium risk amber
  static const Color success = Color(0xFF16A34A); // Verified / Low risk green
  static const Color border = Color(0xFFE2E8F0); // Default card & container border

  // Extended Semantic & Functional Tokens
  static const Color primaryDark = Color(0xFF153C93);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primarySoft = Color(0xFFEFF6FF); // Light blue tint
  static const Color primaryAccent = Color(0xFF2563EB);

  // Surfaces
  static const Color surface = card;
  static const Color surfaceMuted = Color(0xFFF8FAFC);

  // Text Hierarchy
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFFFFFFF);

  // Sidebar Tokens
  static const Color sidebarBg = sidebar;
  static const Color sidebarBgDark = Color(0xFF173E96);
  static const Color sidebarActive = Color(0xFF2E63DE);
  static const Color sidebarActiveItemBg = Color(0x33FFFFFF);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);
  static const Color sidebarTextInactive = Color(0xFFC3D4FB);
  static const Color sidebarIconInactive = Color(0xFFA5C0F8);

  // Risk Badges (Background, Text, Border)
  static const Color riskHighText = highRisk;
  static const Color riskHighBg = Color(0xFFFEE2E2);
  static const Color riskHighBorder = Color(0xFFFECACA);

  static const Color riskMediumText = mediumRisk;
  static const Color riskMediumBg = Color(0xFFFEF3C7);
  static const Color riskMediumBorder = Color(0xFFFDE68A);

  static const Color riskLowText = success;
  static const Color riskLowBg = Color(0xFFDCFCE7);
  static const Color riskLowBorder = Color(0xFFBBF7D0);

  // Status Badges
  static const Color statusVerifiedText = success;
  static const Color statusVerifiedBg = Color(0xFFDCFCE7);

  static const Color statusPendingText = Color(0xFFB45309);
  static const Color statusPendingBg = Color(0xFFFEF3C7);

  static const Color statusFlaggedText = Color(0xFFB91C1C);
  static const Color statusFlaggedBg = Color(0xFFFEE2E2);

  static const Color statusBlockchainText = Color(0xFF6D28D9);
  static const Color statusBlockchainBg = Color(0xFFEDE9FE);

  // Borders, Inputs & Dividers
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color inputBorder = Color(0xFFCBD5E1);
  static const Color inputFocusBorder = primary;

  // Chart & Accent Colors
  static const Color chartBlue = Color(0xFF2563EB);
  static const Color chartOrange = Color(0xFFF97316);
  static const Color chartGreen = Color(0xFF10B981);
  static const Color chartRed = Color(0xFFEF4444);
  static const Color chartPurple = Color(0xFF8B5CF6);
}
