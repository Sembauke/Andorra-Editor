// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/editor_view_controller.dart';
import 'package:flutter_code_editor/editor/editor.dart';
import 'package:flutter_code_editor/models/editor_options.dart';
import 'package:flutter_code_editor/models/file_model.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Editor editor = Editor(
      language: 'html',
      openedFile: FileIDE(
        fileContent: 'hello',
        fileExplorer: null,
        fileName: '',
        filePath: '',
        parentDirectory: '',
      ),
    );

    EditorViewController controller = EditorViewController(
        options: const EditorOptions(
          canCloseFiles: false,
          showAppBar: false,
          showTabBar: false,
        ),
        editor: editor);

    return MaterialApp(
      home: Row(
        children: [
          Expanded(child: controller),
        ],
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
