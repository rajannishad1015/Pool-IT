import 'package:supabase_flutter/supabase_flutter.dart';

class WalletService {
  final SupabaseClient _client;

  WalletService(this._client);

  /// Get wallet balance
  Future<double> getWalletBalance(String userId) async {
    try {
      final response = await _client
          .from('wallets')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null) return 0.0;
      return (response['balance'] as num).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  /// Get transaction history
  Future<List<Map<String, dynamic>>> getTransactions(String userId) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('wallet_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add money to wallet (Simulated)
  Future<void> addMoney(String userId, double amount) async {
    // 1. Get current balance
    final currentBalance = await getWalletBalance(userId);
    
    // 2. Update wallet
    await _client.from('wallets').upsert({
      'user_id': userId,
      'balance': currentBalance + amount,
    });

    // 3. Log transaction
    await _client.from('transactions').insert({
      'wallet_id': userId,
      'amount': amount,
      'type': 'deposit',
      'description': 'Added to Wallet',
    });
  }

  /// Process ride payment
  Future<void> processPayment({
    required String userId,
    required double amount,
    required String rideId,
    required String description,
  }) async {
    final currentBalance = await getWalletBalance(userId);
    
    if (currentBalance < amount) {
      throw Exception('Insufficient balance');
    }

    // 1. Update wallet
    await _client.from('wallets').update({
      'balance': currentBalance - amount,
    }).eq('user_id', userId);

    // 2. Log transaction
    await _client.from('transactions').insert({
      'wallet_id': userId,
      'amount': amount,
      'type': 'payment',
      'description': description,
    });
  }
}
