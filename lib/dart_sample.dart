library gist.dart_sample;

import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:github/server.dart';
import 'package:gist/github.dart';
import 'package:path/path.dart' as path;

class DartSample {
  final Directory _dir;

  final List<File> _allFiles;

  String get _dirName {
    if (_dir.path == '.') {
      return path.basename(Uri.base.path);
    }
    return path.relative(_dir.path);
  }

  String description;

  DartSample(Directory dir)
      : this._dir = dir,
        _allFiles = dir.listSync(recursive: true)
          ..retainWhere((file) => file is File);

  generateGist() async {
    String pubspec = new File('${_dir.path}/pubspec.yaml').readAsStringSync();
    Map yaml = loadYaml(pubspec);
    String gistUrl = yaml['gist'];
//    String description = yaml['description'];
//    if (description != null) {
//      this.description = description;
//    } else {
      this.description = _dirName;
//    }
    if (gistUrl == null) {
      await _createGist();
    } else {
      await _updateGist(_getIdFromHomepage(gistUrl));
    }
  }

  String _getIdFromHomepage(String gistUrl) =>
      gistUrl.substring(gistUrl.lastIndexOf('/') + 1);

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
    String gistUrl = 'https://gist.github.com/${gist.owner.login}/${gist.id}';
    String dartpadUrl = 'https://dartpad.dartlang.org/${gist.id}';
    String newString = '$oldString\n' 'gist: $gistUrl\n' 'dartpad: $dartpadUrl\n';
    pubspecFile.writeAsStringSync(newString);
    print('Gist url and dartpad url inserted in pubspec.yaml.');
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
