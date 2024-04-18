import 'package:esi_ui/xml_parsing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  runApp(const EsiUi());
}

class EsiUi extends StatelessWidget {
  const EsiUi({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'ESI-UI',
      theme: MacosThemeData.dark(),
      home: const MainPage(),
    );
  }
}

class pdo_display_page extends StatelessWidget {
  const pdo_display_page({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: MacosColors.appleBrown);
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int pageIndex = 0;
  String? selectedFile;
  // Parsed file list
  @override
  void initState() {
    super.initState();
    // TODO: Do this inside a builder or something.
    // TODO: Add add file functionality with a file picker
    parseEsiFile('test/test_files/test.xml').then((value) => setState(() {
          files.addAll({value.name: value});
        }));
  }

  Map<String, EsiFile> files = {};
  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: const [],
      child: MacosWindow(
        sidebar: Sidebar(
            top: MacosSearchField(
              placeholder: 'Search',
              onResultSelected: (result) {
                switch (result.searchKey) {
                  case 'Buttons':
                    setState(() {
                      pageIndex = 0;
                    });
                    break;
                  case 'Indicators':
                    setState(() {
                      pageIndex = 1;
                    });
                    break;
                  case 'Fields':
                    setState(() {
                      pageIndex = 2;
                    });
                    break;
                  case 'Colors':
                    setState(() {
                      pageIndex = 3;
                    });
                    break;
                  case 'Dialogs and Sheets':
                    setState(() {
                      pageIndex = 4;
                    });
                    break;
                  case 'Toolbar':
                    setState(() {
                      pageIndex = 6;
                    });
                    break;
                  case 'ResizablePane':
                    setState(() {
                      pageIndex = 7;
                    });
                    break;
                  case 'Selectors':
                    setState(() {
                      pageIndex = 8;
                    });
                    break;
                }
              },
              results: const [
                SearchResultItem('Buttons'),
                SearchResultItem('Indicators'),
                SearchResultItem('Fields'),
                SearchResultItem('Colors'),
                SearchResultItem('Dialogs and Sheets'),
                SearchResultItem('Toolbar'),
                SearchResultItem('ResizablePane'),
                SearchResultItem('Selectors'),
              ],
            ),
            minWidth: 200,
            builder: (context, scrollController) {
              return SidebarItems(
                  currentIndex: pageIndex,
                  onChanged: (i) {
                    setState(() => pageIndex = i);
                  },
                  scrollController: scrollController,
                  itemSize: SidebarItemSize.large,
                  items: files.values
                      .map((e) => SidebarItem(leading: const MacosIcon(CupertinoIcons.square_on_square), label: Text(e.name), disclosureItems: [
                            const SidebarItem(
                              leading: MacosIcon(CupertinoIcons.selection_pin_in_out),
                              label: Text('pdo'),
                            ),
                            const SidebarItem(
                              leading: MacosIcon(CupertinoIcons.list_bullet),
                              label: Text('Objects'),
                            ),
                            const SidebarItem(
                              leading: MacosIcon(CupertinoIcons.person),
                              label: Text('Vendor'),
                            )
                          ]))
                      .toList());
            },
            bottom: GestureDetector(
                child: const MacosListTile(
                  leading: MacosIcon(CupertinoIcons.add),
                  title: Text('Add File'),
                  subtitle: Text('Add more files to ESI-UI'),
                ),
                onTap: () async {
                  //TODO: Look into other file picker libs. Needs some binary named zenity
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xml']);
                  if (result == null) {
                    return;
                  }
                  for (var file in result.files) {
                    if (file.path == null) {
                      continue;
                    }
                    try {
                      final EsiFile parsedFile = await parseEsiFile(file.path!);
                      setState(() {
                        files.addAll({parsedFile.name: parsedFile});
                      });
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  }
                })),
        endSidebar: Sidebar(
          startWidth: 200,
          minWidth: 200,
          maxWidth: 300,
          shownByDefault: false,
          builder: (context, _) {
            return const Center(
              child: Text('End Sidebar'),
            );
          },
        ),
        child: [
          CupertinoTabView(builder: (_) => const pdo_display_page()),
          const pdo_display_page(),
          const pdo_display_page(),
          const pdo_display_page(),
        ][pageIndex],
      ),
    );
  }
}
