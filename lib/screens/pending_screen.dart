import 'package:flutter/material.dart';

import '../utils/pending_data.dart';
import 'checkout_screen.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Payments")),

      body: pendingInvoices.isEmpty
          ? const Center(
              child: Text(
                "No Pending Payments",
                style: TextStyle(fontSize: 22),
              ),
            )
          : ListView.builder(
              itemCount: pendingInvoices.length,

              itemBuilder: (context, index) {
                final invoice = pendingInvoices[index];

                return Card(
                  margin: const EdgeInsets.all(10),

                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.payment)),

                    title: Text(invoice.invoiceId),

                    subtitle: Text("₹${invoice.amount}"),

                    trailing: const Icon(Icons.arrow_forward_ios),

                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(
                            finalTotal: invoice.amount,

                            soldToSchool: invoice.soldToSchool,

                            invoiceId: invoice.invoiceId,

                            soldBooks: const [],
                            discount: 0,

                            originalTotal: invoice.amount,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
