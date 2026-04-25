import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/edit_product_screen.dart';
import 'package:root2route/screens/Market/create_auction_screen.dart';
import 'package:root2route/screens/Market/add_product_screen.dart';
import 'package:root2route/screens/details_product_screen.dart';
import 'package:root2route/services/api.dart';

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
  String? _currentOrgId;

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
            'No organization found. Please create one to manage products.';
        _isLoading = false;
      });
      return;
    }

    _currentOrgId = targetOrgId;

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
          _errorMessage = 'Invalid data format from server.';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Failed to load products';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Product?'),
            content: const Text(
              'Are you sure you want to delete this product? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Deleting...',
      text: 'Please wait, deleting product.',
      barrierDismissible: false,
    );

    try {
      final res = await _api.deleteProduct(id);
      if (!mounted) return;
      Navigator.pop(context); // close loading dialog

      if (res['success'] == true) {
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Deleted!',
          text: 'The product was successfully removed.',
          showConfirmBtn: false,
          autoCloseDuration: const Duration(seconds: 2),
        );
        _fetchProducts(); // Refresh list automatically
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Delete Failed',
          text: res['message'] ?? 'Could not delete product.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Unexpected Error',
        text: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'My Products',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _buildBody(),
      floatingActionButton:
          _currentOrgId != null
              ? FloatingActionButton(
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              AddProductScreen(organizationId: _currentOrgId!),
                    ),
                  );
                  if (result == true) {
                    _fetchProducts();
                  }
                },
                child: const Icon(Icons.add, color: AppColors.iconPrimary),
              )
              : null,
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
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
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No products found.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first product to get started.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                if (_currentOrgId != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              AddProductScreen(organizationId: _currentOrgId!),
                    ),
                  );
                  if (result == true) {
                    _fetchProducts();
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.68,
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
    final name = product['name'] ?? product['Name'] ?? 'Unknown';

    // Convert direct sale price safely
    final rawPrice =
        product['directSalePrice'] ?? product['DirectSalePrice'] ?? 0;
    final price = double.tryParse(rawPrice.toString()) ?? 0.0;

    // Safely extract first image URL
    final imagesList = product['images'] ?? product['Images'];
    String? imageUrl;
    if (imagesList is List && imagesList.isNotEmpty) {
      imageUrl = imagesList.first?.toString();
    }

    final displayUrl =
        (imageUrl != null && imageUrl.startsWith('/'))
            ? 'https://root2route.runasp.net$imageUrl'
            : imageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailsProductScreen(productId: id.toString()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // Image Area
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child:
                    displayUrl != null && displayUrl.isNotEmpty
                        ? Image.network(
                          displayUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                        : _buildPlaceholder(),
              ),
            ),
            // Info Area
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'EGP ${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => CreateAuctionScreen(
                                    productId: id.toString(),
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.gavel_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _deleteProduct(id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade100,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade300,
        size: 40,
      ),
    );
  }
}

