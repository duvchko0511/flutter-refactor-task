// Import necessary packages
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

// Main function
void main() async {
  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapter
  Hive.registerAdapter(ItemAdapter());

  // Open Hive box
  await Hive.openBox<Item>('items');

  // Run the app
  runApp(MyApp());
}

// MyApp class
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Refactor Task App',
      theme: ThemeData(primarySwatch: Colors.blue),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: MyHomePage(),
    );
  }
}

// MyHomePage class
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get instance of DataController
    final DataController dataController = Get.put(DataController());

    return Scaffold(
      appBar: AppBar(title: Text('Refactor Task App')),
      body: Obx(() {
        if (dataController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        } else if (dataController.error.isNotEmpty) {
          return Center(child: Text('Error: ${dataController.error}'));
        } else {
          final List<Item> items = dataController.items;
          final bool isDarkMode = Get.isDarkMode;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Get.width ~/ 200,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.title ?? ''),
                subtitle: Text(item.description ?? ''),
                tileColor: isDarkMode ? Colors.grey[800] : Colors.white,
              );
            },
          );
        }
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: dataController.fetchAndStoreItems,
        tooltip: 'Fetch Data',
        child: Icon(Icons.refresh),
      ),
    );
  }
}

// DataController class
class DataController extends GetxController {
  // Observable variables
  RxBool isLoading = true.obs;
  RxString error = ''.obs;

  // Items list
  RxList<Item> items = <Item>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchItemsFromDatabase();
  }

  // Fetch items from API and store in local database
  void fetchAndStoreItems() async {
    try {
      final response = await http
          .get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
      if (response.statusCode == 200) {
        final List<Item> fetchedItems = (json.decode(response.body) as List)
            .map((item) => Item.fromJson(item))
            .toList();

        final box = await Hive.openBox<Item>('items');
        await box.clear();
        await box.addAll(fetchedItems);

        items.assignAll(fetchedItems);
        isLoading.value = false;
        error.value = '';
      } else {
        throw 'Failed to fetch data from API';
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  // Fetch items from local database
  void fetchItemsFromDatabase() async {
    final box = await Hive.openBox<Item>('items');
    items.assignAll(box.values.toList());
    isLoading.value = false;
  }
}

// Item class
@HiveType(typeId: 0)
class Item extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String? title;

  @HiveField(2)
  final String? description;

  // Constructor
  Item({required this.id, this.title, this.description});

  // FromJson method
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      title: json['title'],
      description: json['body'],
    );
  }
}
