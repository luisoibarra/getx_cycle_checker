

import 'dart:io';

import 'package:getx_cycle_checker/getx_cycle_checker.dart';
import 'package:test/test.dart';

void main() {
  
  FileSystemEntity entity = Directory.current;
  final testPath = entity.absolute.path + '\\test\\test3';
  final expectedResult = <String>["A", "C", "B","A"];
  test("Testing cycles", () {
    final cycle = findCircularDependencies(testPath);
    expect(cycle, expectedResult);
  });
}