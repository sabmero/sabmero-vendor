import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myOrdersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Orders',
          subtitle: 'Orders containing your products',
          actions: [
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(myOrdersProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: AsyncListView<OrderRow>(
            value: async,
            onRetry: () => ref.invalidate(myOrdersProvider),
            emptyText: 'No orders yet.',
            builder: (rows) => SingleChildScrollView(
              child: Column(
                children: rows.map(_orderCard).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _orderCard(OrderRow o) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: const Border(),
        title: Row(
          children: [
            Text('Order #${o.id}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(width: 12),
            StatusBadge(o.status),
            const SizedBox(width: 8),
            StatusBadge(o.paymentStatus),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${o.customerName} • Rs ${o.totalAmount.toStringAsFixed(0)} • ${o.paymentMethod} • ${o.createdAt.split('T').first}',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          _detailRow('Customer', o.customerName),
          if (o.customerPhone != null && o.customerPhone!.isNotEmpty)
            _detailRow('Phone', o.customerPhone!),
          if (o.customerEmail != null && o.customerEmail!.isNotEmpty)
            _detailRow('Email', o.customerEmail!),
          _detailRow('Delivery address', o.deliveryAddress),
          _detailRow('Payment', '${o.paymentMethod} • ${o.paymentStatus}'),
          if (o.promoCode != null && o.promoCode!.isNotEmpty)
            _detailRow('Promo', o.promoCode!),
          if (o.riderName != null && o.riderName!.isNotEmpty)
            _detailRow('Rider', o.riderName!),
          const Divider(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Items',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
          ),
          const SizedBox(height: 6),
          ...o.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                    Expanded(child: Text(it.productName)),
                    Text('x${it.quantity}'),
                    const SizedBox(width: 16),
                    Text('Rs ${it.lineTotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Rs ${o.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: AppColors.text, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
