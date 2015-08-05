library gist.dart_sample;

import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:github/server.dart';
import 'package:gist/dart_sample.dart';
import 'package:gist/github.dart';
import 'package:path/path.dart' as path;

class DartSample {
  final Directory _dir;

  final List<File> _allFiles;

  String get _dirName => path.basename(_dir.path);

  String description;

  DartSample(Directory dir)
      : this._dir = dir,
        _allFiles = dir.listSync(recursive: true)
          ..retainWhere((file) => file is File);

  generateGist() async {
    String pubspec = new File('${_dir.path}/pubspec.yaml').readAsStringSync();
    Map yaml = loadYaml(pubspec);
    String homepage = yaml['homepage'];
    String description = yaml['description'];
    if (description != null) {
      this.description = description;
    } else {
      description = _dirName;
    }
    if (homepage == null) {
      await _createGist();
    } else {
      await _updateGist(_getIdFromHomepage(homepage));
    }
  }

  String _getIdFromHomepage(String homepage) =>
      homepage.substring(homepage.lastIndexOf('/') + 1);

  _createGist() async {
    Gist gist = await gitHub.gists.createGist(_getFiles(), description: description, public: true);
    print('"$_dirName" gist created at ${gist.htmlUrl}');
    _writeGistUrlToPubspec(gist);

  }

  _updateGist(String id) async {
    Gist gist = await gitHub.gists.editGist(id, description: description, files: _getFiles());
    print('"$_dirName" gist updated at ${gist.htmlUrl}');
  }

  void _writeGistUrlToPubspec(Gist gist) {
    File pubspecFile =
    _allFiles.firstWhere((file) => file.path.endsWith('pubspec.yaml'));
    String oldString = pubspecFile.readAsStringSync();
    String homepage = 'http://gist.github.com/${gist.owner.login}/${gist.id}';
    String newString = '$oldString\n' 'homepage: $homepage';
    pubspecFile.writeAsStringSync(newString);
    print('Homepage inserted in pubspec.yaml');
  }

  Map<String, String> _getFiles() {
    Map files = {
      'index.html': _allFiles
          .firstWhere((file) => file.path.endsWith('.html'), orElse: () => null)
          ?.readAsStringSync(),
      'main.dart': _allFiles
          .firstWhere((file) => file.path.endsWith('.dart'), orElse: () => null)
          ?.readAsStringSync(),
      'styles.css': _allFiles
          .firstWhere((file) => file.path.endsWith('.css'), orElse: () => null)
          ?.readAsStringSync()
    };
    return files
      ..keys.where((key) => files[key] == null).toList().forEach(files.remove);
  }
}
