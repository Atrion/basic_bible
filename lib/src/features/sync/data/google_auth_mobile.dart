import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_auth_service.dart' as api;
import 'google_oauth_config.dart';

/// Android/iOS auth via the google_sign_in plugin (v7 API).
class MobileGoogleAuthService implements api.GoogleAuthService {
  static const _scopes = [driveAppDataScope];

  /// Remembers who is signed in so a cold start can show the signed-in state
  /// without going through Google's sign-in UI again.
  static const _emailKey = 'googleSyncAccountEmail';

  bool _initialized = false;
  GoogleSignInAccount? _account;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      // Android requires the Web OAuth client as the serverClientId for
      // google_sign_in; iOS can use the iOS client ID via Info.plist.
      clientId: Platform.isIOS && googleIosClientId.isNotEmpty
          ? googleIosClientId
          : null,
      serverClientId: Platform.isAndroid && googleWebClientId.isNotEmpty
          ? googleWebClientId
          : null,
    );
    _initialized = true;
  }

  @override
  bool get isSupported => true;

  @override
  // Mobile clients are registered in the Cloud console, not passed in code,
  // so there is nothing to check at runtime here.
  bool get isConfigured => true;

  @override
  Future<api.GoogleAccount?> restoreExistingSignIn() async {
    // Cold start: don't call attemptLightweightAuthentication() when we
    // already know who signed in. On Android that goes through Credential
    // Manager and can show Google's "signing in as ..." sheet on every launch.
    // Access tokens are fetched silently when a sync needs one (getAccessToken).
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_emailKey);
    if (savedEmail != null && savedEmail.isNotEmpty) {
      return api.GoogleAccount(email: savedEmail);
    }
    // Signed in before the email was remembered: restore once, then remember.
    await _ensureInitialized();
    final attempt = GoogleSignIn.instance.attemptLightweightAuthentication();
    final account = attempt == null ? null : await attempt;
    _account = account;
    if (account != null) {
      await prefs.setString(_emailKey, account.email);
    }
    return account == null ? null : api.GoogleAccount(email: account.email);
  }

  @override
  Future<api.GoogleAccount> signIn() async {
    await _ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: _scopes,
    );
    _account = account;
    // Complete Drive consent as part of sign-in so the first sync doesn't
    // surprise the user with a second prompt.
    await account.authorizationClient.authorizationForScopes(_scopes) ??
        await account.authorizationClient.authorizeScopes(_scopes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, account.email);
    return api.GoogleAccount(email: account.email);
  }

  @override
  Future<String> getAccessToken() async {
    await _ensureInitialized();
    var account = _account;
    if (account == null) {
      // Preferred: a token for the already-approved account with no sign-in
      // UI at all (returns null instead of prompting).
      try {
        final silent = await GoogleSignIn.instance.authorizationClient
            .authorizationForScopes(_scopes);
        if (silent != null) return silent.accessToken;
      } on GoogleSignInException {
        // Fall through to the lightweight restore below.
      }
      account = await (GoogleSignIn.instance
              .attemptLightweightAuthentication() ??
          Future<GoogleSignInAccount?>.value());
    }
    if (account == null) {
      throw const api.GoogleSignInRequiredException();
    }
    _account = account;
    // Never fall back to interactive authorizeScopes() here: this runs from
    // automatic background syncs, which must not pop a consent dialog the
    // user didn't ask for. Interactive consent happens only in signIn().
    try {
      final authorization = await account.authorizationClient
          .authorizationForScopes(_scopes);
      if (authorization == null) {
        throw const api.GoogleSignInRequiredException(
          'Google Drive access needs to be approved again. Please sign in.',
        );
      }
      return authorization.accessToken;
    } on GoogleSignInException catch (e) {
      throw api.GoogleSignInRequiredException(
        'Google authorization failed: ${e.description ?? e.code.name}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    _account = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await GoogleSignIn.instance.signOut();
  }
}
