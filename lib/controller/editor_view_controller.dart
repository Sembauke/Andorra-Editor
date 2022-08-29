import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/editor/editor.dart';
import 'package:flutter_code_editor/editor/file_explorer/file_explorer.dart';
import 'package:flutter_code_editor/editor/preview/preview.dart';
import 'package:flutter_code_editor/models/editor_options.dart';
import 'package:flutter_code_editor/models/file_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class EditorViewController extends StatefulWidget {
  EditorViewController({
    Key? key,
    required this.editor,
    this.recentlyOpenedFiles = const [],
    this.options = const EditorOptions(),
    this.file,
  }) : super(key: key);

  List<FileIDE> recentlyOpenedFiles;
  FileIDE? file;
  final EditorOptions options;

  Editor editor;

  @override
  State<StatefulWidget> createState() => EditorViewControllerState();

  Future<void> removeAllRecentlyOpenedFilesCache(String dirname) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getStringList('$dirname-recently-opened') != null) {
      prefs.remove('$dirname-recently-opened');
    }
  }
}

class EditorViewControllerState extends State<EditorViewController> {
  @override
  void initState() {
    super.initState();

    setRecentlyOpenedFilesInDir();
  }

  FileIDE cachedFileStringToFile(String fileString) {
    return FileIDE.fromJSON(json.decode(fileString));
  }

  Future<void> setRecentlyOpenedFilesInDir() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (widget.file == null) return;

    String key = (widget.file?.parentDirectory as String) + '-recently-opened';

    List<FileIDE> cache = prefs
            .getStringList(key)
            ?.map((file) => cachedFileStringToFile(file))
            .toList() ??
        [];

    List<String> cachedFileNames = cache.map((file) => file.fileName).toList();

    if (!cachedFileNames.contains(widget.file?.fileName)) {
      cache.add(widget.file as FileIDE);
    }

    List<String> cacheStringList = cache
        .map((file) => json.encode(FileIDE.fileToMap(file)).toString())
        .toList();

    prefs.setStringList(key, cacheStringList);

    setState(() {
      widget.recentlyOpenedFiles = cache;
    });
  }

  Future<void> removeRecentlyOpenedFile(String fileToClose) async {
    setState(() {
      widget.recentlyOpenedFiles = [];
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = (widget.file?.parentDirectory as String) + '-recently-opened';

    if (prefs.getStringList(key) != null) {
      List<String>? fileStrings = prefs.getStringList(key);

      if (fileStrings == null) return;

      for (int i = 0; i < fileStrings.length; i++) {
        var fileObject = json.decode(fileStrings[i]);

        FileIDE file = FileIDE.fromJSON(fileObject);

        if (file.fileName == fileToClose) {
          fileStrings.removeAt(i);

          prefs.setStringList(key, fileStrings);

          setState(() {
            widget.recentlyOpenedFiles = fileStrings
                .map((file) => cachedFileStringToFile(file))
                .toList();
          });

          break;
        }
      }
      pushNewView(widget.recentlyOpenedFiles[0]);
    }
  }

  bool fileIsFocused(String fileName) {
    return fileName == widget.file?.fileName;
  }

  int getActualTabLength() {
    int tabs = 1;
    widget.options.codePreview ? tabs = tabs + 1 : tabs = tabs;

    tabs = widget.options.customViews.length + tabs;

    return tabs;
  }

  void pushNewView(FileIDE tappedFile) {
    if (tappedFile.fileName == widget.file?.fileName) return;

    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
            transitionDuration: Duration.zero,
            pageBuilder: (context, animation1, animation2) =>
                EditorViewController(
                  file: tappedFile,
                  editor: widget.editor,
                  options: widget.options,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return widget.options.showAppBar || widget.options.showTabBar
        ? DefaultTabController(
            length: 2,
            child: Scaffold(
                extendBodyBehindAppBar: false,
                backgroundColor: widget.options.scaffoldBackgrounColor,
                drawer: widget.options.useFileExplorer
                    ? Drawer(child: FileExplorer())
                    : null,
                appBar: widget.options.showAppBar
                    ? AppBar(
                        title: Text(widget.file?.parentDirectory ?? ''),
                        leading: Builder(
                          builder: (BuildContext context) => IconButton(
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                              icon: const Icon(Icons.folder)),
                        ),
                        backgroundColor: widget.options.tabBarColor,
                        toolbarHeight: 50,
                      )
                    : null,
                body: DefaultTabController(
                    length: getActualTabLength(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: widget.options.tabBarColor,
                          height: 50,
                          child: fileTabBar(),
                        ),
                        Container(
                          height: 35,
                          color: widget.options.tabBarColor,
                          child: TabBar(tabs: <Text>[
                            for (int i = 0;
                                i < widget.options.customViewNames.length;
                                i++)
                              widget.options.customViewNames[i],
                            const Text('editor'),
                            const Text('preview'),
                          ]),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              for (int i = 0;
                                  i < widget.options.customViews.length;
                                  i++)
                                widget.options.customViews[i],
                              widget.editor,
                              CodePreview(
                                editor: widget.editor,
                                options: widget.options,
                                //consoleStream: widget.consoleStream,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ))))
        : Scaffold(
            body: widget.editor,
          );
  }

  ListView fileTabBar() {
    if (widget.recentlyOpenedFiles.isEmpty) {
      setRecentlyOpenedFilesInDir();
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      itemCount: widget.recentlyOpenedFiles.length,
      itemBuilder: (context, index) => Container(
        height: 25,
        constraints: const BoxConstraints(
          minWidth: 150,
        ),
        child: Container(
          padding: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
              border: fileIsFocused(widget.recentlyOpenedFiles[index].fileName)
                  ? const Border(
                      right: BorderSide(width: 2, color: Colors.white),
                      left: BorderSide(width: 2, color: Colors.white),
                      top: BorderSide(width: 2, color: Colors.white))
                  : const Border(
                      bottom: BorderSide(width: 2, color: Colors.white))),
          child: TextButton(
            onPressed: () {
              pushNewView(widget.recentlyOpenedFiles[index]);
            },
            style: TextButton.styleFrom(
                backgroundColor:
                    !fileIsFocused(widget.recentlyOpenedFiles[index].fileName)
                        ? widget.options.scaffoldBackgrounColor
                        : widget.options.tabBarColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.zero),
                )),
            child: Row(
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 75),
                  child: Text(
                    widget.recentlyOpenedFiles[index].fileName,
                    maxLines: 1,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                widget.recentlyOpenedFiles.length > 1 &&
                        widget.options.canCloseFiles
                    ? IconButton(
                        onPressed: () {
                          removeRecentlyOpenedFile(
                              widget.recentlyOpenedFiles[index].fileName);
                        },
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.only(left: 16))
                    : Container()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
