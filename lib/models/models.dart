// Null-tolerant models for the vendor panel.

T? _as<T>(dynamic v) => v is T ? v : null;
int _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
double _dbl(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
bool _bool(dynamic v) => v == true;
String _str(dynamic v) => v?.toString() ?? '';

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
  final String name, description, categoryName, vendorName;
  final String? imagePath, sizeOptions, colorOptions, unit;
  final double price, averageRating;
  final bool isActive;
  final String createdAt;

  Product.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        vendorId = _int(j['vendorId']),
        categoryId = _int(j['categoryId']),
        stock = _int(j['stock']),
        reviewCount = _int(j['reviewCount']),
        name = _str(j['name']),
        description = _str(j['description']),
        categoryName = _str(j['categoryName']),
        vendorName = _str(j['vendorName']),
        imagePath = _as<String>(j['imagePath']),
        sizeOptions = _as<String>(j['sizeOptions']),
        colorOptions = _as<String>(j['colorOptions']),
        unit = _as<String>(j['unit']),
        price = _dbl(j['price']),
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
  final double totalAmount;
  final List<OrderItemRow> items;

  OrderRow.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        customerName = _str(j['customerName']),
        paymentMethod = _str(j['paymentMethod']),
        paymentStatus = _str(j['paymentStatus']),
        status = _str(j['status']),
        deliveryAddress = _str(j['deliveryAddress']),
        createdAt = _str(j['createdAt']),
        totalAmount = _dbl(j['totalAmount']),
        items = ((j['items'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(OrderItemRow.fromJson)
            .toList();
}

// Pending payment awaiting vendor verification. The backend shape may vary;
// these fields are read defensively.
class PendingPayment {
  final int id;
  final String reference, method, status, createdAt;
  final double amount;
  final String? screenshotPath, customerName;

  PendingPayment.fromJson(Map<String, dynamic> j)
      : id = _int(j['id'] ?? j['orderId'] ?? j['bookingId']),
        reference = _str(j['reference'] ?? j['orderId'] ?? j['bookingId'] ?? j['id']),
        method = _str(j['paymentMethod'] ?? j['method']),
        status = _str(j['paymentStatus'] ?? j['status']),
        createdAt = _str(j['createdAt']),
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
