
import 'dart:io';

import 'package:getx_cycle_checker/src/dependency.dart';
import 'package:getx_cycle_checker/src/utils.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('''First argument must be the path to search for cycles''');
  }
  else {
    findCircularDependencies(args[0]);
  }
}

List<String> findCircularDependencies(String path) {
  final files = getDartFiles(path);
  
  final allDependencies = <Dependency>[];
  for (var file in files) {
    print("Extracting dependencies in $file ...");
    allDependencies.addAll(extractDependencies(file));
  }
  
  print("Creating dependency graph ...");
  final graph = getGraphFromDependencies(allDependencies);
  
  print("Finding circular dependency ...");
  final cycle = findCycle(graph);
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