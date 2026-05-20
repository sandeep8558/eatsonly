import 'package:flutter/material.dart';

class ApiConstants {
  static String get _host => 'https://eatsonly.com';

  static String get baseUrl => '$_host/api';
  
  // Auth Endpoints
  static String get login => '$baseUrl/login';
  static String get register => '$baseUrl/register';
  static String get forgotPassword => '$baseUrl/forgot-password';
  static String get resetPassword => '$baseUrl/reset-password';
  static String get userProfile => '$baseUrl/me';
  static String get upgrade => '$baseUrl/upgrade';
  static String get restaurants => '$baseUrl/restaurants';
  static String get staff => '$baseUrl/staff';
  static String get roles => '$baseUrl/roles';
  static String get addresses => '$baseUrl/addresses';
  static String get profile => '$baseUrl/profile';
  static String get taxGroups => '$baseUrl/tax-groups';
  static String get storageUrl => '$baseUrl/media/';
  static String get storageBaseUrl => '$_host/storage/';
  
  // Inventory & Procurement Endpoints
  static String get inventory => '$baseUrl/inventory';
  static String get inventoryCategories => '$baseUrl/inventory-categories';
  static String get suppliers => '$baseUrl/suppliers';
  static String get purchases => '$baseUrl/purchases';
  static String get recipes => '$baseUrl/recipes';
  static String get issuances => '$baseUrl/issuances';
  static String get wastage => '$baseUrl/wastage';
  static String get stockLedger => '$baseUrl/stock-ledger';
  static String get stockAudits => '$baseUrl/stock-audits';

  // Integrations (Zomato & Swiggy) Endpoints
  static String get integrations => '$baseUrl/integrations';
  static String get integrationsCredentials => '$baseUrl/integrations/credentials';
  static String get integrationsMenu => '$baseUrl/integrations/menu';
  static String get integrationsMapItem => '$baseUrl/integrations/map-item';
}

class BrandColors {
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color primaryGoldLight = Color(0xFFE5C158);
  static const Color primaryGoldDark = Color(0xFFB8860B);
}
