import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // For AppState and trial info
import 'report_screen.dart'; // NEW: Import the ReportScreen

import 'customer_list_screen.dart';
// Import new screens
import 'measurement_list_screen.dart';
import 'order_list_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({Key? key}) : super(key: key);

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0; // Index for the selected tab

  static const List<Widget> _widgetOptions = <Widget>[
    CustomerListScreen(),
    OrderListScreen(),
    MeasurementListScreen(),
    ReportScreen(), // NEW: Use the ReportScreen here
    // Placeholder for future Reports screen or Settings
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Reusable widget for showing trial/upgrade banner
  Widget _buildTrialBanner(BuildContext context, AppState appState) {
    if (appState.isPremiumUser) {
      return const SizedBox.shrink(); // Don't show if premium
    }

    String message;
    Color backgroundColor;
    Color textColor;
    VoidCallback? onUpgradeTap;

    if (appState.isTrialActive) {
      message = 'Free Trial: ${appState.daysLeftInTrial} days left!';
      backgroundColor = Colors.amber[100]!;
      textColor = Theme.of(context).primaryColorDark;
      onUpgradeTap = () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigate to Subscription Page!')),
        );
        appState.upgradeToPremium(); // For testing
      };
    } else if (appState.hasUsedTrial) {
      message = 'Trial Expired! Upgrade to unlock full features.';
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[800]!;
      onUpgradeTap = () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigate to Subscription Page!')),
        );
        appState.upgradeToPremium(); // For testing
      };
    } else {
      return const SizedBox.shrink(); // Don't show if trial not started
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      color: backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onUpgradeTap != null)
            TextButton(
              onPressed: onUpgradeTap,
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero, // Important for small padding
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Upgrade'),
            ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context); // Listen to AppState for banner updates

    return Scaffold(
      body: Column(
        children: [
          _buildTrialBanner(context, appState), // Show banner at the top
          Expanded(
            child: _widgetOptions.elementAt(_selectedIndex), // Display selected screen
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.straighten),
            label: 'Measurements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports', // Placeholder
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Shows all labels
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}