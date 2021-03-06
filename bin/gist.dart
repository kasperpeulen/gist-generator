import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:args/src/arg_parser.dart';
import 'package:gist/dartpadable.dart';
import 'package:gist/dart_sample.dart';
import 'package:gist/github.dart';
import 'package:github/server.dart';
import 'package:prompt/prompt.dart';

main(List<String> arguments) async {
  try {
    var runner = new CommandRunner('gist', 'Gist manager.')..addCommand(new Generate());
    await runner.run(arguments);
  } catch (e) {
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
    argParser.addFlag("verbose",
        abbr: 'v', negatable: false, help: 'Show extra information about why a directory is skipped.');
    argParser.addFlag("dry-run",
        abbr: 'n', negatable: false, help: 'Show which directories would be converted to gists.');
    argParser.addFlag("test-gist",
        abbr: 't', negatable: false, help: 'Create anonymous test gist, instead of creating public gists.');
  }

  run() async {
    setupGitHub();

    Directory root = new Directory(rootPath);
    List<Directory> allDirectories = root.listSync(recursive: true)..retainWhere((entity) => entity is Directory);

    bool pubspecInRoot = new File('$rootPath/pubspec.yaml').existsSync();

    // Generate a gist from the root if a pubspec.yaml file is in the root
    if (pubspecInRoot) {
      if (isDartpadAble(root, verbose: verbose, dry_run: dry_run)) {
        DartSample sample = new DartSample(root);

        if (dry_run) exit(0);

        await sample.generateGist(test: test_gist);
      }
    } else {
      // if there is no pubspec.yaml file in the root
      // check if the project contains dartpadable directories
      var dartpadAbleSamples = allDirectories
        ..retainWhere((e) => isDartpadAble(e, verbose: verbose, dry_run: dry_run));

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
    } else {
      String token = askSync('Create a github token here:\n'
          'https://github.com/settings/tokens\n'
          'Github Token:');
      Authentication auth = new Authentication.withToken(token);
      gitHub = createGitHubClient(auth: auth);
    }
  }
}
