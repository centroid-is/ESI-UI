import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

class SDO {
  String index;
  String name;
  String type;
  int bitSize;
  SDO({required this.index, required this.name, required this.type, required this.bitSize});
  @override
  String toString() {
    return 'Index: $index Name: $name Type: $type Bit size: $bitSize';
  }
}

class Device {
  String name;
  String type;
  String productCode;
  String revision;
  List<SDO>? sdo;

  Device({required this.name, required this.type, required this.productCode, required this.revision, this.sdo});

  @override
  String toString() {
    return 'Name: $name Type: $type Product code: $productCode Revision: $revision SDO: [${(sdo ?? <SDO>[]).map((element) => element.toString())}]';
  }
}

class Vendor {
  int id;
  String name;
  Vendor({required this.id, required this.name});
}

class EsiFile {
  String name;
  Vendor vendor;
  List<Device> devices;
  EsiFile({required this.name, required this.vendor, required this.devices});
}

Future<EsiFile> parseEsiFile(String fileLocation) async {
  final file = File(fileLocation);
  String? fileContents; 

  // This try-catch is not great. Would maybe be an ok solution to require utf-8 formatted files.
  try{
    fileContents = await file.readAsString(encoding: utf8);
  } catch (exception){
    if (exception is FileSystemException) { // String value was propably not utf-8 let's try iso-8859-1
    fileContents = await file.readAsString(encoding: Encoding.getByName('iso-8859-1')!);
    }
  }
  final XmlDocument document = XmlDocument.parse(fileContents!);

  final ethercatInfoRoot = document.getElement('EtherCATInfo')!;
  final descriptionsNode = ethercatInfoRoot.getElement('Descriptions')!;
  final devicesNode = descriptionsNode.getElement('Devices')!;
  final deviceNodes = devicesNode.findElements('Device');

  final devices = deviceNodes.map((element) {
    final type = element.getElement('Type')!;
    return Device(
        name: element.getElement('Name')!.innerText,
        type: type.innerText,
        productCode: type.getAttribute('ProductCode')!,
        revision: type.getAttribute('RevisionNo')!,
        sdo: element
            .findAllElements('Object')
            .map((objElement) => SDO(
                  index: objElement.getElement('Index')!.innerText,
                  name: objElement.getElement('Name')!.innerText,
                  type: objElement.getElement('Type')!.innerText,
                  bitSize: int.parse(objElement.getElement('BitSize')!.innerText),
                ))
            .toList());
  });
  final vendorElement = ethercatInfoRoot.getElement('Vendor')!;
  final vendor = Vendor(id: int.parse(vendorElement.getElement('Id')!.innerText), name: vendorElement.getElement('Name')!.innerText);
  // TODO: Set a better name, vendor name? can have many files though
  return EsiFile(name: fileLocation.split('/').last, devices: devices.toList(), vendor: vendor);
}
