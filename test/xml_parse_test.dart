import 'dart:io';
import 'package:esi_ui/xml_parsing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Parse known good ESI files', () async {
    final dir = Directory('test/test_files/');
    final files = await dir.list().toList();
    for (var xmlFile in files) {
      print(xmlFile.path);
      final document = await parseEsiFile(xmlFile.path);
      print('parsed');
      expect(document.devices, isNotEmpty);
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}
