import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

// Import your Hive models
import 'models/customer.dart';
import 'models/order.dart';
import 'models/measurement.dart';
import 'models/subscription_info.dart';
import 'models/order_item.dart'; // NEW: Import OrderItem
import 'screens/main_home_screen.dart';

// NEW: Notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// =======================================================================
// PHASE 1: Step 1.6 - Setup Provider for app state management
// Our global app state, accessible from anywhere in the app
// =======================================================================
class AppState extends ChangeNotifier {
  // --- General App State ---
  int _counter = 0; // For basic testing, can be removed later
  int get counter => _counter;
  void incrementCounter() {
    _counter++;
    notifyListeners();
  }

  String _appTitle = "DarziApp";
  String get appTitle => _appTitle;

  // --- SharedPreferences & Hive Boxes ---
  late SharedPreferences _prefs;
  SharedPreferences get prefs => _prefs;

  late Box<Customer> customerBox;
  late Box<Order> orderBox;
  late Box<Measurement> measurementBox;
  late Box<SubscriptionInfo> subscriptionInfoBox;

  // --- Subscription and Trial State ---
  SubscriptionInfo? _currentSubscriptionInfo;
  SubscriptionInfo? get currentSubscriptionInfo => _currentSubscriptionInfo;

  // Defined Limits for Free/Trial users
  static const int maxFreeCustomers = 20;
  static const int maxFreeOrders = 30;
  static const int maxFreeMeasurements = 30;
  static const int trialDurationDays = 7;

  bool get isPremiumUser => _currentSubscriptionInfo?.isSubscribed == true;
  bool get isTrialActive {
    if (_currentSubscriptionInfo?.trialStartDate == null) return false;
    final now = DateTime.now();
    final trialEnd = _currentSubscriptionInfo!.trialStartDate!.add(const Duration(days: trialDurationDays));
    return now.isBefore(trialEnd);
  }
  
  int get daysLeftInTrial {
    if (!isTrialActive) return 0;
    final now = DateTime.now();
    final trialEnd = _currentSubscriptionInfo!.trialStartDate!.add(const Duration(days: trialDurationDays));
    return trialEnd.difference(now).inDays + 1; // +1 to count current day
  }
  
  bool get hasUsedTrial => _currentSubscriptionInfo?.hasUsedTrial == true;

  // --- Reporting Methods (NEW) ---
  int get totalCustomers => customerBox.length;

  int get totalOrders => orderBox.length;

  int get totalMeasurements => measurementBox.length;

  double get totalRevenue {
    return orderBox.values
        .where((order) => order.status == 'Delivered') // Only count delivered orders as revenue
        .fold(0.0, (sum, order) => sum + order.totalPrice);
  }

  double get totalOutstandingPayments {
    return orderBox.values
        .where((order) => order.status != 'Delivered') // Exclude delivered orders
        .fold(0.0, (sum, order) => sum + order.remainingPayment);
  }

  double get averageOrderValue {
    if (orderBox.isEmpty) return 0.0;
    final total = orderBox.values.fold(0.0, (sum, order) => sum + order.totalPrice);
    return total / orderBox.length;
  }

