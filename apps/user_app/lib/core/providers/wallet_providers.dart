import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_providers.dart';

final walletBalanceProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;
  
  final walletService = ref.watch(walletServiceProvider);
  return await walletService.getWalletBalance(user.id);
});

final transactionHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final walletService = ref.watch(walletServiceProvider);
  return await walletService.getTransactions(user.id);
});

// Stream for real-time balance updates if supported by Supabase Realtime
final walletBalanceStreamProvider = StreamProvider<double>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0.0);
  
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('wallets')
      .stream(primaryKey: ['user_id'])
      .eq('user_id', user.id)
      .map((event) {
        if (event.isEmpty) return 0.0;
        return (event.first['balance'] as num).toDouble();
      });
});
