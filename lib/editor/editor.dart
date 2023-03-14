import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_code_editor/controller/custom_text_controller/custom_text_controller.dart';
import 'package:flutter_code_editor/editor/linebar/linebar_helper.dart';
import 'package:flutter_code_editor/models/editor_options.dart';
import 'package:flutter_code_editor/models/file_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Editor extends StatefulWidget {
  Editor({
    Key? key,
    required this.options,
    required this.language,
  }) : super(key: key);

  // the coding language in the editor

  String language;

  // A stream where the text in the editor is changable

  StreamController<FileIDE> fileTextStream =
      StreamController<FileIDE>.broadcast();

  // A stream where you can listen to the changes made in the editor
  StreamController<String> onTextChange = StreamController<String>.broadcast();

  // options of the editor

  EditorOptions options = EditorOptions();

  @override
  State<StatefulWidget> createState() => EditorState();
}

class EditorState extends State<Editor> {
  ScrollController scrollController = ScrollController();
  ScrollController horizontalController = ScrollController();
  ScrollController linebarController = ScrollController();

  TextEditingControllerIDE beforeController = TextEditingControllerIDE();
  TextEditingControllerIDE inController = TextEditingControllerIDE();
  TextEditingControllerIDE afterController = TextEditingControllerIDE();

  int _currNumLines = 1;

  double _initialWidth = 28;

  String currentFileId = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
    horizontalController.dispose();
    linebarController.dispose();

    beforeController.dispose();
    inController.dispose();
    afterController.dispose();

