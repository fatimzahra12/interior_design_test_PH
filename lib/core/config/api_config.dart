import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // IMPORTANT: Remplacez 192.168.1.100 par l'IP de VOTRE PC
  // Pour trouver votre IP: ouvrez CMD et tapez "ipconfig"
  // Cherchez "Adresse IPv4" dans la section "Carte réseau sans fil Wi-Fi"
  
  static const String baseUrl = kIsWeb 
      ? 'http://localhost:8000'           // Pour le web (navigateur)
      : 'http://192.168.11.107:8000';      // Pour Android - CHANGEZ CETTE IP !
  
  // Timeout pour les requêtes HTTP
  static const Duration timeout = Duration(seconds: 30);
  
  // Endpoints de l'API
  static const String authEndpoint = '/api/auth';
  static const String registerEndpoint = '$authEndpoint/register';
  static const String loginEndpoint = '$authEndpoint/login';
  static const String meEndpoint = '$authEndpoint/me';
  static const String classifyEndpoint = '/predict';
  static const String transformEndpoint = '/transform';
  static const String healthEndpoint = '/health';
  
  // URL complètes
  static String get registerUrl => '$baseUrl$registerEndpoint';
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get meUrl => '$baseUrl$meEndpoint';
  static String get classifyUrl => '$baseUrl$classifyEndpoint';
  static String get transformUrl => '$baseUrl$transformEndpoint';
  static String get healthUrl => '$baseUrl$healthEndpoint';
}