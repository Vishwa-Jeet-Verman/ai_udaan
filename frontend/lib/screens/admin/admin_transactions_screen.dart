import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/enrollment.dart';
import '../../utils/responsive.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  String? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final horizontalPadding = AppResponsive.horizontalPadding(
      context,
      mobile: 16,
      tablet: 20,
      desktop: 24,
    );
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context,
      tablet: 1080,
      desktop: 1320,
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: Column(
          children: [
            // Filter chips
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 8,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Verified', 'verified'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rejected', 'rejected'),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: adminProvider.transactionsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : adminProvider.transactionsError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            adminProvider.transactionsError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => adminProvider.fetchAllTransactions(
                              status: _filterStatus,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : adminProvider.transactions.isEmpty
                  ? const Center(child: Text('No transactions found.'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final useGrid =
                            constraints.maxWidth >=
                            AppResponsive.tabletBreakpoint;

                        if (!useGrid) {
                          return RefreshIndicator(
                            onRefresh: () => adminProvider.fetchAllTransactions(
                              status: _filterStatus,
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.all(horizontalPadding),
                              itemCount: adminProvider.transactions.length,
                              itemBuilder: (context, index) {
                                return _buildTransactionCard(
                                  adminProvider.transactions[index],
                                );
                              },
                            ),
                          );
                        }

                        final crossAxisCount = constraints.maxWidth >= 1200
                            ? 3
                            : 2;

                        return RefreshIndicator(
                          onRefresh: () => adminProvider.fetchAllTransactions(
                            status: _filterStatus,
                          ),
                          child: GridView.builder(
                            padding: EdgeInsets.all(horizontalPadding),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.05,
                                ),
                            itemCount: adminProvider.transactions.length,
                            itemBuilder: (context, index) {
                              return _buildTransactionCard(
                                adminProvider.transactions[index],
                                margin: EdgeInsets.zero,
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterStatus = status);
        context.read<AdminProvider>().fetchAllTransactions(status: status);
      },
    );
  }

  Widget _buildTransactionCard(
    Enrollment transaction, {
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 12),
  }) {
    Color statusColor;
    switch (transaction.transactionStatus) {
      case 'verified':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transaction.course?.title ?? 'Unknown Course',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    transaction.transactionStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (transaction.userName != null)
              Text(
                'Student: ${transaction.userName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (transaction.userEmail != null)
              Text(
                'Email: ${transaction.userEmail}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (transaction.course?.price != null)
              Text(
                'Amount: ${transaction.course!.isFree ? "Free" : "\u20B9${transaction.course!.price.toStringAsFixed(2)}"}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (transaction.enrolledAt != null)
              Text(
                'Date: ${transaction.enrolledAt!.toLocal().toString().split('.')[0]}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            if (transaction.transactionStatus == 'pending') ...[
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus(transaction.id, 'rejected'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(transaction.id, 'verified'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String transactionId, String status) async {
    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.updateTransactionStatus(
      transactionId,
      status,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Transaction $status successfully'
                : adminProvider.transactionsError ?? 'Failed',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
