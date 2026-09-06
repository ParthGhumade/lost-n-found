class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qmlzegacppfjsrgzacbi.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_9YTNxtiOTEKOjUbsdUFkvA_RBJsYpbI',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtbHplZ2FjcHBmanNyZ3phY2JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg2ODQ3OTIsImV4cCI6MjEwNDI2MDc5Mn0._7DMfB7mSWefVUdVamPsb0yWuNLykXNmR2u6HZdxRAY',
  );

  static const String storageBucket = String.fromEnvironment(
    'SUPABASE_STORAGE_BUCKET',
    defaultValue: 'item-images-private',
  );

  // Table names
  static const String tableContacts = 'contacts';
  static const String tableItems = 'items';
  static const String tableClaims = 'claims';
}
