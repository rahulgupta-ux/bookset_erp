import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolManagerScreen extends StatefulWidget {
  const SchoolManagerScreen({super.key});

  @override
  State<SchoolManagerScreen> createState() => _SchoolManagerScreenState();
}

class _SchoolManagerScreenState extends State<SchoolManagerScreen> {
  final schoolController = TextEditingController();

  final schoolCodeController = TextEditingController();

  final classController = TextEditingController();

  bool isLoading = false;

  Future<void> createSchool() async {
    final school = schoolController.text.trim();

    final schoolCode = schoolCodeController.text.trim().toUpperCase();

    final className = classController.text.trim();

    if (school.isEmpty || schoolCode.isEmpty || className.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    final docId = "${schoolCode}_$className";

    await FirebaseFirestore.instance.collection("schools").doc(docId).set({
      "school": school,
      "schoolCode": schoolCode,
      "className": className,
      "createdAt": Timestamp.now(),
    });

    schoolController.clear();
    schoolCodeController.clear();
    classController.clear();

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("School Created")));
  }

  @override
  void dispose() {
    schoolController.dispose();
    schoolCodeController.dispose();
    classController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("School Manager")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: schoolController,

              decoration: const InputDecoration(
                labelText: "School Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: schoolCodeController,

              decoration: const InputDecoration(
                labelText: "School Code",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: classController,

              decoration: const InputDecoration(
                labelText: "Class",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: isLoading ? null : createSchool,

                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("CREATE"),
              ),
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 20),

            const Text(
              "Existing Schools",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("schools")
                    .orderBy("school")
                    .snapshots(),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,

                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          title: Text(data["school"]),

                          subtitle: Text(
                            "${data["schoolCode"]} • ${data["className"]}",
                          ),

                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),

                            onPressed: () async {
                              await docs[index].reference.delete();
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
