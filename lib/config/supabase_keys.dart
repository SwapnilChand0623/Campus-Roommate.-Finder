class SupabaseKeys {
  /// Replace with your Supabase project URL.
  static const supabaseUrl = 'https://jjjaljfpvbnvwhrkuogj.supabase.co';

  /// Replace with your Supabase anon/public key.
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpqamFsamZwdmJudndocmt1b2dqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4NTAzOTgsImV4cCI6MjA3OTQyNjM5OH0.6XQKJl26d6qFYseFqrQbkm_zT9mPN1P7lZxcYK8Ig74';

  static bool get isConfigured =>
      !supabaseUrl.contains('YOUR-PROJECT') && supabaseAnonKey != 'SUPABASE-ANON-KEY';
}
