import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:getx_cycle_checker/src/dependency.dart';
import 'package:getx_cycle_checker/src/visitor.dart';

/// Returns all paths for .dart files in all `root`'s subdirectories
List<String> getDartFiles(String root) {
  Directory dir = Directory(root);
  return dir.listSync(recursive: true)
    .map((e) => e.absolute.path)
    .where((element) => element.endsWith('.dart'))
    .toList();
}

/// Extracts all Get depenencies in `dartFile` 
List<Dependency> extractDependencies(String dartFile) {
  final dependencies = <Dependency>[];
  
  // Read dart file
  String content = File(dartFile).readAsStringSync();

  // Parsing dart file
  ParseStringResult result = parseString(content: content, throwIfDiagnostics: false);
  
  for (CompilationUnitMember unitMember in result.unit.declarations) {
    if (unitMember is ClassDeclaration) {
      // Extracting Get Dependencies
      final visitor = ClassDependencyCollectorVisitor(unitMember.name.name);
      visitor.visitClassDeclaration(unitMember);
      dependencies.addAll(visitor.dependencies);
    }
  }

  return dependencies;
} 


/// Builds the dependency graph from `dependencies` list
Map<String,Set<String>> getGraphFromDependencies(List<Dependency> dependencies) {
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
List<String> findCycle(Map<String,Set<String>> graph) {
  final allVisited = <String>{};
  var pending = graph.keys.toSet();
  while (pending.isNotEmpty) {
    final visiting = <String>{};
    final cycle = dfs(pending.first, graph, visiting, allVisited);
    if (cycle.isNotEmpty) { // Cycle
      return cycle;
    }
    pending = pending.difference(allVisited);
  }
  return [];
}

/// Performs a dfs search through the `graph` starting at node `current` returning the first cycle if any
List<String> dfs(String current, Map<String,Set<String>> graph, Set<String> visiting, Set<String> visited) {
  if (visiting.contains(current)) {
    return [current]; // Watching a node in current search. Cycle
  }
  if (visited.contains(current)) {
    return []; // Watching a node of previous search. No Cycle
  }
  visiting.add(current);
  for (var child in graph[current]!) {
    var cycle = dfs(child, graph, visiting, visited);
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
