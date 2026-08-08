import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';
import '../../../../core/utils/app_size.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/app_screen_background.dart';
import '../../../home/domain/entities/payment_transaction.dart';
import '../../../home/domain/repositories/home_repository.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  late Future<List<PaymentTransaction>> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = GetIt.instance<HomeRepository>().fetchPaymentTransactions();
  }

  Future<void> _refresh() async {
    setState(() {
      _transactions = GetIt.instance<HomeRepository>().fetchPaymentTransactions();
    });
    await _transactions;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ColorConstants.transparent,
        body: Stack(
          children: <Widget>[
            const AppScreenBackground(),
            SafeArea(
              child: Padding(
                padding: AppSize.insets(context, left: 16, right: 16, top: 8),
                child: Column(
                  children: <Widget>[
                    AppBackHeader(
                      title: 'Payment history',
                      onBack: () => context.pop(),
                    ),
                    SizedBox(height: AppSize.h(context, 14)),
                    Expanded(
                      child: FutureBuilder<List<PaymentTransaction>>(
                        future: _transactions,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return _HistoryMessage(
                              icon: Icons.receipt_long_outlined,
                              title: 'Unable to load payment history',
                              action: _refresh,
                            );
                          }
                          final transactions = snapshot.data ?? const <PaymentTransaction>[];
                          if (transactions.isEmpty) {
                            return const _HistoryMessage(
                              icon: Icons.receipt_long_outlined,
                              title: 'No payments yet',
                            );
                          }
                          return RefreshIndicator(
                            color: ColorConstants.brandBlue,
                            onRefresh: _refresh,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.only(bottom: AppSize.h(context, 24)),
                              itemCount: transactions.length,
                              separatorBuilder: (_, __) => SizedBox(height: AppSize.h(context, 10)),
                              itemBuilder: (_, index) => _TransactionCard(
                                transaction: transactions[index],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final PaymentTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final successful = transaction.isSuccessful;
    final statusColor = successful ? ColorConstants.green : ColorConstants.red;
    final amount = NumberFormat.currency(
      locale: 'en_IN',
      symbol: transaction.currency == 'INR' ? '₹' : '${transaction.currency} ',
      decimalDigits: transaction.amount % 1 == 0 ? 0 : 2,
    ).format(transaction.amount);
    final date = transaction.createdAt == null
        ? 'Date unavailable'
        : DateFormat('dd MMM yyyy • hh:mm a').format(transaction.createdAt!);

    return Container(
      padding: AppSize.insets(context, left: 14, right: 14, top: 14, bottom: 14),
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(AppSize.r(context, 14)),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: AppSize.r(context, 40),
            height: AppSize.r(context, 40),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              successful ? Icons.check_rounded : Icons.close_rounded,
              color: statusColor,
            ),
          ),
          SizedBox(width: AppSize.w(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  transaction.planName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyleConstants.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.ink,
                  ),
                ),
                SizedBox(height: AppSize.h(context, 3)),
                Text(date, style: TextStyleConstants.caption),
              ],
            ),
          ),
          SizedBox(width: AppSize.w(context, 8)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(amount, style: TextStyleConstants.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              SizedBox(height: AppSize.h(context, 3)),
              Text(
                _statusLabel(transaction.status),
                style: TextStyleConstants.caption.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.trim().toUpperCase()) {
      case 'CAPTURED':
      case 'CREATED':
        return 'Subscribed';
      default:
        return status.toUpperCase();
    }
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Future<void> Function()? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: AppSize.r(context, 38), color: ColorConstants.soft),
            SizedBox(height: AppSize.h(context, 10)),
            Text(title, style: TextStyleConstants.bodyMedium),
            if (action != null)
              TextButton(onPressed: action, child: const Text('Try again')),
          ],
        ),
      );
}
