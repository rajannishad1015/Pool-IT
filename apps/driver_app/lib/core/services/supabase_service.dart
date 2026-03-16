import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String url = 'https://hrbobsgasxibsbqkuhxy.supabase.co';
  static const String anonKey = 'sb_publishable_Dk4ZNMsLbPrU9qW4fqxwRQ_QjIsqPGX';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
