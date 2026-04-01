import 'package:flutter/material.dart';
import 'package:root2route/components/custom_merchant/transaction_item.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
              child: ListView(
                children: const [
                  TransactionItem(
                    title: "Potatoes",
                    price: "\$100.00",
                    status: "Completed",
                    statusColor: Colors.red,
                                         amount: '23k',

                  ),
                  TransactionItem(
                    title: "Pepper",
                    price: "\$34.00",
                    status: "Completed",
                    statusColor: Colors.red,
                     amount: '23k',
                  ),
                  TransactionItem(
                    title: "Eggplant",
                    price: "\$70.00",
                    status: "Pending",
                    statusColor: Color.fromARGB(255, 80, 192, 15),
                                         amount: '23k',

                  ),
                ],
              ),
            );
  }
}