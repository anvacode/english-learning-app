/// Servicio de autenticación para el panel de administración.
///
/// Contiene credenciales hardcodeadas para el admin predefinido.
/// No requiere Firestore ni colecciones adicionales.
class AdminAuthService {
  /// Email de la cuenta admin principal.
  static const adminEmail = 'english.learning.app.4559e@gmail.com';

  static const List<Map<String, String>> _adminCredentials = [
    {
      'email': adminEmail,
      'password': 'EnglishApp2026!',
    },
  ];

  /// Valida si las credenciales coinciden con un admin predefinido.
  static bool validateAdmin(String email, String password) {
    return _adminCredentials.any(
      (cred) => cred['email'] == email && cred['password'] == password,
    );
  }

  /// Verifica si un email corresponde a una cuenta admin.
  static bool isAdminEmail(String email) {
    return email == adminEmail;
  }
}
