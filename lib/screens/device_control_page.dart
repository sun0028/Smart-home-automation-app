import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceControlPage extends StatefulWidget {
  const DeviceControlPage({super.key});

  @override
  _DeviceControlPageState createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0; // 0 = All Devices, 1 = Groups

  @override
  Widget build(BuildContext context) {
    // ... (build method remains the same)
    return Scaffold(
      appBar: AppBar(title: const Text("Device Control")),
      body: Column(
        children: [
          ToggleButtons(
            isSelected: [_selectedIndex == 0, _selectedIndex == 1],
            onPressed: (index) => setState(() => _selectedIndex = index),
            children: const [
              Padding(padding: EdgeInsets.all(8.0), child: Text("All Devices")),
              Padding(padding: EdgeInsets.all(8.0), child: Text("Groups")),
            ],
          ),
          Expanded(
            child: _selectedIndex == 0 ? _buildAllDevices() : _buildGroups(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: const Icon(Icons.add),
      ),
    );

  }

  void _showAddOptions() {
    // ... (_showAddOptions remains the same)

   showModalBottomSheet(
    context: context,
    builder: (context) => Wrap(
      children: [
        ListTile(
          leading: const Icon(Icons.device_hub),
          title: const Text("Add Device"),
          onTap: () {
            Navigator.pop(context);
            _addDevice();
          },
        ),
        ListTile(
          leading: const Icon(Icons.group),
          title: const Text("Add Group"),
          onTap: () {
            Navigator.pop(context);
            _addGroup();
          },
        ),
        // Removed the "Add Device to Group" ListTile here
      ],
    ),
  );

  }


  void _removeDeviceFromGroup(String groupId, String deviceId, String deviceName) async {
  DocumentSnapshot groupDoc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
  List devices = groupDoc.get('devices');
  devices.remove(deviceId);
  await FirebaseFirestore.instance.collection('groups').doc(groupId).update({'devices': devices});
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Device "$deviceName" removed from group.')));
}

  Widget _buildAllDevices() {
   
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('devices')
          .where('userId', isEqualTo: _auth.currentUser!.uid) // Query by userId
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No devices found."));
        }

      final devices = snapshot.data!.docs;

      return ListView(
        children: devices.map((device) {
          var data = device.data() as Map<String, dynamic>;
          return ListTile(
            title: Text(data['name'] ?? "Unknown"),
            subtitle: Text("Status: ${data['status'] ? 'On' : 'Off'}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editDevice(device.id, data),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteDevice(device.id),
                ),
                IconButton( // Add Device to Group button
                  icon: const Icon(Icons.group_add),
                  onPressed: () => _addDeviceToGroup(deviceId: device.id, 
                  deviceName: data['name'] ?? "Unknown", // Handle potential null
                   ),
                ),
                Switch(
                  value: data['status'] ?? false,
                  onChanged: (value) => _toggleDevice(device.id, value),
                ),
              ],
            ),
          );
        }).toList(),
      );
    },
  );

  }

