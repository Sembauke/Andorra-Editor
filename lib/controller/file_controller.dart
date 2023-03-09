// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_code_editor/editor/file_explorer/file_explorer.dart';
// import 'package:flutter_code_editor/models/directory_model.dart';
// import 'package:flutter_code_editor/models/file_model.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class FileController {
//   FileController({required this.fileExplorer});

//   FileExplorer? fileExplorer;

//   Future<String> initProjectsDirectory() async {
//     Directory appDocDir = await getApplicationDocumentsDirectory();

//     final Directory _appDocDirFolder = Directory('${appDocDir.path}/projects');

//     if (!await _appDocDirFolder.exists()) {
//       final Directory _appDocDirNewFolder =
//           await _appDocDirFolder.create(recursive: true);
//       return _appDocDirNewFolder.path;
//     }

//     return _appDocDirFolder.path;
//   }

//   static Future<String> readFile(String filePath) async {
//     final File file = File(filePath);

//     return await file.readAsString();
//   }

//   static Future<void> createNewDir(String path, String name) async {
//     final Directory _dir = Directory('$path/$name');

//     if (!await _dir.exists()) {
//       await _dir.create(recursive: true);
//     }
//   }

//   static Future<void> createFile(String name, [String? path]) async {
//     path ??= await returnRootPath();

//     final File _file = File('$path/$name');

//     if (!await _file.exists()) {
//       await _file.create(recursive: true);
//     }
//   }

//   static Future<void> writeFile(String filePath, String content) async {
//     final File file = File(filePath);

//     if (file.existsSync()) {
//       file.writeAsString(content);
//     }
//   }

//   static Future<void> deleteDir(String path) async {
//     final Directory _dir = Directory(path);

//     await _dir.delete();
//   }

//   static Future<void> deleteFile(String path) async {
//     final File _file = File(path);

//     await _file.delete();
//   }

//   static Future<String> returnRootPath() async {
//     Directory dir = await getApplicationDocumentsDirectory();

//     return '${dir.path}/projects';
//   }

//   Future<bool> getDirectoryOpenClosedState(String directoryPath) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     if (prefs.getString(directoryPath) == null) {
//       prefs.setString(directoryPath, 'false');
//       return false;
//     }

//     if (prefs.getString(directoryPath) == 'true') {
//       return true;
//     }

//     return false;
//   }

//   Future<List<Widget>> listProjects(String path) async {
//     final List<FileSystemEntity> projectPaths = Directory(path).listSync();
//     List<Widget> projects = [];

//     for (int i = 0; i < projectPaths.length; i++) {
//       String path = projectPaths[i].path;

//       if (await Directory(path).exists()) {
//         projects.add(DirectoryIDE(
//             fileExplorer: fileExplorer,
//             directoryName: path.split("/").last,
//             directoryOpen: await getDirectoryOpenClosedState(path),
//             directoryPath: path,
//             directoryContent: await listProjects(path)));
//       } else {
//         projects.add(FileIDE(
//             fileExplorer: fileExplorer,
//             fileName: path.split("/").last,
//             filePath: path,
//             parentDirectory: path.split("/")[path.split("/").length - 2],
//             fileContent: await readFile(path)));
//       }
//     }

//     return projects;
//   }
// }
