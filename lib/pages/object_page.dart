import 'package:esi_ui/xml_parsing.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ObjectList extends StatelessWidget {
  final DeviceData data;
  const ObjectList({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
        children: [
          for (SDO sdo in data.sdo ?? [])
            Column(children: [
              Text('Object Name: ${sdo.name}'),
              Text('BitSize    : ${sdo.bitSize}'),
              Text('Index    : ${sdo.index}'),
            ])
        ],
      ),
    );
  }
}

class DevicePlate extends StatelessWidget {
  final Device device;
  const DevicePlate({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    Image deviceImage = Image.network(
      'https://multimedia.beckhoff.com/media/el${device.type.substring(2)}_es${device.type.substring(2)}__web.jpg.webp',
      errorBuilder: (context, error, stackTrace) => const Text('Image not found'),
    );
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(device.type, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              device.url != null
                  ? MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => launchUrl(device.url!),
                        child: Text(device.url!.toString(), style: const TextStyle(color: Colors.blue)),
                      ),
                    )
                  : Container(),
            ]),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text('Product code: 0x${device.productCode?.toRadixString(16) ?? 'N/A'}'),
                    for (DeviceData data in device.data ?? [])
                      data.revision == null
                          ? const Text('N/A')
                          : MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                child: Text('Revision : 0x${data.revision!.toRadixString(16)}'),
                                onTap: () => showDialog(context: context, builder: (context) => ObjectList(data: data)),
                              ),
                            ),
                  ],
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    child: Image(
                      width: 360,
                      image: deviceImage.image,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(child: Image(image: deviceImage.image));
                        },
                      );
                    },
                  ),
                )
              ],
            )
          ],
        ),
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
    // TODO: Could be a listview builder for more performance
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Vendor: ${selectedFile!.vendor.name}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        for (var device in selectedFile!.devices) DevicePlate(device: device),
      ],
    );
  }
}
