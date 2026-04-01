import 'package:flutter/material.dart';
import 'package:root2route/components/custom_merchant/transaction_item.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        TransactionItem(
          title: "Yellow Levantine",
          price: "\$84.00",
          status: "Completed",
          statusColor: Color.fromARGB(255, 243, 33, 33),
                               amount: '23k',

        ),
        TransactionItem(
          title: "Parsley",
          price: "\$150.00",
          status: "Completed",
          statusColor: Colors.red,
                               amount: '23k',

        ),
        TransactionItem(
          title: "Rice    ",
          price: "\$450.00",
          status: "Pending",
          statusColor: Color.fromARGB(255, 80, 192, 15),
                               amount: '23k',

        ),
        TransactionItem(
          title: "Raisins    ",
          price: "\$450.00",
          status: "Completed",
          statusColor: Colors.red,
                               amount: '23k',

        ),
        TransactionItem(
          title: "Banana    ",
          price: "\$450.00",
          status: "Pending",
          statusColor: Color.fromARGB(255, 80, 192, 15),
                               amount: '23k',

        ),
      ],
    );
  }
}