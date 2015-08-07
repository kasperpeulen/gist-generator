import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:args/src/arg_parser.dart';
import 'package:gist/analyzer.dart';
import 'package:gist/dart_sample.dart';
import 'package:gist/github.dart';
import 'package:github/server.dart';
import 'package:path/path.dart' as path;
import 'package:prompt/prompt.dart';

main(List<String> arguments) async {
  try {
    var runner = new CommandRunner('gist', 'Gist manager.')
      ..addCommand(new Generate());
     await runner.run(arguments);
  } catch(e) {
    print(e);
  }
}

class Generate extends Command {
  String name = "generate";

  String description = 'Generate gists from the current directory.';

  String get invocation => "gist generate [directory]";

  bool get verbose => argResults['verbose'];
  bool get dry_run => argResults['dry-run'];
  bool get test_gist => argResults['test-gist'];

  String get rootPath => argResults.rest.isEmpty ? '.' : argResults.rest[0];

  ArgParser argParser = new ArgParser(allowTrailingOptions: true);

  Generate() {
    argParser.addFlag("verbose", abbr: 'v');
    argParser.addFlag("dry-run", abbr: 'n');
    argParser.addFlag("test-gist", abbr: 't');
  }

  run() async {
    setupGitHub();

    Directory root = new Directory(rootPath);
    List<Directory> allDirectories = root.listSync(recursive: true)..retainWhere((entity) => entity is Directory);

    bool pubspecInRoot = new File('$rootPath/pubspec.yaml').existsSync();

    // Generate a gist from the root if a pubspec.yaml file is in the root
    if (pubspecInRoot) {
      if (_isDartpadAble(root)) {
        DartSample sample = new DartSample(root);

        if (dry_run) exit(0);

        await sample.generateGist(test: test_gist);
      }
    } else {
      // if there is no pubspec.yaml file in the root
      // check if the project contains dartpadable directories
      var dartpadAbleSamples = allDirectories..retainWhere(_isDartpadAble);

      if (dry_run) exit(0);

      for (Directory sampleDir in dartpadAbleSamples) {
        DartSample sample = new DartSample(sampleDir);
        await sample.generateGist(test: test_gist);
      }
    }

    exit(0);
  }

  void setupGitHub() {
    if (dry_run || test_gist) {
      gitHub = createGitHubClient(auth: new Authentication.anonymous());
    } else  {
      String token = askSync('Create a github token here:\n'
          'https://github.com/settings/tokens\n'
          'Github Token:');
      Authentication auth = new Authentication.withToken(token);
      gitHub = createGitHubClient(auth: auth);
    }
  }

  bool _isDartpadAble(Directory dir) {
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

    if (! new File('$dirName/pubspec.yaml').existsSync()) {
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
}
