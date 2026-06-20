import 'package:quickalert/quickalert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/auctions/ui/my_auctions_screen.dart';
import 'package:root2route/features/products/ui/edit_product_screen.dart';
import 'package:root2route/core/services/api.dart';
import 'package:root2route/features/auctions/ui/create_auction_screen.dart';
import 'package:root2route/core/services/storage_service.dart';
import 'package:root2route/features/auth/ui/login_screen.dart';
import 'package:root2route/core/utils/price_formatter.dart';
import 'package:root2route/core/utils/snackbar_helper.dart';
import 'package:root2route/core/utils/image_utils.dart';
class MyProductsScreen extends StatefulWidget {
  final String organizationId;

  const MyProductsScreen({super.key, required this.organizationId});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final _api = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _products = [];

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

    String targetOrgId = widget.organizationId;

    // If no organizationId is passed, attempt to fetch the user's organizations
    if (targetOrgId.isEmpty) {
      try {
        final orgsRes = await _api.getMyOrganizations();
        if (orgsRes['success'] == true && orgsRes['data'] != null) {
          final List orgs = orgsRes['data'] is List ? orgsRes['data'] : [];
          if (orgs.isNotEmpty) {
            targetOrgId =
                orgs[0]['id']?.toString() ?? orgs[0]['Id']?.toString() ?? '';
          }
        }
      } catch (e) {
        // We'll let it fail down below or just show an error
        debugPrint('Failed to fetch user organizations: $e');
      }
    }

    if (targetOrgId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'لم يتم العثور على شركة. يرجى إنشاء واحدة لإدارة المنتجات.';
        _isLoading = false;
      });
      return;
    }

    final res = await _api.getOrganizationProducts(targetOrgId);
    if (!mounted) return;

    if (res['success'] == true) {
      if (res['data'] is List) {
        setState(() {
          _products = res['data'] as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'تنسيق بيانات غير صالح من الخادم.';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'فشل تحميل المنتجات';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'حذف المنتج؟',
      text:
          'هل أنت متأكد من رغبتك في حذف هذا المنتج؟ لا يمكن التراجع عن هذا الإجراء.',
      barrierDismissible: false,
      confirmBtnText: 'حذف',
      cancelBtnText: 'إلغاء',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () {
        Navigator.of(context, rootNavigator: true).pop(true);
      },
      onCancelBtnTap: () {
        Navigator.of(context, rootNavigator: true).pop(false);
      },
    );

    if (confirm == true) {
      QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
        context: context,
        type: QuickAlertType.loading,
        title: 'جاري الحذف...',
        text: 'جاري إزالة المنتج من مخزونك.',
        barrierDismissible: false,
      );

      final navigator = Navigator.of(context, rootNavigator: true);

      try {
        final res = await _api.deleteProduct(id);

        // Always dismiss the loading alert first
        navigator.pop();

        if (!mounted) return;

        if (res['success'] == true) {
          QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.success, title: 'نجاح', text: 'تم حذف المنتج بنجاح.');
          if (!mounted) return;
          _fetchProducts();
        } else {
          QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
            context: context,
            type: QuickAlertType.error,
            title: 'فشل الحذف',
            text: res['message'] ?? 'فشل في حذف المنتج.',
            barrierDismissible: false,
          );
        }
      } catch (e) {
        // Ensure loading alert is dismissed even on error
        try {
          navigator.pop();
        } catch (_) {}

        if (!mounted) return;
        QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
          context: context,
          type: QuickAlertType.error,
          title: 'خطأ',
          text: e.toString(),
          barrierDismissible: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (StorageService().isGuest) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'يرجى تسجيل الدخول وإنشاء شركة لعرض هذه الصفحة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ── Manage My Auctions Banner ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text(
                            'مزاداتي',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                        ),
                        body: const MyAuctionsScreen(),
                      ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1B5E20)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إدارة مزاداتي',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        Text(
                          'عرض المزادات القادمة والنشطة والمنتهية',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        // ── Products List ─────────────────────────────────────────────────
        Expanded(child: _buildProductsContent()),
      ],
    );
  }

  Widget _buildProductsContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18.sp),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
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
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد منتجات.',
              style: TextStyle(
                fontSize: 20.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف منتجك الأول للبدء.',
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchProducts,
      color: AppColors.primary,
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
        itemCount: _products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16.h,
          crossAxisSpacing: 16.w,
          childAspectRatio: 0.52,
        ),
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    if (product is! Map) return const SizedBox();

    final id = product['id'] ?? product['Id'] ?? '';
    final name = product['name'] ?? product['Name'] ?? 'غير معروف';

    final isAvailableForDirectSale =
        product['isAvailableForDirectSale'] == true ||
        product['IsAvailableForDirectSale'] == true;
    final isAvailableForAuction =
        product['isAvailableForAuction'] == true ||
        product['IsAvailableForAuction'] == true;

    double displayPrice = 0.0;
    bool showAuctionOnlyBadge = false;

    if (isAvailableForDirectSale) {
      final rawPrice =
          product['directSalePrice'] ?? product['DirectSalePrice'] ?? 0;
      displayPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    } else if (isAvailableForAuction) {
      final rawPrice =
          product['startBiddingPrice'] ?? product['StartBiddingPrice'] ?? 0;
      displayPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
      showAuctionOnlyBadge = true;
    } else {
      final rawPrice =
          product['directSalePrice'] ?? product['DirectSalePrice'] ?? 0;
      displayPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    }

    final stockQuantity =
        product['stockQuantity'] ?? product['StockQuantity'] ?? 0;
    final dynamic unitRaw = product['weightUnit'] ?? product['WeightUnit'];
    String unitString = '';
    if (unitRaw is String) {
      final Map<String, String> _unitMap = {
        'Kg': 'كجم',
        'Kilogram': 'كجم',
        'Liter': 'لتر',
        'pkg': 'عبوة',
        'Package': 'عبوة',
      };
      unitString = _unitMap[unitRaw] ?? unitRaw;
    } else {
      unitString = _getWeightUnitString(unitRaw);
    }
    final stockText =
        unitString.isNotEmpty
            ? 'متاح $stockQuantity $unitString'
            : 'متاح $stockQuantity';

    // Safely extract first image URL
    final imagesList = product['images'] ?? product['Images'];
    String? imageUrl;
    if (imagesList is List && imagesList.isNotEmpty) {
      imageUrl = imagesList.first?.toString();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child:
                      imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                            imageUrl.fullImageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                          : _buildPlaceholder(),
                ),
                if (showAuctionOnlyBadge)
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'مزاد فقط',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info Area
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                SizedBox(height: 4.h),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${PriceFormatter.format(displayPrice)} جنيه',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 14.w,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        stockText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => EditProductScreen(
                                  product: Map<String, dynamic>.from(product),
                                ),
                          ),
                        );
                        if (result == true) _fetchProducts();
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18.w,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'تعديل',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          CreateAuctionScreen.id,
                          arguments: {'id': id, 'name': name},
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.gavel_rounded,
                              size: 16.w,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'مزاد',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _deleteProduct(id),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 18.w,
                              color: Colors.red.shade700,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'حذف',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Theme.of(context).colorScheme.outline,
        size: 40,
      ),
    );
  }

  String _getWeightUnitString(dynamic unitIndex) {
    if (unitIndex == null) return '';
    final idx = int.tryParse(unitIndex.toString());
    if (idx == null) {
      return unitIndex.toString();
    }
    switch (idx) {
      case 0:
        return 'كجم';
      case 1:
        return 'عبوة';
      case 2:
        return 'لتر';
      default:
        return '';
    }
  }
}
