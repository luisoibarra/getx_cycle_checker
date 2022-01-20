import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:getx_cycle_checker/src/dependency.dart';

class ClassDependencyCollectorVisitor extends RecursiveAstVisitor<void> {
  /// Stores all dependencies after analysis
  final dependencies = <Dependency>[];
  /// Class name that will be analyzed
  final String className;

  ClassDependencyCollectorVisitor(this.className);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    final serviceType = node.typeArguments?.arguments.isNotEmpty == true ? node.typeArguments?.arguments[0] : null;

    // Find all method invocations like `Get.find<T>()` 
    if (node.methodName.name == "find" 
    && target is SimpleIdentifier 
    && target.name == "Get"
    && serviceType is NamedType) {
      dependencies.add(Dependency(className, serviceType.name.name));
    }
    super.visitMethodInvocation(node);
  }
}
