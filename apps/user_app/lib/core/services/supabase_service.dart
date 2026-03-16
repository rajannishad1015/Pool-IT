import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String url = 'https://hrbobsgasxibsbqkuhxy.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhyYm9ic2dhc3hpYnNicWt1aHh5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyMTU2ODQsImV4cCI6MjA4ODc5MTY4NH0.B0BowNrmVLoRUWhervPnq51eNavh7XGrTk_XEsMQMYE';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