    widget.onTextChange.close();
    widget.fileTextStream.close();
  }

  void updateLineCount(FileIDE file, String event) async {
    String lines = beforeController.text + event + afterController.text;

    setState(() {
      _currNumLines = lines.split('\n').length + (file.hasRegion ? 2 : 0);
    });
  }

  double getTextHeight(BuildContext context, {double fontSize = 18}) {
    double systemFontSize = MediaQuery.of(context).textScaleFactor;

    double calculatedFontSize =
        systemFontSize > 1 ? fontSize * systemFontSize : fontSize;

    Size textHeight = Linebar.calculateTextSize(
      'L',
      style: TextStyle(
        color: widget.options.linebarTextColor,
        fontSize: calculatedFontSize,
      ),
      context: context,
    );

    return textHeight.height;
  }

  handleFileInit(FileIDE file) {
    String fileContent = file.content;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      handleRegionFields(file);
      if (file.hasRegion) {
        Future.delayed(const Duration(seconds: 0), () {
          double offset = fileContent
                  .split('\n')
                  .sublist(0, file.region.start! - 1)
                  .length *
              getTextHeight(context);
          scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );

          scrollController.addListener(() {
            linebarController.jumpTo(scrollController.offset);
          });
        });
      }
    });

    TextEditingControllerIDE.language = widget.language;
  }

  handleRegionFields(FileIDE file) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (file.hasRegion) {
      int regionStart = file.region.start!;
      int regionEnd;

      if (prefs.get(file.id) != null) {
        regionEnd = int.parse(prefs.getString(file.id) ?? '');
      } else {
        regionEnd = file.region.end!;
      }

      if (file.content.split('\n').length > 1) {
        String beforeEditableRegionText =
            file.content.split("\n").sublist(0, regionStart).join("\n");

        String inEditableRegionText = file.content
            .split("\n")
            .sublist(regionStart, regionEnd - 1)
            .join("\n");

        String afterEditableRegionText = file.content
            .split("\n")
            .sublist(regionEnd - 1, file.content.split("\n").length)
            .join("\n");
        beforeController.text = beforeEditableRegionText;
        inController.text = inEditableRegionText;
        afterController.text = afterEditableRegionText;
      }
    } else {
      beforeController.text = '';
      inController.text = file.content;
      afterController.text = '';
    }

    setState(() {
      _currNumLines = file.content.split("\n").length;
    });
  }

  handleRegionCaching(FileIDE file, String event) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    int inRegionLines = event.split('\n').length + 1;
    int beforeRegionLines = beforeController.text.split('\n').length;

    int newRegionlines = inRegionLines + beforeRegionLines;

    if (prefs.get(file.id) != null) {
      prefs.setString(
        file.id,
        newRegionlines.toString(),
      );
    } else {
      prefs.setString(
        file.id,
        newRegionlines.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FileIDE>(
      stream: widget.fileTextStream.stream,
      builder: (context, snapshot) {
        FileIDE? file;

        if (snapshot.hasData) {
          if (snapshot.data is FileIDE) {
            file = snapshot.data as FileIDE;

            if (file.id != currentFileId) {
              handleFileInit(file);
              currentFileId = file.id;
            }

            TextEditingControllerIDE.language = file.ext;
          } else {
            return const Center(
              child: Text('Something went wrong'),
            );
          }

          return Row(
            children: [
              Container(
                constraints: BoxConstraints(
                  minWidth: 1,
                  maxWidth: _initialWidth,
                ),
                decoration: BoxDecoration(
                  color: widget.options.linebarColor,
                  border: const Border(
                    right: BorderSide(
                      color: Color.fromRGBO(0x88, 0x88, 0x88, 1),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 10,
                  ),
                  child: linecountBar(),
                ),
              ),
              Expanded(
                child: editorView(context, file),
              )
            ],
          );
        }

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget editorView(BuildContext context, FileIDE file) {
    return ListView(
      padding: const EdgeInsets.only(top: 0),
      scrollDirection: Axis.horizontal,
      controller: horizontalController,
      children: [
        SizedBox(
          height: 1000,
          width: widget.options.minHeight,
          child: ListView(
            padding: const EdgeInsets.only(
              top: 0,
            ),
            controller: scrollController,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            children: [
              if (file.hasRegion)
                SizedBox(
                  width: widget.options.minHeight,
                  child: TextField(
                    controller: beforeController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      fillColor: widget.options.editorBackgroundColor,
                      filled: true,
                      isDense: true,
                      contentPadding: const EdgeInsets.only(
                        top: 10,
                        left: 10,
                      ),
                    ),
                    enabled: false,
                    maxLines: null,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              Container(
                width: widget.options.minHeight,
                decoration: file.hasRegion
                    ? BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            width: 5,
                            color: widget.options.region!.condition
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      )
                    : null,
                child: TextField(
                  controller: inController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    fillColor: file.hasRegion
                        ? file.region.color
                        : widget.options.editorBackgroundColor,
                    filled: true,
                    isDense: true,
                    contentPadding: EdgeInsets.only(
                      left: 10,
                      top: file.hasRegion ? 0 : 10,
                    ),
                  ),
                  onChanged: (String event) async {
                    updateLineCount(file, event);

                    if (file.hasRegion) {
                      handleRegionCaching(
                        file,
                        event,
                      );
                    }

                    String text = beforeController.text +
                        '\n' +
                        event +
                        '\n' +
                        afterController.text;

                    widget.onTextChange.sink.add(text);
                  },
                  maxLines: null,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              if (file.hasRegion)
                SizedBox(
                  width: widget.options.minHeight,
                  child: TextField(
                    controller: afterController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      filled: true,
                      fillColor: widget.options.editorBackgroundColor,
                      contentPadding: const EdgeInsets.only(
                        left: 10,
                      ),
                      isDense: true,
                    ),
                    enabled: false,
                    maxLines: null,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
            ],
          ),
        )
      ],
    );
  }

  linecountBar() {
    return Column(
      children: [
        Flexible(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            controller: linebarController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currNumLines == 0 ? 1 : _currNumLines,
            itemBuilder: (_, i) => Linebar(
              calculateBarWidth: () {
                if (i + 1 > 9) {
                  SchedulerBinding.instance.addPostFrameCallback(
                    (timeStamp) {
                      setState(() {
                        _initialWidth = getTextHeight(context) + 2;
                      });
                    },
                  );
                }
              },
              child: Text(
                i == 0 ? (1).toString() : (i + 1).toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: widget.options.linebarTextColor,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
