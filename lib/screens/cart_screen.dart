import 'package:flutter/material.dart';

import '../models/book_set.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final List<BookSet> cartItems;

  const CartScreen({super.key, required this.cartItems});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController discountController = TextEditingController();

  final TextEditingController addValueController = TextEditingController();

  bool soldToSchool = false;

  @override
  Widget build(BuildContext context) {
    int total = 0;

    for (var item in widget.cartItems) {
      total += item.price;
    }

    int discount = int.tryParse(discountController.text) ?? 0;

    int addValue = int.tryParse(addValueController.text) ?? 0;

    int finalTotal = total - discount + addValue;

    return Scaffold(
      appBar: AppBar(title: const Text("Cart")),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              // CART ITEMS
              ListView.builder(
                shrinkWrap: true,

                physics: const NeverScrollableScrollPhysics(),

                itemCount: widget.cartItems.length,

                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.menu_book)),

                      title: Text("${item.school} ${item.className}"),

                      subtitle: Text(item.qrId),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          Text(
                            "₹${item.price}",

                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),

                            onPressed: () {
                              final updatedCart = List<BookSet>.from(
                                widget.cartItems,
                              )..removeAt(index);

                              Navigator.pop(context, updatedCart);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // TOTAL CARD
              Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.blue.shade100,

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "Final Total",

                          style: TextStyle(
                            fontSize: 22,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text("Books: ₹$total"),

                        Text("Discount: ₹$discount"),

                        Text("Extra Value: ₹$addValue"),
                      ],
                    ),

                    Text(
                      "₹$finalTotal",

                      style: const TextStyle(
                        fontSize: 28,

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // DISCOUNT
              TextField(
                controller: discountController,

                keyboardType: TextInputType.number,

                onChanged: (_) {
                  setState(() {});
                },

                decoration: InputDecoration(
                  labelText: "Discount",

                  prefixIcon: const Icon(Icons.discount),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // EXTRA VALUE
              TextField(
                controller: addValueController,

                keyboardType: TextInputType.number,

                onChanged: (_) {
                  setState(() {});
                },

                decoration: InputDecoration(
                  labelText: "Add Value (Stationery)",

                  prefixIcon: const Icon(Icons.add_box),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // SCHOOL SALE
              SwitchListTile(
                value: soldToSchool,

                onChanged: (value) {
                  setState(() {
                    soldToSchool = value;
                  });
                },

                title: const Text("Sold To School"),
              ),

              const SizedBox(height: 20),

              // CHECKOUT BUTTON
              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: () async {
                    final invoiceId =
                        "INV-${DateTime.now().millisecondsSinceEpoch}";

                    final paymentDone = await Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(
                          finalTotal: finalTotal,

                          soldToSchool: soldToSchool,

                          invoiceId: invoiceId,

                          soldBooks: widget.cartItems,
                          discount: discount,

                          originalTotal: total,
                        ),
                      ),
                    );

                    if (paymentDone == true) {
                      if (!mounted) return;

                      Navigator.pop(context, <BookSet>[]);
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),

                  child: const Text("Checkout", style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
