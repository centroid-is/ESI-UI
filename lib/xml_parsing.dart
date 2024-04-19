import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

// Example of Object info
// <Info>
// 	<DefaultData>89139001</DefaultData>
// </Info>
// Second example
// <Info>
//   <SubItem>
//     <Name>SubIndex 000</Name>
//     <Info>
//       <DefaultData>01</DefaultData>
//     </Info>
//   </SubItem>
//   <SubItem>
//     <Name>SubIndex 001</Name>
//     <Info>
//       <DefaultData>00000000</DefaultData>
//     </Info>
//   </SubItem>
// </Info>

class Info {
  String? defaultData;
  List<SubItem>? subItems;
  Info({this.defaultData, this.subItems});
  @override
  String toString() {
    return 'DefaultData: $defaultData SubItems: [${(subItems ?? <SubItem>[]).map((element) => element.toString())}]';
  }
}

class SubItem {
  String name;
  Info info;
  SubItem({required this.name, required this.info});
  @override
  String toString() {
    return 'Name: $name DefaultData: $info';
  }
}

// Example of Flags
// <Flags>
//   <Access>rw</Access>
//   <Category>o</Category>
//   <Backup>1</Backup>
//   <Setting>1</Setting>
//   <PdoMapping>R</PdoMapping>
// </Flags>
class Flags {
  String access;
  String? category;
  int? backup;
  int? setting;
  String? pdoMapping;
  Flags(
      {required this.access,
      this.category,
      this.backup,
      this.setting,
      this.pdoMapping});
  @override
  String toString() {
    return 'Access: $access Category: $category Backup: $backup Setting: $setting PdoMapping: $pdoMapping';
  }
}

class SDO {
  String index;
  String name;
  String type;
  int bitSize;
  Flags flags;
  Info? info;
  SDO(
      {required this.index,
      required this.name,
      required this.type,
      required this.bitSize,
      required this.flags,
      this.info});
  @override
  String toString() {
    return 'Index: $index Name: $name Type: $type Bit size: $bitSize';
  }
}

// Example
// <RxPdo Fixed="1" Mandatory="1" Sm="2">
//   <Index>#x1600</Index>
//   <Name>AO Outputs Channel 1</Name>
//   <Entry>
//     <Index>#x7000</Index>
//     <SubIndex>17</SubIndex>
//     <BitLen>16</BitLen>
//     <Name>Analog output</Name>
//     <DataType DScale="0-10">INT</DataType>
//   </Entry>
// </RxPdo>
// <TxPdo Fixed="1" Sm="3">
//   <Index>#x1a00</Index>
//   <Name>AI Standard </Name>
//   <Exclude>#x1a01</Exclude>
//   <Entry>
//     <Index>#x6000</Index>
//     <SubIndex>1</SubIndex>
//     <BitLen>1</BitLen>
//     <Name>Underrange</Name>
//     <Comment>Underrange event active</Comment>
//     <DataType>BOOL</DataType>
//   </Entry>
//   <Entry>
//     <Index>#x0</Index>
//     <BitLen>7</BitLen>
//   </Entry>
// </TxPdo>

class Entry {
  String index;
  int bitLen;
  int? subIndex;
  String? name;
  String? dataType;
  String? comment;
  Entry(
      {required this.index,
      required this.bitLen,
      this.subIndex,
      this.name,
      this.dataType,
      this.comment});
}

class PDO {
  String index;
  String name;
  List<Entry> entries;
  PDO({required this.index, required this.name, required this.entries});
}

class Device {
  String name;
  String type;
  String? productCode;
  String? revision;
  List<SDO>? sdo;
  List<PDO>? rxPdo;
  List<PDO>? txPdo;

  Device(
      {required this.name,
      required this.type,
      this.productCode,
      this.revision,
      this.sdo});

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
  try {
    fileContents = await file.readAsString(encoding: utf8);
  } catch (exception) {
    if (exception is FileSystemException) {
      // String value was propably not utf-8 let's try iso-8859-1
      fileContents =
          await file.readAsString(encoding: Encoding.getByName('iso-8859-1')!);
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
        productCode: type.getAttribute('ProductCode'),
        revision: type.getAttribute('RevisionNo'),
        sdo: element.findAllElements('Object').map((objElement) {
          final info = objElement.getElement('Info');
          late Info? infoObj = null;
          if (info != null) {
            final subItems =
                info.findAllElements('SubItem').map((subItemElement) {
              final subItemInfo = subItemElement.getElement('Info')!;
              return SubItem(
                  name: subItemElement.getElement('Name')!.innerText,
                  info: Info(
                      defaultData:
                          subItemInfo.getElement('DefaultData')?.innerText));
            }).toList();
            infoObj = Info(
                defaultData: info.getElement('DefaultData')?.innerText,
                subItems: subItems);
          }
          final flagElement = objElement.getElement('Flags')!;
          final extractOptionalInt =
              (String? value) => value == null ? null : int.parse(value);

          final flags = Flags(
              access: flagElement.getElement('Access')!.innerText,
              category: flagElement.getElement('Category')?.innerText,
              backup: extractOptionalInt(
                  flagElement.getElement('Backup')?.innerText),
              setting: extractOptionalInt(
                  flagElement.getElement('Setting')?.innerText),
              pdoMapping: flagElement.getElement('PdoMapping')?.innerText);

          return SDO(
              index: objElement.getElement('Index')!.innerText,
              name: objElement.getElement('Name')!.innerText,
              type: objElement.getElement('Type')!.innerText,
              bitSize: int.parse(objElement.getElement('BitSize')!.innerText),
              flags: flags,
              info: infoObj);
        }).toList());
  });
  // devices.forEach(print);

  parseHexOrInt(String value) {
    if (value.startsWith('#x')) {
      return int.parse(value.substring(2), radix: 16);
    }
    return int.parse(value);
  }

  final vendorElement = ethercatInfoRoot.getElement('Vendor')!;
  final vendor = Vendor(
      id: parseHexOrInt(vendorElement.getElement('Id')!.innerText),
      name: vendorElement.getElement('Name')!.innerText);
  // TODO: Set a better name, vendor name? can have many files though
  return EsiFile(
      name: fileLocation.split('/').last,
      devices: devices.toList(),
      vendor: vendor);
}
