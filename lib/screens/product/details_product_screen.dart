import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/services/api.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/screens/order/cart_screen.dart';
import 'package:root2route/services/cart_service.dart';
import 'package:root2route/services/chat_service.dart';
import 'package:root2route/screens/chat/chat_details_screen.dart';
import 'package:root2route/features/chat/cubit/chat_messages_cubit.dart';
import 'package:root2route/features/cart/cubit/cart_cubit.dart';
import 'package:root2route/features/cart/cubit/cart_state.dart';

class DetailsProductScreen extends StatefulWidget {
  final String productId;

  const DetailsProductScreen({super.key, required this.productId});

  @override
  State<DetailsProductScreen> createState() => _DetailsProductScreenState();
}

class _DetailsProductScreenState extends State<DetailsProductScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _productData;
  int _cartCount = 0;

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _api.getProductById(widget.productId);
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _productData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          String msg = result['message'] ?? '';
          _errorMessage =
              msg.trim().isEmpty
                  ? 'فشل تحميل بيانات المنتج. لم يرسل الخادم تفاصيل الخطأ.'
                  : msg;

          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع: $e';
        _isLoading = false;
      });
    }
  }

  String _getProductTypeString(dynamic typeIndex) {
    if (typeIndex == null) return 'منتج';
    final idx = int.tryParse(typeIndex.toString()) ?? 0;
    switch (idx) {
      case 0:
        return 'محصول';
      case 1:
        return 'مصنع';
      case 2:
        return 'أداة';
      case 3:
        return 'كيماويات';
      default:
        return '';
    }
  }

  String _getWeightUnitString(dynamic unitIndex) {
    if (unitIndex == null) return '';
    final idx = int.tryParse(unitIndex.toString()) ?? 0;
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(top: 10, right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.black26,
              child: IconButton(
                padding: const EdgeInsets.only(
                  right: 2,
                ), // slightly adjust chevron alignment
                icon: Icon(
                  Icons.arrow_back_ios_rounded, // ده هيبص يمين في العربي
                  color: Colors.white,
                  size: 16,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 16),
              child: BlocBuilder<CartCubit, CartState>(
                builder: (context, state) {
                  final cartCount = state.cartItems.length;
                  return Stack(
                    alignment: Alignment.topRight,
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black26,
                        child: IconButton(
                          icon: const Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                          ),
                          onPressed:
                              () => Navigator.pushNamed(context, CartScreen.id),
                        ),
                      ),
                      if (cartCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                "$cartCount",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _productData != null ? _buildBottomBar() : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null || _productData == null) {
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
                _errorMessage ?? 'المنتج غير موجود.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProductDetails,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _productData!;
    final String name = data['name'] ?? data['Name'] ?? 'منتج غير معروف';
    final bool isAvailableForDirectSale =
        data['isAvailableForDirectSale'] == true ||
        data['IsAvailableForDirectSale'] == true;
    final bool isAvailableForAuction =
        data['isAvailableForAuction'] == true ||
        data['IsAvailableForAuction'] == true;

    double price = 0.0;
    bool showAuctionBadge = false;
    if (isAvailableForDirectSale) {
      final dynamic priceRaw =
          data['directSalePrice'] ?? data['DirectSalePrice'] ?? 0;
      price =
          priceRaw is num
              ? priceRaw.toDouble()
              : double.tryParse(priceRaw.toString()) ?? 0.0;
    } else if (isAvailableForAuction) {
      final dynamic priceRaw =
          data['startBiddingPrice'] ?? data['StartBiddingPrice'] ?? 0;
      price =
          priceRaw is num
              ? priceRaw.toDouble()
              : double.tryParse(priceRaw.toString()) ?? 0.0;
      showAuctionBadge = true;
    } else {
      final dynamic priceRaw =
          data['directSalePrice'] ?? data['DirectSalePrice'] ?? 0;
      price =
          priceRaw is num
              ? priceRaw.toDouble()
              : double.tryParse(priceRaw.toString()) ?? 0.0;
    }
    final String description =
        data['description'] ?? data['Description'] ?? 'لا يوجد وصف متاح.';
    final dynamic stockRaw =
        data['stockQuantity'] ?? data['StockQuantity'] ?? 0;
    final int quantity =
        stockRaw is num
            ? stockRaw.toInt()
            : int.tryParse(stockRaw.toString()) ?? 0;
    final dynamic typeRaw = data['productType'] ?? data['ProductType'];
    String typeStr = '';
    if (typeRaw is String) {
      final Map<String, String> _typeMap = {
        'RawCrop': 'محصول',
        'Processed': 'مصنع',
        'Tool': 'أداة',
        'Chemical': 'كيماويات',
      };
      typeStr = _typeMap[typeRaw] ?? typeRaw;
    } else {
      typeStr = _getProductTypeString(typeRaw);
    }

    final dynamic unitRaw = data['weightUnit'] ?? data['WeightUnit'];
    String unitStr = '';
    if (unitRaw is String) {
      final Map<String, String> _unitMap = {
        'Kg': 'كجم',
        'Kilogram': 'كجم',
        'Liter': 'لتر',
        'pkg': 'عبوة',
      };
      unitStr = _unitMap[unitRaw] ?? unitRaw;
    } else {
      unitStr = _getWeightUnitString(unitRaw);
    }

    // Extract image list
    final images = data['images'] ?? data['Images'];
    final List<dynamic> imagesList = (images is List) ? images : [];

    return Stack(
      children: [
        /// IMAGE SLIDER
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.45,
          child:
              imagesList.isNotEmpty
                  ? Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      PageView.builder(
                        itemCount: imagesList.length,
                        onPageChanged:
                            (index) =>
                                setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          String? imgUrl;
                          if (imagesList[index] is Map) {
                            imgUrl =
                                imagesList[index]['url'] ??
                                imagesList[index]['Url'];
                          } else {
                            imgUrl = imagesList[index].toString();
                          }

                          final displayUrl =
                              (imgUrl != null && imgUrl.startsWith('/'))
                                  ? 'https://root2route.runasp.net$imgUrl'
                                  : imgUrl;

                          return Image.network(
                            displayUrl ?? '',
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder:
                                (ctx, err, stack) => _buildPlaceholderImage(),
                          );
                        },
                      ),
                      // Indicators
                      if (imagesList.length > 1)
                        Positioned(
                          bottom: 60,
                          child: Row(
                            children: List.generate(imagesList.length, (index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      _currentImageIndex == index
                                          ? AppColors.primary
                                          : Colors.white70,
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  )
                  : _buildPlaceholderImage(),
        ),

        /// DETAILS CARD
        Positioned.fill(
          top: MediaQuery.of(context).size.height * 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${price.toStringAsFixed(0)} جنيه',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          if (showAuctionBadge) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'مزاد فقط',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        icon: Icons.category_rounded,
                        label: typeStr,
                        color: Colors.blue.shade50,
                        textColor: Colors.blue.shade700,
                      ),
                      _buildChip(
                        icon: Icons.inventory_2_rounded,
                        label: '$quantity في المخزن',
                        color: Colors.orange.shade50,
                        textColor: Colors.orange.shade800,
                      ),
                      if (unitStr.isNotEmpty && unitStr != '0')
                        _buildChip(
                          icon: Icons.scale_rounded,
                          label: unitStr,
                          color: Colors.purple.shade50,
                          textColor: Colors.purple.shade700,
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "الوصف",
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 18.sp,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 100), // Extra space for scroll
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 80,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final String productOrgId =
        _productData?['organizationId'] ??
        _productData?['OrganizationId'] ??
        '';
    final bool isGuest = StorageService().isGuest;
    final String? currentOrgId = StorageService().currentUserOrgId;

    if (!isGuest &&
        currentOrgId != null &&
        currentOrgId.isNotEmpty &&
        currentOrgId == productOrgId) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 15, 24, 35),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.edit, color: Colors.white, size: 16),
          label: Text(
            'أنت تملك هذا المنتج',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.grey.shade400,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    final bool isAvailableForDirectSale =
        _productData?['isAvailableForDirectSale'] == true ||
        _productData?['IsAvailableForDirectSale'] == true;

    if (!isAvailableForDirectSale) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 35),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                if (isGuest) {
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.info,
                    title: 'تسجيل الدخول مطلوب',
                    text: 'تحتاج إلى تسجيل الدخول لمراسلة البائع.',
                    confirmBtnText: 'تسجيل الدخول',
                    onConfirmBtnTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, LoginScreen.id);
                    },
                  );
                  return;
                }

                if (productOrgId.isEmpty) return;

                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.loading,
                  title: 'جاري بدء الدردشة...',
                  text: 'يرجى الانتظار',
                  barrierDismissible: false,
                );

                try {
                  final roomId = await ChatService().startChat(
                    organizationId: productOrgId,
                    productId: widget.productId,
                  );

                  if (context.mounted) {
                    Navigator.pop(context); // close loading alert
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => BlocProvider(
                              create: (_) => ChatMessagesCubit(ChatService()),
                              child: ChatDetailsScreen(
                                roomId: roomId,
                                roomName:
                                    _productData?['sellerName'] ??
                                    _productData?['organizationName'] ??
                                    'بائع',
                              ),
                            ),
                      ),
                    );
                  }
                } catch (e, stackTrace) {
                  debugPrint(" EXACT ERROR: $e");
                  debugPrint(" STACK TRACE: $stackTrace");
                  if (context.mounted) {
                    Navigator.pop(context);
                    QuickAlert.show(
                      context: context,
                      type: QuickAlertType.error,
                      title: 'خطأ',
                      text: 'فشل الاتصال. يرجى التحقق من السجلات.',
                    );
                  }
                }
              },
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF1B7A35),
                size: 16,
              ),
              label: Text(
                'مراسلة البائع',
                style: TextStyle(
                  color: const Color(0xFF1B7A35),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF1B7A35), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (isGuest) {
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.info,
                    title: 'تسجيل الدخول مطلوب',
                    text: 'تحتاج إلى تسجيل الدخول للشراء أو المزايدة.',
                    confirmBtnText: 'تسجيل الدخول',
                    onConfirmBtnTap: () {
                      Navigator.pop(context); // close alert
                      Navigator.pushNamed(context, LoginScreen.id);
                    },
                  );
                  return;
                }

                // حماية من إضافة المنتج مرتين
                final bool alreadyInCart = CartService().items.any(
                  (item) => item['productId'] == widget.productId,
                );
                if (alreadyInCart) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('العنصر موجود بالفعل في السلة!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final dynamic stockRaw =
                    _productData?['stockQuantity'] ??
                    _productData?['StockQuantity'] ??
                    0;
                final int stockQuantity =
                    stockRaw is num
                        ? stockRaw.toInt()
                        : int.tryParse(stockRaw.toString()) ?? 0;

                _showAddToCartBottomSheet(
                  context,
                  _productData!,
                  stockQuantity,
                );
              },
              icon: const Icon(
                Icons.add_shopping_cart_rounded,
                color: Colors.white,
                size: 16,
              ),
              label: Text(
                'أضف إلى السلة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B7A35),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToCartBottomSheet(
    BuildContext context,
    Map<String, dynamic> productData,
    int stockQuantity,
  ) {
    final String name =
        productData['name'] ?? productData['Name'] ?? 'منتج غير معروف';
    final dynamic priceRaw =
        productData['directSalePrice'] ?? productData['DirectSalePrice'] ?? 0;
    final double unitPrice =
        priceRaw is num
            ? priceRaw.toDouble()
            : double.tryParse(priceRaw.toString()) ?? 0.0;

    final images = productData['images'] ?? productData['Images'];
    final List<dynamic> imagesList = (images is List) ? images : [];
    String? firstImageUrl;
    if (imagesList.isNotEmpty) {
      if (imagesList[0] is Map) {
        firstImageUrl = imagesList[0]['url'] ?? imagesList[0]['Url'];
      } else {
        firstImageUrl = imagesList[0].toString();
      }
    }
    if (firstImageUrl != null && firstImageUrl.startsWith('/')) {
      firstImageUrl = 'https://root2route.runasp.net$firstImageUrl';
    }

    final int maxQty = stockQuantity > 0 ? stockQuantity : 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _QuantitySelectorSheet(
              productId: widget.productId,
              name: name,
              unitPrice: unitPrice,
              maxQty: maxQty,
              firstImageUrl: firstImageUrl,
              onConfirm: (int qty) {
                Navigator.pop(sheetContext);
                context.read<CartCubit>().addItem(
                  productId: widget.productId,
                  name: name,
                  price: unitPrice,
                  imageUrl: firstImageUrl,
                  quantity: qty,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تمت إضافة $qty × $name إلى السلة!'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// A self-contained StatefulWidget for the quantity selector bottom sheet.
class _QuantitySelectorSheet extends StatefulWidget {
  final String productId;
  final String name;
  final double unitPrice;
  final int maxQty;
  final String? firstImageUrl;
  final void Function(int quantity) onConfirm;

  const _QuantitySelectorSheet({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.maxQty,
    required this.firstImageUrl,
    required this.onConfirm,
  });

  @override
  State<_QuantitySelectorSheet> createState() => _QuantitySelectorSheetState();
}

class _QuantitySelectorSheetState extends State<_QuantitySelectorSheet> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '$_selectedQuantity');
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        if (_controller.text.isEmpty || int.tryParse(_controller.text) == 0) {
          setState(() {
            _selectedQuantity = 1;
            _controller.text = '1';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double total = _selectedQuantity * widget.unitPrice;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'اختر الكمية',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedQuantity = widget.maxQty;
                    _controller.text = '$_selectedQuantity';
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text(
                  'شراء الكل',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.name,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          // Counter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Minus button
                Material(
                  color:
                      _selectedQuantity > 1
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.12)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap:
                        _selectedQuantity > 1
                            ? () {
                              setState(() {
                                _selectedQuantity--;
                                _controller.text = '$_selectedQuantity';
                              });
                            }
                            : null,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.remove,
                        size: 20,
                        color:
                            _selectedQuantity > 1
                                ? Theme.of(context).colorScheme.primary
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white24
                                    : Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
                // Current value (Editable TextField)
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 42,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.black26
                                : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                        cursorColor: Theme.of(context).colorScheme.primary,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          filled: false,
                        ),
                        onChanged: (val) {
                          if (val.isEmpty) {
                            setState(() {
                              _selectedQuantity = 0;
                            });
                            return;
                          }
                          int? parsed = int.tryParse(val);
                          if (parsed != null) {
                            if (parsed > widget.maxQty) {
                              parsed = widget.maxQty;
                              _controller.text = '$parsed';
                              _controller
                                  .selection = TextSelection.fromPosition(
                                TextPosition(offset: _controller.text.length),
                              );
                            }
                            setState(() {
                              _selectedQuantity = parsed!;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'من أصل ${widget.maxQty} متاح',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                // Plus button
                Material(
                  color:
                      _selectedQuantity < widget.maxQty
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.12)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap:
                        _selectedQuantity < widget.maxQty
                            ? () {
                              setState(() {
                                _selectedQuantity++;
                                _controller.text = '$_selectedQuantity';
                              });
                            }
                            : null,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.add,
                        size: 20,
                        color:
                            _selectedQuantity < widget.maxQty
                                ? Theme.of(context).colorScheme.primary
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white24
                                    : Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Total Price Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'السعر الإجمالي',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(2)} جنيه',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // Confirm Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _selectedQuantity > 0
                      ? () {
                        FocusScope.of(context).unfocus();
                        widget.onConfirm(_selectedQuantity);
                      }
                      : null,
              icon: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                'تأكيد الشراء',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