Widget _buildGroups() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('groups').where('userId', isEqualTo: _auth.currentUser!.uid).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.data!.docs.isEmpty) {
        return const Center(child: Text("No groups found."));
      }
      final groups = snapshot.data!.docs;

      return ListView(
        children: groups.map((group) {
          var data = group.data() as Map<String, dynamic>;
          return Theme(
            data: Theme.of(context).copyWith(
              cardColor: Theme.of(context).colorScheme.surfaceVariant,
              dividerColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            child: ExpansionTile(
              title: Text(data['name'] ?? "Unknown"),
              children: [
                Material( // Use Material for consistent background
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: SwitchListTile(
                    title: const Text("All Devices"),
                    value: data['status'] ?? false,
                    onChanged: (value) {
                      _toggleGroupDevices(value, data['devices']);
                      FirebaseFirestore.instance
                          .collection('groups')
                          .doc(group.id)
                          .update({'status': value});
                    },
                  ),
                ),
                ..._buildGroupDeviceList(group.id, data['devices']),
              ],
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editGroup(group.id, data),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteGroup(group.id),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}


 List<Widget> _buildGroupDeviceList(String groupId, List<dynamic>? deviceIds) {
  if (deviceIds == null || deviceIds.isEmpty) {
    return [const ListTile(title: Text("No devices in this group."))];
  }

  return deviceIds.map((deviceId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('devices').doc(deviceId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const ListTile(title: Text("Device not found or deleted."));
        }

        var deviceData = snapshot.data!.data() as Map<String, dynamic>?;

        return ListTile(
          title: Text(deviceData?['name'] ?? "Unknown"),
          tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5), // Lighter tile color
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _removeDeviceFromGroup(groupId, deviceId, deviceData?['name'] ?? "Unknown"),
              ),
              Switch(
                value: deviceData?['status'] ?? false,
                onChanged: (value) => _toggleDevice(deviceId, value),
              ),
            ],
          ),
        );
      },
    );
  }).toList();
}

  void _deleteGroup(String groupId) {
  FirebaseFirestore.instance.collection('groups').doc(groupId).delete();
}


  void _toggleGroupDevices(bool status, List<dynamic>? deviceIds) { // groupId removed
  if (deviceIds != null) {
    for (var deviceId in deviceIds) {
      _toggleDevice(deviceId, status); 
    }
  }
}

  void _toggleDevice(String deviceId, bool status) {
  FirebaseFirestore.instance.collection('devices').doc(deviceId).update({'status': status});
}

  void _deleteDevice(String deviceId) {
    // ... (_deleteDevice remains the same)
  FirebaseFirestore.instance.collection('groups').where('devices', arrayContains: deviceId).get().then((querySnapshot) {
      for (var groupDoc in querySnapshot.docs) {
        List devices = groupDoc.data()['devices'];
        devices.remove(deviceId);
        FirebaseFirestore.instance.collection('groups').doc(groupDoc.id).update({'devices': devices});
      }
    });

    FirebaseFirestore.instance.collection('devices').doc(deviceId).delete();

  }

  void _editDevice(String deviceId, Map<String, dynamic> data) {
    TextEditingController nameController = TextEditingController(text: data['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Device"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Device Name"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('devices')
                  .doc(deviceId)
                  .update({'name': nameController.text});
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _editGroup(String groupId, Map<String, dynamic> data) {
    TextEditingController nameController = TextEditingController(text: data['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Group"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Group Name"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('groups')
                  .doc(groupId)
                  .update({'name': nameController.text});
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _addDevice() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Device"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Device Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('devices').add({
                'name': nameController.text,
                'status': false,
                'userId': _auth.currentUser!.uid, // Add userId
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _addGroup() {
   TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Group"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Group Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('groups').add({
                'name': nameController.text,
                'devices': [],
                'status': false,
                'userId': _auth.currentUser!.uid,
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );  
  }

  void _addDeviceToGroup({required String deviceId, required String deviceName}) async {
   String userId = _auth.currentUser!.uid;
  
  QuerySnapshot groupsSnapshot =
      await FirebaseFirestore.instance.collection('groups').where('userId', isEqualTo: userId).get();

  if (groupsSnapshot.docs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No groups available. Add a group first.')));
    return;
  }

  String? selectedGroupId;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Add '$deviceName' to Group"), // Display device name
      content: StatefulBuilder(
        builder: (context, setState) {
          return DropdownButton<String>(
            hint: const Text("Select Group"),
            value: selectedGroupId,
            items: groupsSnapshot.docs.map((group) {
              return DropdownMenuItem<String>(
                value: group.id,
                child: Text(group.get('name')),
              );
            }).toList(),
            onChanged: (groupId) => setState(() => selectedGroupId = groupId),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            if (selectedGroupId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Please select a group.')));
              return;
            }

            DocumentSnapshot groupDoc = await FirebaseFirestore.instance
                .collection('groups')
                .doc(selectedGroupId)
                .get();
            List devices = groupDoc.get('devices') ?? [];
            if (!devices.contains(deviceId)) {
              devices.add(deviceId);
              await FirebaseFirestore.instance
                  .collection('groups')
                  .doc(selectedGroupId)
                  .update({'devices': devices});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Device "$deviceName" added to group.')));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Device is already in this group.')));
            }
          },
          child: const Text("Add"),
        ),
      ],
    ),
  );
}
  
}