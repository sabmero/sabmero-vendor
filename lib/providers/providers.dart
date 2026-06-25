import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/token_store.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/vendor_service.dart';

final authServiceProvider = Provider((_) => AuthService());
final vendorServiceProvider = Provider((_) => VendorService());

final authStateProvider = FutureProvider<bool>((ref) async {
  final token = await TokenStore.token();
  return token != null && token.isNotEmpty;
});

final vendorNameProvider = FutureProvider<String>((ref) async {
  return (await TokenStore.name()) ?? 'Vendor';
});

final myProfileProvider = FutureProvider<VendorProfile?>(
  (ref) => ref.read(vendorServiceProvider).myProfile(),
);

final myProductsProvider = FutureProvider<List<Product>>(
  (ref) => ref.read(vendorServiceProvider).myProducts(),
);

final categoriesProvider = FutureProvider<List<CategoryRow>>(
  (ref) => ref.read(vendorServiceProvider).categories(),
);

final myOrdersProvider = FutureProvider<List<OrderRow>>(
  (ref) => ref.read(vendorServiceProvider).myOrders(),
);

final pendingPaymentsProvider = FutureProvider<List<PendingPayment>>(
  (ref) => ref.read(vendorServiceProvider).pendingPayments(),
);

final kycStatusProvider = FutureProvider<KycStatus?>(
  (ref) => ref.read(vendorServiceProvider).kycStatus(),
);
