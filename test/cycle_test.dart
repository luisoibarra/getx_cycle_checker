

import 'dart:io';

import 'package:test/test.dart';

import '../bin/main.dart';

void main() {
  
  FileSystemEntity entity = Directory.current;
  final testPath = entity.absolute.path + '\\test\\test3';
  final expectedResult = <String>["A", "C", "B","A"];
  test("Testing cycles", () {
    final cycle = findCircularDependencies(testPath);
    expect(cycle, expectedResult);
  });
}