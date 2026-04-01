import 'package:flutter/material.dart';
import 'package:root2route/components/custom_merchant/custom_SummaryCard.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/tradesman/purchases_screen.dart';
import 'package:root2route/screens/tradesman/sales_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isPurchasesSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        title: const Text(
          "History",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
       backgroundColor: AppColors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
            Expanded(
  child: CustomSummaryCard(
    title: "Total Purchases",
    amount: "\$4,250",
  ),
),
const SizedBox(width: 12),
Expanded(
  child: CustomSummaryCard(
    title: "Total Sales",
    amount: "\$6,800",
  ),
),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isPurchasesSelected = true;
                        });
                      },
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isPurchasesSelected
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Purchases",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isPurchasesSelected
                                ? Colors.black
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isPurchasesSelected = false;
                        });
                      },
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !isPurchasesSelected
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Sales",
                          style: TextStyle(
                                                        fontSize: 16,

                            fontWeight: FontWeight.w700,
                            color: !isPurchasesSelected
                                ? Colors.black
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Activity",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: isPurchasesSelected
                  ? PurchasesScreen()
                  : SalesScreen(),
            ),
          ],
        ),
      ),
    );
  }
}