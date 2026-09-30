import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const SewtronApp());

class SewtronApp extends StatelessWidget {
  const SewtronApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SEWTRON ENGINEERING',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String apiUrl = "https://script.google.com/macros/s/AKfycby_B2C-rOOJVXYqGA0AJ8hkJ31B0d2o5OmwEaE6qRkDEqd8tiPNA6haRUHRjXPkjigN/exec";
  List<dynamic> entries = [];
  bool isLoading = true;
  double totalDue = 0.0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        double dueSum = 0.0;
        for (var item in data) {
          dueSum += double.tryParse(item['due'].toString()) ?? 0.0;
        }
        setState(() {
          entries = data.reversed.toList();
          totalDue = dueSum;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> addNewBill(String name, String inv, String total, String paid, String remarks) async {
    double totalVal = double.tryParse(total) ?? 0.0;
    double paidVal = double.tryParse(paid) ?? 0.0;
    double dueVal = totalVal - paidVal;

    final bodyData = {
      "name": name,
      "inv": inv,
      "total": totalVal,
      "paid": paidVal,
      "due": dueVal,
      "remarks": remarks,
      "date": DateTime.now().toIso8601String().substring(0, 10),
    };

    try {
      await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bodyData),
      );
      fetchData();
    } catch (_) {}
  }

  void showAddDialog() {
    final nameController = TextEditingController();
    final invController = TextEditingController();
    final totalController = TextEditingController();
    final paidController = TextEditingController();
    final remarksController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("নতুন বিল এন্ট্রি", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "কাস্টমারের নাম", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: invController, decoration: const InputDecoration(labelText: "চালান / ইনভয়েস নং", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: totalController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "মোট বিল (৳)", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: paidController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "জমা / পেইড (৳)", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: remarksController, decoration: const InputDecoration(labelText: "মন্তব্য (Remarks)", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  minimumSize: const Size.fromHeight(45),
                ),
                onPressed: () {
                  if (nameController.text.isNotEmpty && totalController.text.isNotEmpty) {
                    Navigator.pop(ctx);
                    addNewBill(
                      nameController.text,
                      invController.text,
                      totalController.text,
                      paidController.text.isEmpty ? "0" : paidController.text,
                      remarksController.text,
                    );
                  }
                },
                child: const Text("সংরক্ষণ করুন", style: TextStyle(color: Colors.white, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEWTRON ENGINEERING'),
        actions: [
          IconButton(onPressed: fetchData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("সর্বমোট বকেয়া (Outstanding Due)", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text("৳ ${totalDue.toStringAsFixed(0)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent)),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : entries.isEmpty
                    ? const Center(child: Text("কোনো রেকর্ড পাওয়া যায়নি"))
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (ctx, i) {
                          final item = entries[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              title: Text(item['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Inv: ${item['inv'] ?? '-'} | Date: ${item['date'] ?? '-'}"),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("৳ ${item['due'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15)),
                                  Text("বিল: ৳ ${item['total'] ?? 0}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E3A8A),
        onPressed: showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
