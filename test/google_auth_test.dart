import 'package:flutter_test/flutter_test.dart';
import 'package:map_project/services/google_auth_service.dart';

void main() {
  group('Google Auth Service Tests', () {
    test('GoogleAuthService should have required methods', () {
      expect(GoogleAuthService.signInWithGoogle, isA<Function>());
      expect(GoogleAuthService.signOut, isA<Function>());
      expect(GoogleAuthService.isSignedIn, isA<Function>());
      expect(GoogleAuthService.getCurrentUser, isA<Function>());
    });
  });
}
