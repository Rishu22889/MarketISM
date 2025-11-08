import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // TODO: Replace with your actual Supabase project details
  static const String supabaseUrl = 'https://nurrxoppjoodhxumnglm.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51cnJ4b3Bwam9vZGh4dW1uZ2xtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyODEzNTcsImV4cCI6MjA3Nzg1NzM1N30.rDtHVRaa0SxmUJ_ZpMfowva0UJcaBXfRAZ0AzZDCPeA';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}