  // Get count of orders by status
  Map<String, int> get ordersByStatus {
    final statusCounts = <String, int>{
      'Cutting': 0,
      'Stitching': 0,
      'Ready': 0,
      'Delivered': 0,
    };
    for (var order in orderBox.values) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }
    return statusCounts;
  }

  // --- Customer Management State ---
  List<Customer> _customers = [];
  String _customerSearchQuery = ''; // NEW: Search query for customers
  void setCustomerSearchQuery(String query) {
    _customerSearchQuery = query.toLowerCase();
    notifyListeners(); // Notify to re-filter the list
  }
  
  List<Customer> get customers {
    if (_customerSearchQuery.isEmpty) {
      return _customers;
    } else {
      return _customers.where((customer) {
        return customer.name.toLowerCase().contains(_customerSearchQuery) ||
               customer.phone.toLowerCase().contains(_customerSearchQuery) ||
               customer.address.toLowerCase().contains(_customerSearchQuery);
      }).toList();
    }
  }

  int get customerCount => customerBox.length;

  bool get canAddMoreCustomers {
    if (isPremiumUser) return true;
    return customerCount < maxFreeCustomers;
  }

  String get customerLimitMessage {
    if (isPremiumUser) return "You have unlimited customer slots.";
    if (!isTrialActive && hasUsedTrial) return "Trial expired. Upgrade to add more customers.";
    return "You can add ${maxFreeCustomers - customerCount} more customers (Max $maxFreeCustomers in free/trial).";
  }

  // --- Measurement Management State (NEW) ---
  List<Measurement> _measurements = [];
  String _measurementSearchQuery = ''; // NEW: Search query for measurements
  void setMeasurementSearchQuery(String query) {
    _measurementSearchQuery = query.toLowerCase();
    notifyListeners(); // Notify to re-filter the list
  }
  
  List<Measurement> get measurements {
    if (_measurementSearchQuery.isEmpty) {
      return _measurements;
    } else {
      return _measurements.where((measurement) {
        final customer = getCustomerById(measurement.customerId);
        return (customer?.name.toLowerCase().contains(_measurementSearchQuery) ?? false) ||
               measurement.type.toLowerCase().contains(_measurementSearchQuery) ||
               measurement.key.toString().contains(_measurementSearchQuery); // Search by ID
      }).toList();
    }
  }

  int get measurementCount => measurementBox.length;

  bool get canAddMoreMeasurements {
    if (isPremiumUser) return true;
    return measurementCount < maxFreeMeasurements;
  }

  String get measurementLimitMessage {
    if (isPremiumUser) return "You have unlimited measurement slots.";
    if (!isTrialActive && hasUsedTrial) return "Trial expired. Upgrade to add more measurements.";
    return "You can add ${maxFreeMeasurements - measurementCount} more measurements (Max $maxFreeMeasurements in free/trial).";
  }

  // --- Order Management State (NEW) ---
  List<Order> _orders = [];
  String _orderSearchQuery = ''; // NEW: Search query for orders
  void setOrderSearchQuery(String query) {
    _orderSearchQuery = query.toLowerCase();
    notifyListeners(); // Notify to re-filter the list
  }
  
  List<Order> get orders {
    if (_orderSearchQuery.isEmpty) {
      return _orders;
    } else {
      return _orders.where((order) {
        final customer = getCustomerById(order.customerId);
        return (customer?.name.toLowerCase().contains(_orderSearchQuery) ?? false) ||
               order.trackingNumber?.toLowerCase().contains(_orderSearchQuery) == true || // Search tracking number
               order.status.toLowerCase().contains(_orderSearchQuery) ||
               order.key.toString().contains(_orderSearchQuery); // Search by Order ID
      }).toList();
    }
  }

  int get orderCount => orderBox.length;

  bool get canAddMoreOrders {
    if (isPremiumUser) return true;
    return orderCount < maxFreeOrders;
  }

  String get orderLimitMessage {
    if (isPremiumUser) return "You have unlimited order slots.";
    if (!isTrialActive && hasUsedTrial) return "Trial expired. Upgrade to add more orders.";
    return "You can add ${maxFreeOrders - orderCount} more orders (Max $maxFreeOrders in free/trial).";
  }

  // --- NEW: Notification Initialization ---
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Ensure 'app_icon' exists in drawable
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, 
        iOS: initializationSettingsIOS);
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification tap
        // For example, navigate to the order details screen
        print('Notification tapped: ${notificationResponse.payload}');
      },
    );
  }

  // --- NEW: Notification scheduling method ---
  Future<void> _scheduleDeliveryNotification(Order order) async {
    final int notificationId = order.key as int; // Use order key as unique ID
    await flutterLocalNotificationsPlugin.cancel(notificationId); // Cancel previous if rescheduling

    final DateTime scheduledDate = order.deliveryDate.subtract(const Duration(days: 1)); // Notify 1 day before

    if (scheduledDate.isAfter(DateTime.now())) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'delivery_channel_id',
        'Delivery Reminders',
        channelDescription: 'Reminders for upcoming order deliveries',
        importance: Importance.high,
        priority: Priority.high,
      );
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      final tz.TZDateTime tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Order Delivery Reminder!',
        'Order for ${getCustomerById(order.customerId)?.name ?? 'a customer'} is due on ${DateFormat('dd MMM yyyy').format(order.deliveryDate)}.',
        tzScheduled,
        platformDetails,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: order.key.toString(),
      );
      print('Scheduled notification for order ${order.key} on $scheduledDate');
    }
  }

  // Constructor and Initialization
  AppState() {
    _initializeServices();
    _initializeNotifications(); // NEW: Initialize notifications
  }

  Future<void> _initializeServices() async {
    // Use Hive.box() to get already-opened boxes (not openBox)
    customerBox = Hive.box<Customer>('customers');
    orderBox = Hive.box<Order>('orders');
    measurementBox = Hive.box<Measurement>('measurements');
    subscriptionInfoBox = Hive.box<SubscriptionInfo>('subscriptionInfo');

    _prefs = await SharedPreferences.getInstance();

    _loadCustomers();
    _loadMeasurements();
    _loadOrders();
    _loadSubscriptionInfo();
  }

  // --- Methods for Subscription/Trial Management ---
  void _loadSubscriptionInfo() {
    if (subscriptionInfoBox.isNotEmpty) {
      _currentSubscriptionInfo = subscriptionInfoBox.getAt(0);
    } else {
      _currentSubscriptionInfo = SubscriptionInfo(
        isSubscribed: false,
        trialStartDate: null,
        hasUsedTrial: false,
      );
      subscriptionInfoBox.add(_currentSubscriptionInfo!);
    }
    notifyListeners();
  }

  Future<void> startTrial() async {
    if (_currentSubscriptionInfo != null && !_currentSubscriptionInfo!.hasUsedTrial) {
      _currentSubscriptionInfo!.trialStartDate = DateTime.now();
      _currentSubscriptionInfo!.hasUsedTrial = true;
      await _currentSubscriptionInfo!.save();
      notifyListeners();
    }
  }

  Future<void> upgradeToPremium() async {
    if (_currentSubscriptionInfo != null) {
      _currentSubscriptionInfo!.isSubscribed = true;
      await _currentSubscriptionInfo!.save();
      notifyListeners();
    }
  }

  // --- Methods for Customer Management ---
  void _loadCustomers() {
    _customers = customerBox.values.toList();
    notifyListeners();
  }

  void refreshCustomers() {
    _loadCustomers();
  }

  Future<void> addCustomer(Customer customer) async {
    if (!canAddMoreCustomers && !isPremiumUser) {
      if (!isTrialActive && !hasUsedTrial) {
        await startTrial();
        if (!canAddMoreCustomers) {
          throw Exception("Trial started, but customer limit still reached. Upgrade to add more customers.");
        }
      } else if (!isTrialActive && hasUsedTrial) {
         throw Exception("Trial expired. Upgrade to add more customers.");
      } else {
         throw Exception("Customer limit reached. Upgrade to add more customers.");
      }
    }
    await customerBox.add(customer);
    _loadCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    await customer.save();
    _loadCustomers();
  }

  Future<void> deleteCustomer(Customer customer) async {
    final customerKey = customer.key as int;
    final associatedOrders = orderBox.values.where((o) => o.customerId == customerKey.toString()).toList();
    for (var order in associatedOrders) {
      // Need to also delete order items if they were in a separate box (not needed now)
      await order.delete();
    }
    final associatedMeasurements = measurementBox.values.where((m) => m.customerId == customerKey.toString()).toList();
    for (var measurement in associatedMeasurements) {
      await measurement.delete();
    }
    await customer.delete();
    _loadCustomers();
    _loadOrders();
    _loadMeasurements();
  }

  Customer? getCustomerById(String customerId) {
    return customerBox.get(int.parse(customerId));
  }

  // --- Methods for Measurement Management ---
  void _loadMeasurements() {
    _measurements = measurementBox.values.toList();
    notifyListeners();
  }

  void refreshMeasurements() {
    _loadMeasurements();
  }

  Future<void> addMeasurement(Measurement measurement) async {
    if (!canAddMoreMeasurements && !isPremiumUser) {
      if (!isTrialActive && !hasUsedTrial) {
        await startTrial();
        if (!canAddMoreMeasurements) {
          throw Exception("Trial started, but measurement limit still reached. Upgrade to add more measurements.");
        }
      } else if (!isTrialActive && hasUsedTrial) {
         throw Exception("Trial expired. Upgrade to add more measurements.");
      } else {
         throw Exception("Measurement limit reached. Upgrade to add more measurements.");
      }
    }
    await measurementBox.add(measurement);
    _loadMeasurements();
  }

  Future<void> updateMeasurement(Measurement measurement) async {
    await measurement.save();
    _loadMeasurements();
  }

  Future<void> deleteMeasurement(Measurement measurement) async {
    await measurement.delete();
    _loadMeasurements();
  }

  Measurement? getMeasurementById(String measurementId) {
    return measurementBox.get(int.parse(measurementId));
  }

  // UPDATED: Sort measurements by newest first
  List<Measurement> getMeasurementsForCustomer(String customerId) {
    return _measurements
        .where((m) => m.customerId == customerId)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by newest first
  }

  // --- Methods for Order Management ---
  void _loadOrders() {
    _orders = orderBox.values.toList();
    notifyListeners();
  }

  void refreshOrders() {
    _loadOrders();
  }

  // UPDATED: Add order with items and notification scheduling
  Future<void> addOrder(Order order) async {
    if (!canAddMoreOrders && !isPremiumUser) {
      if (!isTrialActive && !hasUsedTrial) {
        await startTrial();
        if (!canAddMoreOrders) {
          throw Exception("Trial started, but order limit still reached. Upgrade to add more orders.");
        }
      } else if (!isTrialActive && hasUsedTrial) {
         throw Exception("Trial expired. Upgrade to add more orders.");
      } else {
         throw Exception("Order limit reached. Upgrade to add more orders.");
      }
    }
    
    // Recalculate totalPrice and remainingPayment based on items
    order.totalPrice = order.items.fold(0.0, (sum, item) => sum + item.totalItemPrice);
    order.remainingPayment = order.totalPrice - order.advancePayment;

    await orderBox.add(order);
    _loadOrders();
    
    // Schedule notification if delivery date is in the future
    _scheduleDeliveryNotification(order);
  }

  // UPDATED: Update order with items and notification rescheduling
  Future<void> updateOrder(Order order) async {
    // Recalculate totalPrice and remainingPayment based on items
    order.totalPrice = order.items.fold(0.0, (sum, item) => sum + item.totalItemPrice);
    order.remainingPayment = order.totalPrice - order.advancePayment;

    await order.save();
    _loadOrders();
    
    // Reschedule notification for updated order
    _scheduleDeliveryNotification(order);
  }

  Future<void> deleteOrder(Order order) async {
    await order.delete();
    _loadOrders();
  }

  Order? getOrderById(String orderId) {
    return orderBox.get(int.parse(orderId));
  }

  List<Order> getOrdersForCustomer(String customerId) {
    return _orders.where((o) => o.customerId == customerId).toList();
  }
}

// =======================================================================
// Main function: Entry point of the Flutter app
// =======================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(OrderAdapter());
  Hive.registerAdapter(MeasurementAdapter());
  Hive.registerAdapter(SubscriptionInfoAdapter());
  Hive.registerAdapter(OrderItemAdapter()); // NEW: Register OrderItemAdapter

  // Open boxes HERE before runApp - this ensures data persists
  await Hive.openBox<Customer>('customers');
  await Hive.openBox<Order>('orders');
  await Hive.openBox<Measurement>('measurements');
  await Hive.openBox<SubscriptionInfo>('subscriptionInfo');

  // Initialize timezone data for scheduled notifications
  tz.initializeTimeZones();
  try {
    final String localTimeZone = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimeZone));
  } catch (e) {
    tz.setLocalLocation(tz.UTC);
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const DarziApp(),
    ),
  );
}

// =======================================================================
// DarziApp: The root widget of our application
// =======================================================================
class DarziApp extends StatelessWidget {
  const DarziApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Darzi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.teal,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
          floatingLabelStyle: const TextStyle(color: Colors.teal),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      home: const MainHomeScreen(),
    );
  }
}