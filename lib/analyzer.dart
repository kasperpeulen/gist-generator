library gist.analyzer;

import 'package:analyzer/analyzer.dart';

class AnalyzerUtil {
  AnalyzerUtil();

  List<String> findLibraries(String dartFile) {
    // Parse the dart string
    CompilationUnit compilationUnit = parseCompilationUnit(dartFile);

    // directive ::= [ExportDirective] | [ImportDirective] | [LibraryDirective] |
    // [PartDirective] | [PartOfDirective]
    List<Directive> directives = compilationUnit.directives;

    // only retain the imports
    directives.retainWhere((directive) => directive is ImportDirective);

    // Convert the ImportDirective object to a good looking string.
    List<String> libraries = directives.map(_beautifyImportDirective).toList();

    return libraries;
  }

  String _beautifyImportDirective(ImportDirective import) {
    String uri = import.uri.stringValue;
    if (uri.startsWith('dart')) return uri;

    if (uri.startsWith('package:')) return uri
        .replaceAll('package:', '')
        .replaceFirst('/', ':')
        .replaceAll('/', '.')
        .replaceAll('.dart', '');

    if (uri.startsWith('packages/')) return uri
        .replaceAll('packages/', '')
        .replaceFirst('/', ':')
        .replaceAll('/', '.')
        .replaceAll('.dart', '');

    throw 'Oh noes! I could not extract the library from $uri... My bad!';
  }
}
