import 'package:flutter/material.dart';
import 'package:flutter_code_editor/controller/editor_view_controller.dart';
import 'package:flutter_code_editor/editor/editor.dart';
import 'package:flutter_code_editor/editor/preview/preview.dart';
import 'package:flutter_code_editor/enums/language.dart';
import 'package:rich_text_controller/rich_text_controller.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EditorView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ignore: must_be_immutable
class EditorView extends StatefulWidget {
  EditorView({
    Key? key,
  }) : super(key: key);

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
      onChange: () {},
    );

    editor.onChange = () {
      editor.returnEditorValue(editor.textController!.text);
    };

    return EditorViewController(
      editor: editor,
      codePreview: const CodePreview(),
    );
  }
}
