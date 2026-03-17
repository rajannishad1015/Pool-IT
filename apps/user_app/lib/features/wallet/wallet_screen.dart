import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/wallet_providers.dart';
import '../../core/providers/supabase_providers.dart';
import 'package:intl/intl.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final transactionsAsync = ref.watch(transactionHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: const Color(0xFFF6F8FC),
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletBalanceProvider);
          ref.invalidate(transactionHistoryProvider);
        },
        child: balanceAsync.when(
          data: (balance) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(context, ref, balance),
                const SizedBox(height: 18),
                _buildQuickAdd(context, ref),
                const SizedBox(height: 24),
                _buildTransactionHistory(transactionsAsync),
                const SizedBox(height: 24),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, WidgetRef ref, double balance) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryNavy, AppColors.trustBlue],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                'SmartPool Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Last updated ${DateFormat('hh:mm a').format(DateTime.now())}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildActionButton(Icons.add_circle_outline, 'Add Money', () => _showAddMoneyDialog(context, ref)),
              const SizedBox(width: 16),
              _buildActionButton(Icons.file_download_outlined, 'Withdraw', () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAdd(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EBF4)),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Quick Add',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [100.0, 250.0, 500.0, 1000.0].map((amt) {
              return InkWell(
                onTap: () => _addMoney(context, ref, amt),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    border: Border.all(color: const Color(0xFFDCE4F1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹${amt.toInt()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ));
  }

  Widget _buildTransactionHistory(AsyncValue<List<Map<String, dynamic>>> transactionsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
          ),
        ),
        const SizedBox(height: 12),
        transactionsAsync.when(
          data: (transactions) => transactions.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No transactions yet', style: TextStyle(color: AppColors.grey)),
                ))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final type = tx['type'] as String?;
                    final isCredit = type == 'deposit' || type == 'refund';
                    final date = DateTime.parse(tx['created_at']);
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE6ECF5)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: isCredit
                              ? const Color(0xFFE9F9EF)
                              : const Color(0xFFFFEFF1),
                          child: Icon(
                            isCredit ? Icons.call_received : Icons.call_made,
                            color: isCredit ? const Color(0xFF17985F) : AppColors.accentCoral,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          tx['description'] ?? 'Transaction',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(date.toLocal()),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryNavy.withValues(alpha: 0.6),
                          ),
                        ),
                        trailing: Text(
                          '${isCredit ? '+' : '-'}₹${(tx['amount'] as num).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isCredit ? const Color(0xFF17985F) : AppColors.accentCoral,
                          ),
                        ),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          )),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  Future<void> _addMoney(BuildContext context, WidgetRef ref, double amount) async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      await ref.read(walletServiceProvider).addMoney(user.id, amount);
      
      ref.invalidate(walletBalanceProvider);
      ref.invalidate(transactionHistoryProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('₹$amount added to wallet!')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add money: $e')),
      );
    }
  }

  void _showAddMoneyDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Money'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                _addMoney(context, ref, amount);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
