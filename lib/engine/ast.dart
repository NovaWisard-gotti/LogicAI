/// Árbol de sintaxis del pseudocódigo educativo.
library;

abstract class Node {
  Node(this.line);

  final int line;
}

abstract class Expr extends Node {
  Expr(super.line);
}

abstract class Stmt extends Node {
  Stmt(super.line);
}

// ---------------------------------------------------------------- expresiones
class NumLit extends Expr {
  NumLit(super.line, this.value);

  final num value;
}

class TextLit extends Expr {
  TextLit(super.line, this.value);

  final String value;
}

class BoolLit extends Expr {
  BoolLit(super.line, this.value);

  final bool value;
}

class VarExpr extends Expr {
  VarExpr(super.line, this.name);

  final String name;
}

class IndexExpr extends Expr {
  IndexExpr(super.line, this.target, this.index);

  final Expr target;
  final Expr index;
}

class FieldExpr extends Expr {
  FieldExpr(super.line, this.target, this.field);

  final Expr target;
  final String field;
}

class UnaryExpr extends Expr {
  UnaryExpr(super.line, this.op, this.expr);

  final String op;
  final Expr expr;
}

class BinaryExpr extends Expr {
  BinaryExpr(super.line, this.op, this.left, this.right);

  final String op;
  final Expr left;
  final Expr right;
}

class CallExpr extends Expr {
  CallExpr(super.line, this.name, this.args);

  final String name;
  final List<Expr> args;
}

class ArrayLit extends Expr {
  ArrayLit(super.line, this.items);

  final List<Expr> items;
}

class ObjectLit extends Expr {
  ObjectLit(super.line, this.pairs);

  final List<MapEntry<String, Expr>> pairs;
}

// ------------------------------------------------------------ instrucciones
class AssignStmt extends Stmt {
  AssignStmt(super.line, this.target, this.value);

  final Expr target;
  final Expr value;
}

class ArrayDeclStmt extends Stmt {
  ArrayDeclStmt(super.line, this.name, this.size);

  final String name;
  final Expr size;
}

class PrintStmt extends Stmt {
  PrintStmt(super.line, this.args);

  final List<Expr> args;
}

class ReadStmt extends Stmt {
  ReadStmt(super.line, this.name);

  final String name;
}

class IfStmt extends Stmt {
  IfStmt(super.line, this.condition, this.thenBranch, this.elseBranch);

  final Expr condition;
  final List<Stmt> thenBranch;
  final List<Stmt> elseBranch;
}

class WhileStmt extends Stmt {
  WhileStmt(super.line, this.condition, this.body);

  final Expr condition;
  final List<Stmt> body;
}

class ForStmt extends Stmt {
  ForStmt(super.line, this.variable, this.from, this.to, this.step, this.body);

  final String variable;
  final Expr from;
  final Expr to;
  final Expr? step;
  final List<Stmt> body;
}

class FuncDeclStmt extends Stmt {
  FuncDeclStmt(super.line, this.name, this.params, this.body);

  final String name;
  final List<String> params;
  final List<Stmt> body;
}

class ReturnStmt extends Stmt {
  ReturnStmt(super.line, this.value);

  final Expr? value;
}

class ExprStmt extends Stmt {
  ExprStmt(super.line, this.expr);

  final Expr expr;
}
