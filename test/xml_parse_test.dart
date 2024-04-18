import 'package:esi_ui/xml_parsing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Basic ESI fileformat tests', () async {
    const files = ['test/test_files/test.xml'];
    final document = await parseEsiFile(filePath);
    expect(document.devices, isNotEmpty);
    expect(document.vendor.name, 'Beckhoff Automation GmbH &amp; Co. KG');
    expect(document.vendor.id, 2);
  });
}
