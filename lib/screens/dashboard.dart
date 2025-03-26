import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String weather = "Loading...";
  double temperature = 0.0;
  double totalEnergyUsage = 0.0;
  bool showQuickActions = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;   // FirebaseAuth instance

  @override
  void initState() {
    super.initState();
    fetchWeather();
    fetchEnergyUsage();
  }

  Future<void> fetchWeather() async {
    String apiKey = "b03f2ac951dc66c082018ce2dce0281b"; // Replace with your API key
    String city = "Delhi"; // Replace with your city
    String url = "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          weather = data["weather"][0]["description"];
          temperature = data["main"]["temp"];
        });
      } else {
        setState(() {
          weather = "Failed to load weather";
        });
      }
    } catch (e) {
      setState(() {
        weather = "Error fetching data";
      });
    }
  }

  void fetchEnergyUsage() {
    
    FirebaseFirestore.instance.collection('devices').where('userId', isEqualTo: _auth.currentUser!.uid) // Filter by userId
        .snapshots().listen((snapshot) {  

      double totalUsage = 0.0;
      for (var doc in snapshot.docs) {
        var data = doc.data(); // No need for explicit cast
        totalUsage += (data['energyUsage'] ?? 0.0);
      }
      setState(() {
        totalEnergyUsage = totalUsage;
      });
    });
  }

  void toggleDevice(String deviceId, bool currentState) {
    FirebaseFirestore.instance.collection('devices').doc(deviceId).update({
      'status': !currentState,
    });
  }

  @override
  Widget build(BuildContext context) {
   
    var theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Smart Home Dashboard'),
        backgroundColor: theme.primary,
        foregroundColor: theme.onPrimary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.primary),
              child: Text("Menu", style: TextStyle(color: theme.onPrimary, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text("Device Control"),
              onTap: () {
                Navigator.pushNamed(context, '/device-control');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                // Replace '/profile' with your actual profile route
                Navigator.pushNamed(context, '/profile'); 
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome Back!",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: theme.onBackground),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              
              stream: FirebaseFirestore.instance.collection('devices')
                  .where('userId', isEqualTo: _auth.currentUser!.uid) // Filter by userId
                  .snapshots(),
              builder: (context, snapshot)

               {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text("No devices found"));
                }

                int totalDevices = snapshot.data!.docs.length;

                return Card(
                  color: theme.surface,
                  child: ListTile(
                    leading: Icon(Icons.devices, size: 40, color: theme.secondary),
                    title: const Text("Connected Devices"),
                    subtitle: Text("$totalDevices Active Devices", style: TextStyle(color: theme.onSurface)),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            Card(
              color: theme.surface,
              child: ListTile(
                leading: Icon(Icons.bolt, size: 40, color: theme.secondary),
                title: const Text("Energy Consumption"),
                subtitle: Text("$totalEnergyUsage kWh Used Today", style: TextStyle(color: theme.onSurface)),
              ),
            ),
            const SizedBox(height: 10),

            Card(
              color: theme.surface,
              child: ListTile(
                leading: Icon(Icons.wb_sunny, size: 40, color: theme.secondary),
                title: const Text("Current Weather"),
                subtitle: Text("$weather, $temperature°C", style: TextStyle(color: theme.onSurface)),
              ),
            ),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: () {
                setState(() {
                  showQuickActions = !showQuickActions;
                });
              },
              child: Card(
                color: theme.surface,
                child: ListTile(
                  leading: Icon(Icons.flash_on, size: 40, color: theme.secondary),
                  title: const Text("Quick Actions"),
                  subtitle: Text("Tap to show/hide device controls", style: TextStyle(color: theme.onSurface)),
                ),
              ),
            ),

            if (showQuickActions)
              Expanded(
                child: _buildQuickActionsSection(theme),
              ),
          ],
        ),
      ),
    );
  
  }


  Widget _buildQuickActionsSection(ColorScheme theme) {
  String userId = _auth.currentUser!.uid;

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('devices').where('userId', isEqualTo: userId).snapshots(),
    builder: (context, deviceSnapshot) {
      if (deviceSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!deviceSnapshot.hasData || deviceSnapshot.data == null || deviceSnapshot.data!.docs.isEmpty) {
        return const Center(child: Text("No devices found."));
      }

      var devices = deviceSnapshot.data!.docs;

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('groups').where('userId', isEqualTo: userId).snapshots(),
        builder: (context, groupSnapshot) {
          if (groupSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String?, List<DocumentSnapshot>> devicesByGroup = {};
          devicesByGroup[null] = []; // Initialize ungrouped list
          List<DocumentSnapshot> allGroups = [];
          Set<String> groupedDeviceIds = {}; // To track devices that are in ANY group

          if (groupSnapshot.hasData && groupSnapshot.data != null) {
            allGroups = groupSnapshot.data!.docs;

            for (var group in allGroups) {
              var groupData = group.data() as Map<String, dynamic>;
              String groupId = group.id;
              List<dynamic> deviceIds = groupData['devices'] ?? [];

              devicesByGroup[groupId] = devices.where((device) => deviceIds.contains(device.id)).toList();
              // Add deviceIds to the Set of grouped devices
              deviceIds.forEach((deviceId) => groupedDeviceIds.add(deviceId.toString())); // Ensure deviceId is String
            }
          }

          // After processing all groups, filter for ungrouped devices
          devicesByGroup[null] = devices.where((device) => !groupedDeviceIds.contains(device.id)).toList();


          return ListView(
            children: devicesByGroup.entries.map((entry) {
              String? groupId = entry.key;
              List<DocumentSnapshot> groupDevices = entry.value;
              String groupName = groupId != null
                  ? (allGroups.firstWhere((group) => group.id == groupId)['name'] ?? "Unknown Group")
                  : "Ungrouped Devices";

              // Only show "Ungrouped Devices" if there are any ungrouped devices
              if (groupId == null && groupDevices.isEmpty) {
                return const SizedBox.shrink(); // Return an empty widget if no ungrouped devices
              }


              return Card(
                color: theme.surfaceVariant,
                child: Column(
                  children: [
                    ListTile(title: Text(groupName)),
                    ...groupDevices.map((deviceDoc) {
                      var deviceData = deviceDoc.data() as Map<String, dynamic>?;
                      String deviceId = deviceDoc.id;
                      String deviceName = deviceData?['name'] ?? "Unknown Device";
                      bool isOn = deviceData?['status'] ?? false;

                      return ListTile(
                        leading: Icon(isOn ? Icons.power : Icons.power_off, size: 40, color: isOn ? Colors.green : Colors.red),
                        title: Text(deviceName),
                        subtitle: Text(isOn ? "ON" : "OFF"),
                        trailing: Switch(value: isOn, onChanged: (newValue) => toggleDevice(deviceId, isOn)),
                        tileColor: theme.surfaceVariant.withOpacity(0.5),
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),
          );
        },
      );
    },
  );
}
}