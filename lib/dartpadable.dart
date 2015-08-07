library gist.dartpadable;

import 'dart:io';

import 'package:path/path.dart' as path;

import 'analyzer.dart';

bool isDartpadAble(Directory dir, {bool verbose: false, bool dry_run: false}) {
  String dirName = path.relative(dir.path);

  String printDirName;
  if (dirName == '.') {
    printDirName = path.basename(Uri.base.path);
  } else {
    printDirName = dirName;
  }

  var children = dir.listSync(recursive: true);
  Directory web =
  children.firstWhere((entity) => entity is Directory && entity.path.endsWith('web'), orElse: () => null);

  // not dartpadable if there is no web dir
  if (web == null) {
    if (printDirName.startsWith('.')) {
      //don't show print message for hidden folders
    } else {
      if (verbose) {
        print('Skipping ${printDirName}: App contains no web directory.');
      }
    }
    return false;
  }

  if (!new File('$dirName/pubspec.yaml').existsSync()) {
    if (verbose) {
      print('Skipping ${printDirName}: App contains no pubspec.yaml file.');
    }
    return false;
  }

  List<File> files = web.listSync(recursive: true)..retainWhere((e) => e is File);

  // not dartpadable if there are more than 3 files
  if (files.length > 3) {
    print("Skipping ${printDirName}: Too many files.");
    return false;
  }

  // files can only have the name index.html/main.dart/styles.css
  if (!files.every((file) {
    var path = file.path;
    return path.endsWith('index.html') || path.endsWith('main.dart') || path.endsWith('styles.css');
  })) {
    print("Skipping ${printDirName}: Files can only have the name index.html/main.dart/styles.css.");
    return false;
  }

  // no packages can be imported, and dart:io can also not be imported
  File dartFile = new File('${dir.path}/web/main.dart');
  if (dartFile.existsSync()) {
    var analyzer = new AnalyzerUtil();
    List<String> libraries = analyzer.findLibraries(dartFile.readAsStringSync());
    if (libraries.any((l) => l == 'dart:io')) {
      print("Skipping ${printDirName}: A DartPad can't import dart:io.");
      return false;
    }
    if (libraries.any((l) => !l.startsWith('dart:'))) {
      print("Skipping ${printDirName}: A DartPad can't import packages.");
      return false;
    }
  }

  if (dry_run) {
    print('$printDirName is dartpadable');
  }

  // otherwise dartpadable, yeah :)
  return true;
}