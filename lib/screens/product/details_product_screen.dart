import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/services/api.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/screens/order/cart_screen.dart';
import 'package:root2route/services/cart_service.dart';
import 'package:root2route/services/chat_service.dart';
import 'package:root2route/screens/chat/chat_screen.dart';
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
                  ? 'Failed to load product data. Server did not send error details.'
                  : msg;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  String _getProductTypeString(dynamic typeIndex) {
    if (typeIndex == null) return 'Product';
    final idx = int.tryParse(typeIndex.toString()) ?? 0;
    switch (idx) {
      case 0:
        return 'Crop';
      case 1:
        return 'Processed';
      case 2:
        return 'Tool';
      case 3:
        return 'Chemical';
      default:
        return 'Crop';
    }
  }

  String _getWeightUnitString(dynamic unitIndex) {
    if (unitIndex == null) return '';
    final idx = int.tryParse(unitIndex.toString()) ?? 0;
    switch (idx) {
      case 0:
        return 'Kg';
      case 1:
        return 'pkg';
      case 2:
        return 'Liter';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(top: 10, left: 16),
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 16),
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
                        onPressed: () => Navigator.pushNamed(context, CartScreen.id),
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
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              "$cartCount",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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
                _errorMessage ?? 'Product not found.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProductDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _productData!;
    final String name = data['name'] ?? data['Name'] ?? 'Unknown Product';
    
    final bool isAvailableForDirectSale = data['isAvailableForDirectSale'] == true || data['IsAvailableForDirectSale'] == true;
    final bool isAvailableForAuction = data['isAvailableForAuction'] == true || data['IsAvailableForAuction'] == true;

    double price = 0.0;
    bool showAuctionBadge = false;

    if (isAvailableForDirectSale) {
      final dynamic priceRaw = data['directSalePrice'] ?? data['DirectSalePrice'] ?? 0;
      price = priceRaw is num ? priceRaw.toDouble() : double.tryParse(priceRaw.toString()) ?? 0.0;
    } else if (isAvailableForAuction) {
      final dynamic priceRaw = data['startBiddingPrice'] ?? data['StartBiddingPrice'] ?? 0;
      price = priceRaw is num ? priceRaw.toDouble() : double.tryParse(priceRaw.toString()) ?? 0.0;
      showAuctionBadge = true;
    } else {
      final dynamic priceRaw = data['directSalePrice'] ?? data['DirectSalePrice'] ?? 0;
      price = priceRaw is num ? priceRaw.toDouble() : double.tryParse(priceRaw.toString()) ?? 0.0;
    }
    final String description =
        data['description'] ??
        data['Description'] ??
        'No description available.';
    final dynamic stockRaw =
        data['stockQuantity'] ?? data['StockQuantity'] ?? 0;
    final int quantity =
        stockRaw is num
            ? stockRaw.toInt()
            : int.tryParse(stockRaw.toString()) ?? 0;
    final dynamic typeRaw = data['productType'] ?? data['ProductType'];
    final String typeStr =
        typeRaw is String ? typeRaw : _getProductTypeString(typeRaw);
    final dynamic unitRaw = data['weightUnit'] ?? data['WeightUnit'];
    final String unitStr =
        unitRaw is String ? unitRaw : _getWeightUnitString(unitRaw);

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
            decoration: const BoxDecoration(
              color: Colors.white,
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
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${price.toStringAsFixed(0)} EGP',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          if (showAuctionBadge) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Auction Only',
                                style: TextStyle(
                                  fontSize: 12,
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
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildChip(
                        icon: Icons.category_rounded,
                        label: typeStr,
                        color: Colors.blue.shade50,
                        textColor: Colors.blue.shade700,
                      ),
                      _buildChip(
                        icon: Icons.inventory_2_rounded,
                        label: '$quantity In Stock',
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
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final String productOrgId = _productData?['organizationId'] ?? _productData?['OrganizationId'] ?? '';
    final bool isGuest = StorageService().isGuest;
    final String? currentOrgId = StorageService().currentUserOrgId;

    if (!isGuest && currentOrgId != null && currentOrgId.isNotEmpty && currentOrgId == productOrgId) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 15, 24, 35),
        decoration: BoxDecoration(
          color: Colors.white,
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
          icon: const Icon(Icons.edit, color: Colors.white),
          label: const Text(
            'You own this product',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.grey.shade400,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    final bool isAvailableForDirectSale = _productData?['isAvailableForDirectSale'] == true || _productData?['IsAvailableForDirectSale'] == true;
    if (!isAvailableForDirectSale) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 35),
      decoration: BoxDecoration(
        color: Colors.white,
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
                    title: 'Login Required',
                    text: 'You need to login to contact seller.',
                    confirmBtnText: 'Login',
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
                  title: 'Starting Chat...',
                  text: 'Please wait',
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
                        builder: (_) => BlocProvider(
                          create: (_) => ChatMessagesCubit(ChatService()),
                          child: ChatScreen(roomId: roomId),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    QuickAlert.show(
                      context: context,
                      type: QuickAlertType.error,
                      title: 'Error',
                      text: e.toString(),
                    );
                  }
                }
              },
              icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
              label: const Text(
                'Contact Seller',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                    title: 'Login Required',
                    text: 'You need to login to buy or bid.',
                    confirmBtnText: 'Login',
                    onConfirmBtnTap: () {
                      Navigator.pop(context); // close alert
                      Navigator.pushNamed(context, LoginScreen.id);
                    },
                  );
                  return;
                }
                final String name = _productData?['name'] ?? _productData?['Name'] ?? 'Unknown Product';
                final dynamic priceRaw = _productData?['directSalePrice'] ?? _productData?['DirectSalePrice'] ?? 0;
                final double price = priceRaw is num ? priceRaw.toDouble() : double.tryParse(priceRaw.toString()) ?? 0.0;

                final images = _productData?['images'] ?? _productData?['Images'];
                final List<dynamic> imagesList = (images is List) ? images : [];
                String? firstImageUrl;
                if (imagesList.isNotEmpty) {
                  if (imagesList[0] is Map) {
                    firstImageUrl = imagesList[0]['url'] ?? imagesList[0]['Url'];
                  } else {
                    firstImageUrl = imagesList[0].toString();
                  }
                }

                final bool alreadyInCart = CartService().items.any((item) => item['productId'] == widget.productId);

                context.read<CartCubit>().addItem(
                  productId: widget.productId,
                  name: name,
                  price: price,
                  imageUrl: firstImageUrl,
                  quantity: 1,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(alreadyInCart ? 'Item already in cart!' : 'Product added to cart!'),
                    backgroundColor: alreadyInCart ? Colors.orange : AppColors.primary,
                  ),
                );
              },
              icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
              label: const Text(
                'Add to Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
