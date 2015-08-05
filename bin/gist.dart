import 'package:args/command_runner.dart';

import 'dart:io';
import 'package:github/server.dart';
import 'package:prompt/prompt.dart';
import 'package:gist/dart_sample.dart';
import 'package:gist/github.dart';
import 'package:gist/analyzer.dart';

void main(List<String> arguments) {
  new CommandRunner('gist', 'Gist manager.')
    ..addCommand(new Generate())
    ..run(arguments);
}

class Generate extends Command {
  String name = "generate";

  String description = 'Generate gists from the current directory.';

  Generate() {
    String token = askSync('Github Token:');
    Authentication auth = new Authentication.withToken(token);
    gitHub = createGitHubClient(auth: auth);
  }

  run() async {
    var dartpadAbleSamples = new Directory('').listSync()
      ..retainWhere((dir) => dir is Directory)
      ..retainWhere(_isDartpadAble);

    for (Directory sampleDir in dartpadAbleSamples) {
      DartSample sample = new DartSample(sampleDir);
      await sample.generateGist();
    }
    exit(0);
  }

  bool _isDartpadAble(Directory dir) {
    var children = dir.listSync(recursive: true);
    Directory web = children.firstWhere(
        (entity) => entity is Directory && entity.path.endsWith('web'),
        orElse: () => null);

    // not dartpadable if there is no web dir
    if (web == null) return false;
    List<File> files = web.listSync(recursive: true)
      ..retainWhere((e) => e is File);

    // not dartpadable if there are more than 3 files
    if (files.length > 3) return false;

    // files can only have the name index.html/main.dart/styles.css
    if (!files.every((file) {
      var path = file.path;
      return path.endsWith('index.html') ||
          path.endsWith('main.dart') ||
          path.endsWith('styles.css');
    })) {
      return false;
    }

    // no packages can be imported, and dart:io can also not be imported
    File dartFile = new File('${dir.path}/web/main.dart');
    if (dartFile.existsSync()) {
      var analyzer = new AnalyzerUtil();
      List<String> libraries = analyzer.findLibraries(dartFile.readAsStringSync());
      if (libraries.any((l) => l == 'dart:io')) {
        return false;
      }
      if (libraries.any((l) => ! l.startsWith('dart:'))) {
        return false;
      }
    }

    // otherwise dartpadable, yeah :)
    return true;
  }
}
