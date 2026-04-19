class UserSession {
  static Map<String, dynamic> currentUser = {};

  static void setUser(Map<String, dynamic> userData) {
    currentUser = userData;
  }

  static void clear() {
    currentUser = {};
  }

  static String get email => currentUser['email'] ?? '';
  static String get firstName => currentUser['first_name'] ?? 'Traveler';
  static String get fullName =>
      '${currentUser['first_name'] ?? ''} ${currentUser['last_name'] ?? ''}'
          .trim();
}