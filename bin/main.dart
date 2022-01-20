import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('''First argument must be the path to search for cycles''');
  }
  else {
    findCircularDependencies(args[0]);
  }
}

/// Returns all paths for .dart files in all `root`'s subdirectories
List<String> _getDartFiles(String root) {
  Directory dir = Directory(root);
  return dir.listSync(recursive: true)
    .map((e) => e.absolute.path)
    .where((element) => element.endsWith('.dart'))
    .toList();
}

/// Extracts all Get depenencies in `dartFile` 
List<_Dependency> _extractDependencies(String dartFile) {
  final dependencies = <_Dependency>[];
  
  // Read dart file
  String content = File(dartFile).readAsStringSync();

  // Parsing dart file
  ParseStringResult result = parseString(content: content, throwIfDiagnostics: false);
  
  for (CompilationUnitMember unitMember in result.unit.declarations) {
    if (unitMember is ClassDeclaration) {
      // Extracting Get Dependencies
      final visitor = _ClassDependencyCollectorVisitor(unitMember.name.name);
      visitor.visitClassDeclaration(unitMember);
      dependencies.addAll(visitor.dependencies);
    }
  }

  return dependencies;
} 

class _Dependency {
  final String className;
  final String dependency;

  _Dependency(this.className, this.dependency);
}

class _ClassDependencyCollectorVisitor extends RecursiveAstVisitor<void> {
  /// Stores all dependencies after analysis
  final dependencies = <_Dependency>[];
  /// Class name that will be analyzed
  final String className;

  _ClassDependencyCollectorVisitor(this.className);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    final serviceType = node.typeArguments?.arguments.isNotEmpty == true ? node.typeArguments?.arguments[0] : null;

    // Find all method invocations like `Get.find<T>()` 
    if (node.methodName.name == "find" 
    && target is SimpleIdentifier 
    && target.name == "Get"
    && serviceType is NamedType) {
      dependencies.add(_Dependency(className, serviceType.name.name));
    }
    super.visitMethodInvocation(node);
  }
}

/// Builds the dependency graph from `dependencies` list
Map<String,Set<String>> _getGraphFromDependencies(List<_Dependency> dependencies) {
  final nodes = <String,Set<String>>{};
  final allNodes = <String>{};

  // Creates a graph mapping all the nodes with the dependencies
  for (var dep in dependencies) {
    
    allNodes.add(dep.className);
    allNodes.add(dep.dependency);

    if (nodes.containsKey(dep.className)) {
      nodes[dep.className]!.add(dep.dependency);
    } else {
      nodes[dep.className] = <String>{dep.dependency};
    }
  }

  // Creates the nodes that only appears in the find<> clause
  for (var node in allNodes) {
    if (!nodes.containsKey(node)){
      nodes[node] = <String>{};
    }
  }
  return nodes;
}

/// Retuns the first cycle found in `graph`. If no cycle then returns an empty list
List<String> _findCycle(Map<String,Set<String>> graph) {
  final allVisited = <String>{};
  var pending = graph.keys.toSet();
  while (pending.isNotEmpty) {
    final visiting = <String>{};
    final cycle = _dfs(pending.first, graph, visiting, allVisited);
    if (cycle.isNotEmpty) { // Cycle
      return cycle;
    }
    pending = pending.difference(allVisited);
  }
  return [];
}

/// Performs a dfs search through the `graph` starting at node `current` returning the first cycle if any
List<String> _dfs(String current, Map<String,Set<String>> graph, Set<String> visiting, Set<String> visited) {
  if (visiting.contains(current)) {
    return [current]; // Watching a node in current search. Cycle
  }
  if (visited.contains(current)) {
    return []; // Watching a node of previous search. No Cycle
  }
  visiting.add(current);
  for (var child in graph[current]!) {
    var cycle = _dfs(child, graph, visiting, visited);
    if (cycle.isNotEmpty) { // Building the cycle
      if (cycle.first != cycle.last || cycle.length <= 1) {
        cycle.add(current);
      }
      return cycle;
    }
  }
  visiting.remove(current);
  visited.add(current);
  return [];
}

List<String> findCircularDependencies(String path) {
  final files = _getDartFiles(path);
  
  final allDependencies = <_Dependency>[];
  for (var file in files) {
    print("Extracting dependencies in $file ...");
    allDependencies.addAll(_extractDependencies(file));
  }
  
  print("Creating dependency graph ...");
  final graph = _getGraphFromDependencies(allDependencies);
  
  print("Finding circular dependency ...");
  final cycle = _findCycle(graph);
  final copyCycle = List<String>.from(cycle);
  if (cycle.isEmpty){
    print("No circular dependency found");
  }
  else {
    print("Circular dependency found");
    final initial = cycle.removeAt(0);
    for (var node in cycle.reversed) {
      stdout.write("$node -> ");
    }
    print(initial);
  }
  return copyCycle;
}