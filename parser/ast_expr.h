/* File: ast_expr.h
 * ----------------
 * The Expr class and its subclasses are used to represent
 * expressions in the parse tree.  For each expression in the
 * language (add, call, New, etc.) there is a corresponding
 * node class for that construct. 
 */


#ifndef _H_ast_expr
#define _H_ast_expr

#include "ast.h"
#include "ast_stmt.h"
#include "list.h"

class NamedType; // for new
class Type; // for NewArray

// 表达式类型，继承 Stmt
class Expr : public Stmt 
{
  public:
    // 位置
    Expr(yyltype loc) : Stmt(loc) {}
    Expr() : Stmt() {}
};

/* This node type is used for those places where an expression is optional.
 * We could use a NULL pointer, but then it adds a lot of checking for
 * NULL. By using a valid, but no-op, node, we save that trouble */
// 空表达式
class EmptyExpr : public Expr
{
  public:
    const char *GetPrintNameForNode() { return "Empty"; }
};

// 整型常量
class IntConstant : public Expr 
{
  protected:
    int value;
  
  public:
    // 位置，值
    IntConstant(yyltype loc, int val);
    const char *GetPrintNameForNode() { return "IntConstant"; }
    void PrintChildren(int indentLevel);
};

// 浮点常量
class DoubleConstant : public Expr 
{
  protected:
    double value;
    
  public:
    DoubleConstant(yyltype loc, double val);
    const char *GetPrintNameForNode() { return "DoubleConstant"; }
    void PrintChildren(int indentLevel);
};

// 布尔常量
class BoolConstant : public Expr 
{
  protected:
    bool value;
    
  public:
    BoolConstant(yyltype loc, bool val);
    const char *GetPrintNameForNode() { return "BoolConstant"; }
    void PrintChildren(int indentLevel);
};

// 字符串常量
class StringConstant : public Expr 
{ 
  protected:
    char *value;
    
  public:
    StringConstant(yyltype loc, const char *val);
    const char *GetPrintNameForNode() { return "StringConstant"; }
    void PrintChildren(int indentLevel);
};

// Null常量
class NullConstant: public Expr 
{
  public: 
    NullConstant(yyltype loc) : Expr(loc) {}
    const char *GetPrintNameForNode() { return "NullConstant"; }
};

// 操作符
class Operator : public Node 
{
  protected:
    char tokenString[4];
    
  public:
    Operator(yyltype loc, const char *tok);
    const char *GetPrintNameForNode() { return "Operator"; }
    void PrintChildren(int indentLevel);
 };
 
// 复合表达式，算术表达式，逻辑表达式等的基类
class CompoundExpr : public Expr
{
  protected:
    Operator *op;
    Expr *left, *right; // left will be NULL if unary
    
  public:
    CompoundExpr(Expr *lhs, Operator *op, Expr *rhs); // for binary
    CompoundExpr(Operator *op, Expr *rhs);             // for unary
    void PrintChildren(int indentLevel);
};

// 算术表达式
class ArithmeticExpr : public CompoundExpr 
{
  public:
    ArithmeticExpr(Expr *lhs, Operator *op, Expr *rhs) : CompoundExpr(lhs,op,rhs) {}
    ArithmeticExpr(Operator *op, Expr *rhs) : CompoundExpr(op,rhs) {}
    const char *GetPrintNameForNode() { return "ArithmeticExpr"; }
};

// 关系表达式
class RelationalExpr : public CompoundExpr 
{
  public:
    RelationalExpr(Expr *lhs, Operator *op, Expr *rhs) : CompoundExpr(lhs,op,rhs) {}
    const char *GetPrintNameForNode() { return "RelationalExpr"; }
};

// 相等表达式
class EqualityExpr : public CompoundExpr 
{
  public:
    EqualityExpr(Expr *lhs, Operator *op, Expr *rhs) : CompoundExpr(lhs,op,rhs) {}
    const char *GetPrintNameForNode() { return "EqualityExpr"; }
};

// 逻辑表达式
class LogicalExpr : public CompoundExpr 
{
  public:
    LogicalExpr(Expr *lhs, Operator *op, Expr *rhs) : CompoundExpr(lhs,op,rhs) {}
    LogicalExpr(Operator *op, Expr *rhs) : CompoundExpr(op,rhs) {}
    const char *GetPrintNameForNode() { return "LogicalExpr"; }
};

// 赋值表达式
class AssignExpr : public CompoundExpr 
{
  public:
    AssignExpr(Expr *lhs, Operator *op, Expr *rhs) : CompoundExpr(lhs,op,rhs) {}
    const char *GetPrintNameForNode() { return "AssignExpr"; }
};

// 左值表达式
class LValue : public Expr 
{
  public:
    LValue(yyltype loc) : Expr(loc) {}
};

// This 表达式
class This : public Expr 
{
  public:
    This(yyltype loc) : Expr(loc) {}
    const char *GetPrintNameForNode() { return "This"; }
};

// 数组访问表达式
class ArrayAccess : public LValue 
{
  protected:
    Expr *base, *subscript;
    
  public:
    ArrayAccess(yyltype loc, Expr *base, Expr *subscript);
    const char *GetPrintNameForNode() { return "ArrayAccess"; }
    void PrintChildren(int indentLevel);
};

/* Note that field access is used both for qualified names
 * base.field and just field without qualification. We don't
 * know for sure whether there is an implicit "this." in
 * front until later on, so we use one node type for either
 * and sort it out later. */
class FieldAccess : public LValue 
{
  protected:
    Expr *base;	// will be NULL if no explicit base
    Identifier *field;
    
  public:
    FieldAccess(Expr *base, Identifier *field); //ok to pass NULL base
    const char *GetPrintNameForNode() { return "FieldAccess"; }
    void PrintChildren(int indentLevel);
};

/* Like field access, call is used both for qualified base.field()
 * and unqualified field().  We won't figure out until later
 * whether we need implicit "this." so we use one node type for either
 * and sort it out later. */
class Call : public Expr 
{
  protected:
    Expr *base;	// will be NULL if no explicit base
    Identifier *field;
    List<Expr*> *actuals;
    
  public:
    Call(yyltype loc, Expr *base, Identifier *field, List<Expr*> *args);
    const char *GetPrintNameForNode() { return "Call"; }
    void PrintChildren(int indentLevel);
};

class NewExpr : public Expr
{
  protected:
    NamedType *cType;
    
  public:
    NewExpr(yyltype loc, NamedType *clsType);
    const char *GetPrintNameForNode() { return "NewExpr"; }
    void PrintChildren(int indentLevel);
};


class SpawnExpr : public Expr
{
  protected:
    NamedType *cType;
    
  public:
    SpawnExpr(yyltype loc, NamedType *clsType);
    const char *GetPrintNameForNode() { return "SpawnExpr"; }
    void PrintChildren(int indentLevel);
};


class NewArrayExpr : public Expr
{
  protected:
    Expr *size;
    Type *elemType;
    
  public:
    NewArrayExpr(yyltype loc, Expr *sizeExpr, Type *elemType);
    const char *GetPrintNameForNode() { return "NewArrayExpr"; }
    void PrintChildren(int indentLevel);
};

class ReadIntegerExpr : public Expr
{
  public:
    ReadIntegerExpr(yyltype loc) : Expr(loc) {}
    const char *GetPrintNameForNode() { return "ReadIntegerExpr"; }
};

class ReadLineExpr : public Expr
{
  public:
    ReadLineExpr(yyltype loc) : Expr (loc) {}
    const char *GetPrintNameForNode() { return "ReadLineExpr"; }
};

#endif
