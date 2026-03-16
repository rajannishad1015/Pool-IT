import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSupabase {
  static const String supabaseUrl = 'https://hrbobsgasxibsbqkuhxy.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_Dk4ZNMsLbPrU9qW4fqxwRQ_QjIsqPGX';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
