import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/core/services/api.dart';
import 'package:root2route/features/products/ui/details_product_screen.dart';
import 'package:root2route/features/products/ui/add_product_screen.dart';
import 'package:root2route/core/services/storage_service.dart';
import 'package:root2route/core/utils/price_formatter.dart';
import 'package:root2route/core/utils/image_utils.dart';

class MainMarketTab extends StatefulWidget {
  final String? organizationId;
  final bool isGuestMode;
  final bool canSell;

  const MainMarketTab({
    super.key,
    this.organizationId,
    this.isGuestMode = false,
    this.canSell = true,
  });

  @override
  State<MainMarketTab> createState() => _MainMarketTabState();
}

class _MainMarketTabState extends State<MainMarketTab> {
  final ApiService _api = ApiService();
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _pageNumber = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // static const int _approvedStatus = 0; // تم إيقافها مؤقتاً عشان متبوظش الفلتر

  @override
  void initState() {
    super.initState();
    _fetchProducts(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchProducts();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
      });
      _fetchProducts(isRefresh: true);
    });
  }

  Future<void> _fetchProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _pageNumber = 1;
        _hasMore = true;
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      if (_isLoading || _isFetchingMore || !_hasMore) return;
      setState(() {
        _isFetchingMore = true;
      });
    }

    try {
      final result = await _api.getAllProducts(
        pageNumber: _pageNumber,
        pageSize: _pageSize,
        // تم إيقاف فلتر الـ status عشان نعرض اللي موجود في الداتابيز
        // status: _approvedStatus,

        // 🚀 تم إرجاع النوع 0 ليعرض المحاصيل زي تجربة الـ Postman/Swagger
        productType: 0,

        search: _searchQuery,
      );
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          final fetchedProducts = result['data'] ?? [];

          final filteredProducts =
              fetchedProducts.where((p) {
                final isAvailableForDirectSale =
                    p['isAvailableForDirectSale'] == true ||
                    p['IsAvailableForDirectSale'] == true;
                return isAvailableForDirectSale;
              }).toList();

          if (_pageNumber == 1) {
            _products = filteredProducts;
          } else {
            _products.addAll(filteredProducts);
          }

          if (fetchedProducts.length < _pageSize) {
            _hasMore = false;
          } else {
            _pageNumber++;
          }

          _isLoading = false;
          _isFetchingMore = false;
        });
      } else {
        setState(() {
          if (_pageNumber == 1) {
            _errorMessage = result['message'] ?? 'فشل في تحميل المنتجات';
          }
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_pageNumber == 1) {
          _errorMessage = 'حدث خطأ غير متوقع: $e';
        }
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton:
            (widget.isGuestMode || !widget.canSell)
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
                              "جاري تحميل بيانات الشركة، يرجى الانتظار...",
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [_buildSearchBar(), Expanded(child: _buildContent())],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'ابحث عن منتجات...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                  : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
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
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchProducts(isRefresh: true),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'إعادة المحاولة',
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
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _fetchProducts(isRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد منتجات متاحة حالياً',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _fetchProducts(isRefresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16,
              top: 8,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.48,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = _products[index];
                return _buildProductCard(context, product);
              }, childCount: _products.length),
            ),
          ),
          if (_hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 100.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product) {
    final String name = product['name'] ?? product['Name'] ?? 'منتج غير معروف';
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
        final Map<String, String> _unitMap = {
          'Kg': 'كجم',
          'Kilogram': 'كجم',
          'Liter': 'لتر',
          'pkg': 'عبوة',
          'Package': 'عبوة',
        };
        unitName = _unitMap[unitRaw] ?? unitRaw;
      } else {
        final idx = int.tryParse(unitRaw.toString()) ?? 0;
        switch (idx) {
          case 0:
            unitName = 'كجم';
            break;
          case 1:
            unitName = 'عبوة';
            break;
          case 2:
            unitName = 'لتر';
            break;
        }
      }
    }

    final dynamic typeRaw = product['productType'] ?? product['ProductType'];
    String typeStr = 'محصول';
    if (typeRaw != null) {
      if (typeRaw is String) {
        final Map<String, String> _typeMap = {
          'RawCrop': 'محصول',
          'Processed': 'مصنع',
          'Tool': 'أداة',
          'Chemical': 'كيماويات',
        };
        typeStr = _typeMap[typeRaw] ?? typeRaw;
      } else {
        final idx = int.tryParse(typeRaw.toString()) ?? 0;
        switch (idx) {
          case 0:
            typeStr = 'محصول';
            break;
          case 1:
            typeStr = 'مصنع';
            break;
          case 2:
            typeStr = 'أداة';
            break;
          case 3:
            typeStr = 'كيماويات';
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

    final String? sellerName =
        product['organizationName'] ??
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

    String? imageUrl;
    final images = product['images'] ?? product['Images'];
    if (images != null && images is List && images.isNotEmpty) {
      imageUrl = images[0]?.toString();
    }

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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child:
                          imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                imageUrl.fullImageUrl,
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
                        color: Theme.of(context).textTheme.titleMedium?.color,
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
                            'المخزون: $stockQty ${unitName.isNotEmpty ? unitName : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${PriceFormatter.format(displayPrice)} جنيه',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    if (isMyProduct ||
                        (sellerName != null &&
                            sellerName.trim().isNotEmpty)) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isMyProduct
                                ? Icons.verified_user
                                : Icons.storefront_outlined,
                            size: 14,
                            color:
                                isMyProduct
                                    ? const Color(0xFF1B7A35)
                                    : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isMyProduct ? 'منتجك' : sellerName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isMyProduct ? 12.sp : 11.sp,
                                fontWeight:
                                    isMyProduct
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    isMyProduct
                                        ? const Color(0xFF1B7A35)
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
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
                        'عرض التفاصيل',
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
