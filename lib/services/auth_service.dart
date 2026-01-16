import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp(String email, String password, String fullName) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName}, // Meta data for Trigger logic if any
    );
    // Note: We might need to manually insert into `profiles` if a trigger isn't set up.
    // Assuming the existing app setup relies on a trigger or manual insert? 
    // Previous code didn't show manual insert for profile on Signup in `login.dart`.
    // It likely relies on Supabase Auto-Confirm or just basic Auth. 
    // We will verify this.
    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
