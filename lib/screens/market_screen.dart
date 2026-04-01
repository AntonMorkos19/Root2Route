import 'package:flutter/material.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/details_product_model.dart';
import 'package:root2route/components/custom_product_card.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        title: const Text(
          "Market",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
