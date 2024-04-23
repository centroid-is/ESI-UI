import 'dart:async';

import 'package:adwaita/adwaita.dart';
import 'package:esi_ui/xml_parsing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:libadwaita/libadwaita.dart';
import 'package:libadwaita_window_manager/libadwaita_window_manager.dart';
import 'package:universal_io/io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import 'pages/object_page.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1000, 600),
    minimumSize: Size(400, 450),
    skipTaskbar: false,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'Libadwaita Example',
  );

  unawaited(
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (Platform.isLinux || Platform.isMacOS) {
        await windowManager.setAsFrameless();
      }
      await windowManager.show();
      await windowManager.focus();
    }),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          builder: (context, child) {
            final virtualWindowFrame = VirtualWindowFrameInit();

            return virtualWindowFrame(context, child);
          },
          theme: AdwaitaThemeData.light(),
          darkTheme: AdwaitaThemeData.dark(),
          debugShowCheckedModeBanner: false,
          home: MainPage(themeNotifier: themeNotifier),
          themeMode: currentMode,
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.themeNotifier});

  final ValueNotifier<ThemeMode> themeNotifier;
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late ScrollController listController;
  late ScrollController settingsController;
  late FlapController _flapController;
  int? _currentIndex = 0;

  EsiFile? selectedFile;
  // Parsed file list
  @override
  void initState() {
    super.initState();
    listController = ScrollController();
    settingsController = ScrollController();
    _flapController = FlapController();
    _flapController.addListener(() => setState(() {}));
    // TODO: Do this inside a builder or something.
    // TODO: Add add file functionality with a file picker
    parseEsiFile('test/test_files/Beckhoff EL4xxx.xml').then((value) => setState(() {
          files.addAll({value.name: value});
        }));
  }

  @override
  void dispose() {
    listController.dispose();
    settingsController.dispose();
    super.dispose();
  }

  void changeTheme() => widget.themeNotifier.value = widget.themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

  Map<String, EsiFile> files = {};
  @override
  Widget build(BuildContext context) {
    final developers = {'Jón Bjarni Bjarnason': 'jbbjarnason', 'Ómar Högni Guðmarsson': 'omarhogni'};
    return AdwScaffold(
      flapController: _flapController,
      actions: AdwActions().windowManager,
      start: [
        AdwHeaderButton(
          icon: const Icon(Icons.view_sidebar_outlined, size: 19),
          isActive: _flapController.isOpen,
          onPressed: () => _flapController.toggle(),
        ),
        AdwHeaderButton(
          icon: Icon(widget.themeNotifier.value == ThemeMode.light ? Icons.nightlight_round : Icons.sunny, size: 15),
          onPressed: changeTheme,
        ),
      ],
      title: const Text('ESI-UI'),
      end: [
        MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
                child: const Icon(Icons.add),
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
        GtkPopupMenu(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdwButton.flat(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    files.clear();
                  });
                },
                padding: AdwButton.defaultButtonPadding.copyWith(
                  top: 10,
                  bottom: 10,
                ),
                child: const Text(
                  'Remove all files',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              const Divider(),
              // AdwButton.flat(
              //   padding: AdwButton.defaultButtonPadding.copyWith(
              //     top: 10,
              //     bottom: 10,
              //   ),
              //   child: const Text(
              //     'Preferences',
              //     style: TextStyle(fontSize: 15),
              //   ),
              // ),
              AdwButton.flat(
                padding: AdwButton.defaultButtonPadding.copyWith(
                  top: 10,
                  bottom: 10,
                ),
                onPressed: () => showDialog<Widget>(
                  context: context,
                  builder: (ctx) => AdwAboutWindow(
                    issueTrackerLink: 'https://github.com/skaginn3x/esi-ui/issues',
                    appIcon: const Icon(Icons.run_circle_sharp), //Image.asset('assets/logo.png'),
                    credits: [
                      AdwPreferencesGroup.creditsBuilder(
                        title: 'Developers',
                        itemCount: developers.length,
                        itemBuilder: (_, index) => AdwActionRow(
                          title: developers.keys.elementAt(index),
                          onActivated: () => launchUrl(
                            Uri.parse(
                              'https://github.com/${developers.values.elementAt(index)}',
                            ),
                          ),
                        ),
                      ),
                    ],
                    copyright: 'Copyright 2024 Skaginn3x',
                    license: const Text(
                      'MIT License, This program comes with no warranty.',
                    ),
                  ),
                ),
                child: const Text(
                  'About this Demo',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ],
      flap: (isDrawer) => AdwSidebar(
        currentIndex: _currentIndex,
        isDrawer: isDrawer,
        children: files.values.map((e) => AdwSidebarItem(leading: const Icon(Icons.inbox_sharp), label: e.name)).toList(),
        onSelected: (index) => setState(() {
          _flapController.close();
          _currentIndex = index;
        }),
      ),
      body: AdwViewStack(
          animationDuration: const Duration(milliseconds: 100),
          index: _currentIndex,
          children: files.isEmpty ? [const Text('No file selected')] : files.values.map((value) => object_display_page(selectedFile: value)).toList()),
    );
  }
}
