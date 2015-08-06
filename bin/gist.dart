import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gist/analyzer.dart';
import 'package:gist/dart_sample.dart';
import 'package:gist/github.dart';
import 'package:github/server.dart';
import 'package:path/path.dart' as path;
import 'package:prompt/prompt.dart';

void main(List<String> arguments) {
  new CommandRunner('gist', 'Gist manager.')
    ..addCommand(new Generate())
    ..run(arguments);
}

class Generate extends Command {
  String name = "generate";

  String description = 'Generate gists from the current directory.';

  bool get debug => argResults['debug'];

  Generate() {

    argParser.addFlag("debug", abbr: 'd', help: "Show all the skipping messages.");
    String token = askSync('Create a github token here:\n'
        'https://github.com/settings/tokens\n'
        'Github Token:');
    Authentication auth = new Authentication.withToken(token);
    gitHub = createGitHubClient(auth: auth);
  }

  run() async {
    Directory root = new Directory('.');
    List<Directory> allDirectories = root.listSync(recursive: true)..retainWhere((entity) => entity is Directory);

    bool pubspecInRoot = new File('./pubspec.yaml').existsSync();

    // Generate a gist from the root if a pubspec.yaml file is in the root
    if (pubspecInRoot) {
      if (_isDartpadAble(root)) {
        DartSample sample = new DartSample(root);
        await sample.generateGist();
      }
    } else {
      // if there is no pubspec.yaml file in the root
      // check if the project contains dartpadable directories
      var dartpadAbleSamples = allDirectories..retainWhere(_isDartpadAble);

      for (Directory sampleDir in dartpadAbleSamples) {
        DartSample sample = new DartSample(sampleDir);
        await sample.generateGist();
      }
    }


    exit(0);
  }

  bool _isDartpadAble(Directory dir) {
    String dirName = path.relative(dir.path);
    if (dirName == '.') {
      dirName = path.basename(Uri.base.path);
    }

    var children = dir.listSync(recursive: true);
    Directory web =
        children.firstWhere((entity) => entity is Directory && entity.path.endsWith('web'), orElse: () => null);

    // not dartpadable if there is no web dir
    if (web == null) {
      if (dirName.startsWith('.')) {
        //don't show print message for hidden folders
      }
      else {
        if (debug) {
          print('Skipping ${dirName}: App contains no web directory.');
        }
      }
      return false;
    }

    if (! new File('$dirName/pubspec.yaml').existsSync()) {
      if (debug) {
        print('Skipping ${dirName}: App contains no pubspec.yaml file.');
      }
      return false;
    }

    List<File> files = web.listSync(recursive: true)..retainWhere((e) => e is File);

    // not dartpadable if there are more than 3 files
    if (files.length > 3) {
      print("Skipping ${dirName}: Too many files.");
      return false;
    }

    // files can only have the name index.html/main.dart/styles.css
    if (!files.every((file) {
      var path = file.path;
      return path.endsWith('index.html') || path.endsWith('main.dart') || path.endsWith('styles.css');
    })) {
      print("Skipping ${dirName}: Files can only have the name index.html/main.dart/styles.css.");
      return false;
    }

    // no packages can be imported, and dart:io can also not be imported
    File dartFile = new File('${dir.path}/web/main.dart');
    if (dartFile.existsSync()) {
      var analyzer = new AnalyzerUtil();
      List<String> libraries = analyzer.findLibraries(dartFile.readAsStringSync());
      if (libraries.any((l) => l == 'dart:io')) {
        print("Skipping ${dirName}: Dartpads can't import dart:io.");
        return false;
      }
      if (libraries.any((l) => !l.startsWith('dart:'))) {
        print("Skipping ${dirName}: Dartpads can't import packages.");
        return false;
      }
    }

    // otherwise dartpadable, yeah :)
    return true;
  }
}
