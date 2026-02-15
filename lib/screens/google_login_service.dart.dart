import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthService {
  // -----------------------------------------------------------
  // 🎯 OAUTH CLIENT IDS
  // -----------------------------------------------------------

  /// iOS OAuth Client ID (REQUIRED for iOS)
  static const String _iosClientId =
      "445644172348-io17grh996mpqod5nj4jd8lnrmbp9kp8.apps.googleusercontent.com";

  // -----------------------------------------------------------
  // 🔥 GOOGLE LOGIN
  // -----------------------------------------------------------
  static Future<Map<String, dynamic>?> loginWithGoogle() async {
    try {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("🟡 START: loginWithGoogle()");

      final googleSignIn = GoogleSignIn(
        /// iOS → clientId REQUIRED
        /// Android → clientId AUTO (google-services.json se)
        clientId:
            defaultTargetPlatform == TargetPlatform.iOS ? _iosClientId : null,

        /// ❌ ANDROID ke liye serverClientId UI login me use nahi hota
        /// (Backend verification ke waqt use hota hai)
        scopes: const ['email', 'profile'],
      );

      debugPrint("📌 Platform: $defaultTargetPlatform");
      debugPrint("📌 iOS clientId: "
          "${defaultTargetPlatform == TargetPlatform.iOS ? _iosClientId : 'AUTO'}");

      debugPrint("🟡 Opening Google account chooser...");
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // ---------------- USER CANCELLED ----------------
      if (googleUser == null) {
        debugPrint("❌ Google Sign-In cancelled");
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        return null;
      }

      debugPrint("🟢 ACCOUNT SELECTED");
      debugPrint("    ID    : ${googleUser.id}");
      debugPrint("    NAME  : ${googleUser.displayName}");
      debugPrint("    EMAIL : ${googleUser.email}");
      debugPrint("    PHOTO : ${googleUser.photoUrl}");

      // ---------------- TOKEN FETCH ----------------
      debugPrint("🟡 Fetching tokens...");
      final GoogleSignInAuthentication auth =
          await googleUser.authentication;

      debugPrint("🟢 TOKENS RECEIVED");
      debugPrint("    idToken     : ${auth.idToken?.substring(0, 12)}...");
      debugPrint("    accessToken : ${auth.accessToken?.substring(0, 12)}...");

      // ---------------- FINAL DATA ----------------
      final data = {
        'provider': 'google',
        'provider_id': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
        'photo': googleUser.photoUrl ?? '',
        'id_token': auth.idToken ?? '',
        'access_token': auth.accessToken ?? '',
      };

      debugPrint("✅ GOOGLE LOGIN SUCCESS");
      debugPrint(const JsonEncoder.withIndent('  ').convert(data));
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      return data;

    } catch (e, stack) {
      debugPrint("🔥 GOOGLE LOGIN ERROR");
      debugPrint("ERROR: $e");
      debugPrint("STACK: $stack");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      return null;
    }
  }

  // -----------------------------------------------------------
  // 🍎 APPLE LOGIN
  // -----------------------------------------------------------
  static Future<Map<String, dynamic>?> loginWithApple() async {
    try {
      debugPrint("🟡 START: loginWithApple()");

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final fullName =
          "${credential.givenName ?? ''} ${credential.familyName ?? ''}".trim();

      final data = {
        'provider': 'apple',
        'provider_id': credential.userIdentifier ?? '',
        'email': credential.email ?? '',
        'name': fullName,
        'identity_token': credential.identityToken ?? '',
      };

      debugPrint("✅ APPLE LOGIN SUCCESS");
      debugPrint(const JsonEncoder.withIndent('  ').convert(data));
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      return data;

    } catch (e, stack) {
      debugPrint("🔥 APPLE LOGIN ERROR");
      debugPrint("ERROR: $e");
      debugPrint("STACK: $stack");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      return null;
    }
  }
}
