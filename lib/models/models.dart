// Null-tolerant models for the vendor panel.

T? _as<T>(dynamic v) => v is T ? v : null;
int _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
double _dbl(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
bool _bool(dynamic v) => v == true;
String _str(dynamic v) => v?.toString() ?? '';

// Gallery images: prefer the imagePaths list, fall back to the single cover.
List<String> _imageList(dynamic list, dynamic cover) {
  if (list is List) {
    final l = list.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    if (l.isNotEmpty) return l;
  }
  final c = cover?.toString() ?? '';
  return c.isEmpty ? <String>[] : <String>[c];
}

class VendorProfile {
  final int id, userId, productCount;
  final String ownerName, phone, businessName, businessAddress;
  final bool isApproved;
  final double commissionRate;
  final String createdAt;

  VendorProfile.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        userId = _int(j['userId']),
        productCount = _int(j['productCount']),
        ownerName = _str(j['ownerName']),
        phone = _str(j['phone']),
        businessName = _str(j['businessName']),
        businessAddress = _str(j['businessAddress']),
        isApproved = _bool(j['isApproved']),
        commissionRate = _dbl(j['commissionRate']),
        createdAt = _str(j['createdAt']);
}

class Product {
  final int id, vendorId, categoryId, stock, reviewCount;
  final int warrantyMonths; // 0 = no warranty
  final String name, description, categoryName, vendorName;
  final String? imagePath, sizeOptions, colorOptions, unit, warrantyTerms;
  final List<String> imagePaths;
  final double price, averageRating;
  final double? oldPrice;
  final bool isActive;
  final String createdAt;

  Product.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        vendorId = _int(j['vendorId']),
        categoryId = _int(j['categoryId']),
        stock = _int(j['stock']),
        reviewCount = _int(j['reviewCount']),
        warrantyMonths = _int(j['warrantyMonths']),
        warrantyTerms = _as<String>(j['warrantyTerms']),
        name = _str(j['name']),
        description = _str(j['description']),
        categoryName = _str(j['categoryName']),
        vendorName = _str(j['vendorName']),
        imagePath = _as<String>(j['imagePath']),
        sizeOptions = _as<String>(j['sizeOptions']),
        colorOptions = _as<String>(j['colorOptions']),
        unit = _as<String>(j['unit']),
        imagePaths = _imageList(j['imagePaths'], j['imagePath']),
        price = _dbl(j['price']),
        oldPrice = j['oldPrice'] == null ? null : _dbl(j['oldPrice']),
        averageRating = _dbl(j['averageRating']),
        isActive = _bool(j['isActive']),
        createdAt = _str(j['createdAt']);
}

class CategoryRow {
  final int id;
  final String name;
  final bool isActive;
  CategoryRow.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        name = _str(j['name']),
        isActive = _bool(j['isActive']);
}

class OrderItemRow {
  final String productName;
  final int quantity;
  final double unitPrice, lineTotal;
  OrderItemRow.fromJson(Map<String, dynamic> j)
      : productName = _str(j['productName']),
        quantity = _int(j['quantity']),
        unitPrice = _dbl(j['unitPrice']),
        lineTotal = _dbl(j['lineTotal']);
}

class OrderRow {
  final int id;
  final String customerName, paymentMethod, paymentStatus, status, deliveryAddress, createdAt;
  final String? customerPhone, customerEmail, promoCode, paymentScreenshotPath, riderName;
  final double totalAmount, subTotal, discount;
  final List<OrderItemRow> items;

  OrderRow.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        customerName = _str(j['customerName']),
        customerPhone = _as<String>(j['customerPhone']),
        customerEmail = _as<String>(j['customerEmail']),
        paymentMethod = _str(j['paymentMethod']),
        paymentStatus = _str(j['paymentStatus']),
        paymentScreenshotPath = _as<String>(j['paymentScreenshotPath']),
        status = _str(j['status']),
        deliveryAddress = _str(j['deliveryAddress']),
        promoCode = _as<String>(j['promoCode']),
        riderName = _as<String>(j['riderName']),
        createdAt = _str(j['createdAt']),
        totalAmount = _dbl(j['totalAmount']),
        subTotal = _dbl(j['subTotal']),
        discount = _dbl(j['discount']),
        items = (j['items'] is List)
            ? (j['items'] as List)
                .whereType<Map<String, dynamic>>()
                .map(OrderItemRow.fromJson)
                .toList()
            : const [];
}

// Pending payment awaiting vendor verification. The backend shape may vary;
// these fields are read defensively.
class PendingPayment {
  final int id;
  final String reference, method, status, createdAt;
  final String type; // "Order" | "Booking"
  final double amount;
  final String? screenshotPath, customerName;

  PendingPayment.fromJson(Map<String, dynamic> j)
      : id = _int(j['id'] ?? j['orderId'] ?? j['bookingId']),
        reference = _str(j['reference'] ?? j['orderId'] ?? j['bookingId'] ?? j['id']),
        method = _str(j['paymentMethod'] ?? j['method']),
        status = _str(j['paymentStatus'] ?? j['status']),
        createdAt = _str(j['createdAt']),
        type = _str(j['type']).isNotEmpty
            ? _str(j['type'])
            : (j['bookingId'] != null ? 'Booking' : 'Order'),
        amount = _dbl(j['amount'] ?? j['totalAmount']),
        screenshotPath = _as<String>(j['paymentScreenshotPath'] ?? j['screenshotPath']),
        customerName = _as<String>(j['customerName']);
}

// Current user's KYC status, from GET /api/Auth/kyc-status.
class KycStatus {
  final String status;            // "NotSubmitted" | "Pending" | "Approved" | "Rejected"
  final String? rejectionReason;  // set only when Rejected
  final String? documentPath;
  final bool isVerified;

  KycStatus.fromJson(Map<String, dynamic> j)
      : status = (_str(j['status']).isEmpty ? 'NotSubmitted' : _str(j['status'])),
        rejectionReason = _as<String>(j['rejectionReason']),
        documentPath = _as<String>(j['documentPath']),
        isVerified = _bool(j['isVerified']);
}
