import 'package:flutter/material.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/details_product_model.dart';
import 'package:root2route/screens/Organizations/add_organization_screen.dart';
import 'package:root2route/components/custom_product_card.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  static const String id = 'Products_screen';

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        title: const Text(
          "Products",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 140,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddOrganizationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_business_outlined, size: 20),
                  label: const Text(
                    "Organization",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSizes.paddingSize(context)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color.fromARGB(255, 129, 129, 129),
                  ),
                  suffixIcon:
                      searchController.text.isEmpty
                          ? null
                          : IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              searchController.clear();
                              setState(() {});
                              FocusScope.of(context).unfocus();
                            },
                          ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.Secondary,
                      width: 0.9,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.Secondary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                return CustomProductCard(
                  product: DetailsProductModel(
                    imagePath: 'assets/images/crop.jpg',
                    title: 'Egyptian wheat',
                    location: 'Cairo, Egypt',
                    price: '2,333 \$',
                    quantity: '300k',
                    description:
                        'High-quality Egyptian wheat, perfect for baking and essential food production.',
                    badgeText: 'Available',
                    badgeColor: AppColors.primary,
                    buttonText: 'Details',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
