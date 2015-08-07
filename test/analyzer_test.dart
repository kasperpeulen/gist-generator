import 'dart:io';

import "package:test/test.dart";
import 'package:gist/analyzer.dart';

AnalyzerUtil analyzer = new AnalyzerUtil();

void main() {
  group(('find_libraries'), () {
    test('import dart:io', () {
      String dartString = new File('test/samples/import_io/web/main.dart').readAsStringSync();
      expect(analyzer.findLibraries(dartString)[0], 'dart:io');
    });
    test('import dart:html', () {
      String dartString = new File('test/samples/import_html/web/main.dart').readAsStringSync();
      expect(analyzer.findLibraries(dartString)[0], 'dart:html');
    });
    test('import args:args', () {
      String dartString = new File('test/samples/import_package/web/main.dart').readAsStringSync();
      expect(analyzer.findLibraries(dartString)[0], 'args:args');
    });
  });
}
