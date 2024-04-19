import 'package:esi_ui/xml_parsing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

void main() async {
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

class object_display_page extends StatelessWidget {
  final EsiFile? selectedFile;
  const object_display_page({super.key, this.selectedFile});

  @override
  Widget build(BuildContext context) {
    if (selectedFile == null) return const Text('No file selected');
    return Container(color: MacosColors.appleMagenta);
    // return ListView.builder(itemBuilder: (context, count) {
    //   debugPrint(count.toString());
    //   return Container(color: MacosColors.appleCyan);
    // });
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int pageIndex = 0;
  EsiFile? selectedFile;
  final _controller = MacosTabController(
    initialIndex: 0,
    length: 3,
  );
  // Parsed file list
  @override
  void initState() {
    super.initState();
    // TODO: Do this inside a builder or something.
    // TODO: Add add file functionality with a file picker
    parseEsiFile('test/test_files/Beckhoff EL4xxx.xml').then((value) => setState(() {
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
                debugPrint('searched for $result');
              },
              results: const [
                // Could use this to filter files when we have allot of them
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
                    setState(() {
                      selectedFile = files.values.elementAt(i);
                      pageIndex = i;
                    });
                  },
                  scrollController: scrollController,
                  itemSize: SidebarItemSize.medium,
                  items: files.values.map((e) => SidebarItem(leading: const MacosIcon(CupertinoIcons.square_on_square), label: Text(e.name))).toList());
            },
            bottom: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
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
                    }))),
        endSidebar: Sidebar(
          startWidth: 200,
          minWidth: 200,
          maxWidth: 300,
          shownByDefault: false,
          builder: (context, _) {
            return Center(
                child: Container(
              color: MacosColors.appleCyan,
              child: const Text('End Sidebar'),
            ));
          },
        ),
        child: MacosTabView(
            controller: _controller,
            tabs: const [MacosTab(label: 'Objects'), MacosTab(label: 'Vendor'), MacosTab(label: 'Pdo?')],
            children: [object_display_page(selectedFile: selectedFile), Container(color: MacosColors.appleBlue), Container(color: MacosColors.appleRed)]),
      ),
    );
  }
}
