import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/screens/product/details_product_screen.dart';
import 'package:root2route/screens/product/add_product_screen.dart';
import 'package:root2route/services/storage_service.dart';

class MainMarketTab extends StatefulWidget {
  final String? organizationId;
  final bool isGuestMode;

  const MainMarketTab({
    super.key,
    this.organizationId,
    this.isGuestMode = false,
  });

  @override
  State<MainMarketTab> createState() => _MainMarketTabState();
}

class _MainMarketTabState extends State<MainMarketTab> {
  final ApiService _api = ApiService();
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _api.getAllProducts();
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          final allProducts = result['data'] ?? [];
          _products =
              allProducts.where((p) {
                final isAvailableForDirectSale =
                    p['isAvailableForDirectSale'] == true ||
                    p['IsAvailableForDirectSale'] == true;
                return isAvailableForDirectSale;
              }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load products';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton:
          widget.isGuestMode
              ? null
              : Padding(
                padding: const EdgeInsets.only(bottom: 90.0),
                child: FloatingActionButton(
                  heroTag: "add_product_fab",
                  backgroundColor: AppColors.primary,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: AppColors.iconPrimary),
                  onPressed: () {
                    if (widget.organizationId != null &&
                        widget.organizationId!.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AddProductScreen(
                                organizationId: widget.organizationId!,
                              ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Loading organization data, please wait...",
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchProducts,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No products available currently',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchProducts,
      child: GridView.builder(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 100,
          top: 16,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.48,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(context, product);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product) {
    final String name = product['name'] ?? product['Name'] ?? 'Unknown Product';
    final dynamic stockRaw =
        product['stockQuantity'] ?? product['StockQuantity'] ?? 0;
    final int stockQty =
        stockRaw is num
            ? stockRaw.toInt()
            : int.tryParse(stockRaw.toString()) ?? 0;

    final dynamic unitRaw = product['weightUnit'] ?? product['WeightUnit'];
    String unitName = '';
    if (unitRaw != null) {
      if (unitRaw is String) {
        unitName = unitRaw;
      } else {
        final idx = int.tryParse(unitRaw.toString()) ?? 0;
        switch (idx) {
          case 0:
            unitName = 'Kg';
            break;
          case 1:
            unitName = 'pkg';
            break;
          case 2:
            unitName = 'Liter';
            break;
        }
      }
    }

    final dynamic typeRaw = product['productType'] ?? product['ProductType'];
    String typeStr = 'Crop';
    if (typeRaw != null) {
      if (typeRaw is String) {
        typeStr = typeRaw;
      } else {
        final idx = int.tryParse(typeRaw.toString()) ?? 0;
        switch (idx) {
          case 0:
            typeStr = 'Crop';
            break;
          case 1:
            typeStr = 'Processed';
            break;
          case 2:
            typeStr = 'Tool';
            break;
          case 3:
            typeStr = 'Chemical';
            break;
      }
    }
  }
    final String productOrgId =
        product['organizationId']?.toString() ??
        product['OrganizationId']?.toString() ??
        '';
    final String? currentUserOrgId = StorageService().currentUserOrgId;
    final bool isMyProduct =
        !StorageService().isGuest &&
        currentUserOrgId != null &&
        currentUserOrgId.isNotEmpty &&
        currentUserOrgId == productOrgId;

    final String? sellerName = product['organizationName'] ??
        product['OrganizationName'] ??
        product['sellerName'] ??
        product['seller']?.toString();

    final isAvailableForDirectSale =
        product['isAvailableForDirectSale'] == true ||
        product['IsAvailableForDirectSale'] == true;
    final isAvailableForAuction =
        product['isAvailableForAuction'] == true ||
        product['IsAvailableForAuction'] == true;

    double displayPrice = 0.0;
    if (isAvailableForDirectSale) {
      final rawPrice =
          product['directSalePrice'] ?? product['DirectSalePrice'] ?? 0;
      displayPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    } else if (isAvailableForAuction) {
      final rawPrice =
          product['startBiddingPrice'] ?? product['StartBiddingPrice'] ?? 0;
      displayPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    } else {
      final rawPrice =
          product['directSalePrice'] ?? product['DirectSalePrice'] ?? 0;
      displayPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    }

    String formatPrice(double price) {
      final String str = price.toStringAsFixed(0);
      if (str.length <= 3) return str;
      final StringBuffer sb = StringBuffer();
      int count = 0;
      for (int i = str.length - 1; i >= 0; i--) {
        sb.write(str[i]);
        count++;
        if (count % 3 == 0 && i != 0) {
          sb.write(',');
        }
      }
      return sb.toString().split('').reversed.join();
    }

    String? imageUrl;
    final images = product['images'] ?? product['Images'];
    if (images != null && images is List && images.isNotEmpty) {
      imageUrl = images[0]?.toString();
    }

    final displayUrl =
        (imageUrl != null && imageUrl.startsWith('/'))
            ? 'https://root2route.runasp.net$imageUrl'
            : imageUrl;

    return InkWell(
      onTap: () {
        final String? id =
            product['id']?.toString() ?? product['Id']?.toString();
        if (id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsProductScreen(productId: id),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 11,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFFF8F9FB),
                      child:
                          displayUrl != null && displayUrl.isNotEmpty
                              ? Image.network(
                                displayUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (ctx, err, stack) => const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                              )
                              : const Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: Colors.grey,
                              ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9), // Badge Background
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeStr,
                        style: TextStyle(
                          color: const Color(0xFF1B7A35), // Primary Green
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 12,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        color: const Color(0xFF1A202C), // Primary Text
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          size: 14.sp,
                          color: const Color(0xFF1B7A35), // Primary Green
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Stock: $stockQty ${unitName.isNotEmpty ? unitName : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF718096), // Secondary Text
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatPrice(displayPrice)} EGP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: const Color(0xFF1A202C), // Primary Text
                      ),
                    ),
                    if (isMyProduct || (sellerName != null && sellerName.trim().isNotEmpty)) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isMyProduct ? Icons.verified_user : Icons.storefront_outlined,
                            size: 14,
                            color: isMyProduct ? const Color(0xFF1B7A35) : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isMyProduct ? 'Your Product' : sellerName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isMyProduct ? 12.sp : 11.sp,
                                fontWeight: isMyProduct ? FontWeight.bold : FontWeight.normal,
                                color: isMyProduct ? const Color(0xFF1B7A35) : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B7A35), // Primary Green
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
