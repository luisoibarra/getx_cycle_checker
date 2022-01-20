# GetX Circular Dependency Detector 

Simple package for finding circular dependencies when using **GetX** package. 

## Description

Checks for all `Get.find<T>()` in the source code and tell the user if there are any circular dependency. 

## Usage

> $ dart ./bin/main.dart FOLDER_TO_SEARCH_CIRCULAR_DEPENDENCIES

The program will read all .dart files contained in any subdirectory of FOLDER_TO_SEARCH_CIRCULAR_DEPENDENCIES and will search for any circular dependency.

```dart

import 'package:getx_cycle_checker/main.dart';

List<String> cycle = findCircularDependencies(FOLDER_TO_SEARCH_CIRCULAR_DEPENDENCIES);

```