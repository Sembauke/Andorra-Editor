import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/editor_view_controller.dart';
import 'package:flutter_code_editor/editor/editor.dart';
import 'package:flutter_code_editor/editor/preview/preview.dart';
import 'package:flutter_code_editor/enums/language.dart';
import 'dart:developer' as dev;

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: EditorView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ignore: must_be_immutable
class EditorView extends StatefulWidget {
  const EditorView({
    Key? key,
    this.content = '',
  }) : super(key: key);

  final String content;

  @override
  State<StatefulWidget> createState() => EditorLayout();

  Widget build(BuildContext context) {
    return Scaffold(body: EditorLayout().widget);
  }
}

class EditorLayout extends State<EditorView> {
  @override
  Widget build(BuildContext context) {
    Editor editor = Editor(
      language: Language.html,
      content: widget.content,
      onChange: () {},
    );

    editor.onChange = () {
      dev.log(editor.getTextOnCurrentLine(editor.textController).toString());
    };

    return EditorViewController(
      editor: editor,
      codePreview: const CodePreview(),
    );
  }
}
