import 'dart:io';

/// Updates export statements in Dart [barrel files](https://medium.com/@ugamakelechi501/barrel-files-in-dart-and-flutter-a-guide-to-simplifying-imports-9b245dbe516a) within the current directory.
///
/// installation in cmd of M$ Windows:
/// $ cd <to this project directory>
/// REM add the current directory to the PATH environment variable
/// $ set PATH=%CD%;%PATH%
///
/// run (the update_exports.bat file):
/// 'export_statements'
void main(List<String> arguments) async {
  await exportBarrelFiles();
}

Future<void> exportBarrelFiles() async {
  final projectDir = Directory.current;

  final dartFiles =
      projectDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
  var found = false;
  for (final file in dartFiles) {
    final content = await file.readAsString();
    if (content.contains(RegExp('^export\\s+\'[^\']+\'', multiLine: true))) {
      found = true;
      await updateBarrelFile(projectDir, file);
    }
  }
  if (!found) {
    print('No export statements found in Dart files.');
  }
}

Future<void> updateBarrelFile(Directory projectDir, File barrelFile) async {
  final exportLines = <String>[];

  final barrelFileDir = barrelFile.parent;
  final subDirs = barrelFileDir.listSync().whereType<Directory>().toList();

  for (final dir in subDirs) {
    final dartFilesToExport = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    ;
    for (final dartFileToExport in dartFilesToExport) {
      String relativePath = _relativePath(dartFileToExport, projectDir);
      exportLines.add("export '$relativePath';");
    }
  }
  if (exportLines.isEmpty) {
    print('No files found in subdirectories of ${barrelFileDir.path}.');
    return;
  }
  final newContent = '${exportLines.join('\n')}\n';
  await barrelFile.writeAsString(newContent);
  print('Updated: ${barrelFile.path}');
}

String _relativePath(File dartFileToExport, Directory projectDir) {
  final relativePath = dartFileToExport.path
      .substring(projectDir.path.length + 1)
      .replaceAll('\\', '/');
  if (relativePath.startsWith('lib/')) {
    return relativePath.substring(4);
  }
  return relativePath;
}
