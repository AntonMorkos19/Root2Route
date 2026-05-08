import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/product/my_products_screen.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/screens/product/details_product_screen.dart';
import 'package:root2route/screens/auction/public_auctions_screen.dart';
import 'package:root2route/screens/product/add_product_screen.dart';
import 'package:root2route/services/storage_service.dart';

class MarketScreen extends StatefulWidget {
  final String? organizationId;

  const MarketScreen({super.key, this.organizationId});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  @override
  Widget build(BuildContext context) {
    const int tabLength = 3;

    return DefaultTabController(
      length: tabLength,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          title: const Text(
            'Marketplace',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: 'Market', icon: Icon(Icons.storefront)),
              Tab(text: 'My store', icon: Icon(Icons.inventory_2_outlined)),
              Tab(text: 'Auctions', icon: Icon(Icons.gavel)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MainMarketTab(organizationId: widget.organizationId),
            MyProductsScreen(organizationId: widget.organizationId ?? ''),
            const PublicAuctionsScreen(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// التبويب الخاص بالسوق الأساسي (وفيه الـ FAB بتاع إضافة منتج)
// ---------------------------------------------------------------------
class _MainMarketTab extends StatefulWidget {
  final String? organizationId;
  const _MainMarketTab({this.organizationId});

  @override
  State<_MainMarketTab> createState() => _MainMarketTabState();
}

class _MainMarketTabState extends State<_MainMarketTab> {
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
          _products = allProducts.where((p) {
            final isAvailableForDirectSale = p['isAvailableForDirectSale'] == true || p['IsAvailableForDirectSale'] == true;
            return isAvailableForDirectSale;
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'فشل تحميل المنتجات';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // عشان ياخد لون الخلفية الأصلي
      // هنا رفعنا الزرار 90 بيكسل عشان يكون فوق الـ BottomNavigationBar
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          heroTag: "add_product_fab",
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.add,
            color: AppColors.iconPrimary,
          ), // أيقونة الـ Add
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
                  content: Text("جاري تحميل بيانات المنظمة، انتظر قليلاً"),
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
                    borderRadius: BorderRadius.circular(12),
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
          childAspectRatio: 0.68,
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
    final String productOrgId = product['organizationId']?.toString() ?? product['OrganizationId']?.toString() ?? '';
    final String? currentUserOrgId = StorageService().currentUserOrgId;
    final bool isMyProduct = !StorageService().isGuest && currentUserOrgId != null && currentUserOrgId.isNotEmpty && currentUserOrgId == productOrgId;

    final isAvailableForDirectSale = product['isAvailableForDirectSale'] == true || product['IsAvailableForDirectSale'] == true;
    final isAvailableForAuction = product['isAvailableForAuction'] == true || product['IsAvailableForAuction'] == true;

    double displayPrice = 0.0;
    bool showAuctionOnlyBadge = false;

    if (isAvailableForDirectSale) {
      final rawPrice = product['directSalePrice'] ?? product['DirectSalePrice'] ?? 0;
      displayPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    } else if (isAvailableForAuction) {
      final rawPrice = product['startBiddingPrice'] ?? product['StartBiddingPrice'] ?? 0;
      displayPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
      showAuctionOnlyBadge = true;
    } else {
      final rawPrice = product['directSalePrice'] ?? product['DirectSalePrice'] ?? 0;
      displayPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
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
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${displayPrice.toStringAsFixed(0)} EGP',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (showAuctionOnlyBadge) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Auction Only',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isMyProduct)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'Your Product',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          )
                        else if (isAvailableForDirectSale)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                      ],
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
