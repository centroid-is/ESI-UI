import 'package:esi_ui/xml_parsing.dart';
import 'package:flutter/material.dart';

class DevicePlate extends StatelessWidget {
  final Device device;
  const DevicePlate({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format text large name and smaller extra info
          Text('Name: ${device.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Type: ${device.type}'),
              Text('Product code: ${device.productCode}'),
              Text('Revision: ${device.revision}'),
            ],
          )
        ],
      ),
    );
  }
}

class object_display_page extends StatelessWidget {
  final EsiFile? selectedFile;
  const object_display_page({super.key, this.selectedFile});

  @override
  Widget build(BuildContext context) {
    if (selectedFile == null) return const Text('No file selected');
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [Text('Vendor: ${selectedFile!.vendor.name}'), const Text('Devices:'), for (var device in selectedFile!.devices) DevicePlate(device: device)],
    );
    // return ListView.builder(itemBuilder: (context, count) {
    //   debugPrint(count.toString());
    //   return Container(color: MacosColors.appleCyan);
    // });
  }
}
