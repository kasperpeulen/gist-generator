import 'dart:io';

import "package:test/test.dart";
import 'package:gist/dartpadable.dart';

void main() {
  group(('dartpadble'), () {
    test('import dart:io fails', () => expect(
        isDartpadAble(new Directory('test/samples/import_io')), false));
    test('import dart:html passes', () => expect(
        isDartpadAble(new Directory('test/samples/import_html')), true));
    test('import package fails', () => expect(
        isDartpadAble(new Directory('test/samples/import_package')), false));
  });
}
