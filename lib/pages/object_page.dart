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
