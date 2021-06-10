/* File: ast_expr.h
 * ----------------
 * The Expr class and its subclasses are used to represent
 * expressions in the parse tree.  For each expression in the
 * language (add, call, New, etc.) there is a corresponding
 * node class for that construct. 
 */


#ifndef _H_ast_expr
#define _H_ast_expr

#include <string>
#include "ast.h"
#include "ast_stmt.h"
#include "ast_type.h"
#include "list.h"

class FnDecl;

// 表达式类型，继承 Stmt
class Expr : public Stmt 
{
  protected:
    Type *type;

  public:
    // 位置
    Expr(yyltype loc) : Stmt(loc) {}
    Expr() : Stmt() {}
    virtual Type *GetType() { return type; }
    virtual const char *GetTypeName() { if (type) return type->GetTypeName(); else return NULL;}
};

/* This node type is used for those places where an expression is optional.
 * We could use a NULL pointer, but then it adds a lot of checking for
 * NULL. By using a valid, but no-op, node, we save that trouble */
// 空表达式
class EmptyExpr : public Expr
{
};

// 整型常量
class IntConstant : public Expr 
{
  protected:
    int value;
  
  public:
    // 位置，值
    IntConstant(yyltype loc, int val);
};

// 浮点常量
class DoubleConstant : public Expr 
{
  protected:
    double value;
    
  public:
    DoubleConstant(yyltype loc, double val);
};

// 布尔常量
class BoolConstant : public Expr 
{
  protected:
    bool value;
    
  public:
    BoolConstant(yyltype loc, bool val);
};

// 字符串常量
class StringConstant : public Expr 
{ 
  protected:
    char *value;
    
  public:
    StringConstant(yyltype loc, const char *val);
};

// Null常量
class NullConstant: public Expr 
{
  public: 
    NullConstant(yyltype loc);
};

// 操作符
class Operator : public Node 
{
  protected:
    char tokenString[4];
    
  public:
    Operator(yyltype loc, const char *tok);
    friend ostream &operator<<(ostream &out, Operator *op) { if (op) return out << op->tokenString; else return out; }
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
};

// 算术表达式
class ArithmeticExpr : public CompoundExpr 
{
  public:
    ArithmeticExpr(Expr *lhs, Operator *op, Expr *rhs) : CompoundExpr(lhs,op,rhs) {}
    ArithmeticExpr(Operator *op, Expr *rhs) : CompoundExpr(op,rhs) {}
    void CheckStatements();
    Type *GetType() { return right->GetType(); }
    const char *GetTypeName() { return right->GetTypeName();}
};

// 关系表达式
class RelationalExpr : public CompoundExpr 
{
  public:
    RelationalExpr(Expr *lhs, Operator *op, Expr *rhs) : CompoundExpr(lhs,op,rhs) {}
    void CheckStatements();
    Type *GetType() { return Type::boolType; }
    const char *GetTypeName() { return "bool"; }
};

// 相等表达式
class EqualityExpr : public CompoundExpr 
{
  public:
    EqualityExpr(Expr *lhs, Operator *op, Expr *rhs) : CompoundExpr(lhs,op,rhs) {}
    void CheckStatements();
    Type *GetType() { return Type::boolType; }
    const char *GetTypeName() { return "bool"; }
};

// 逻辑表达式
class LogicalExpr : public CompoundExpr 
{
  public:
    LogicalExpr(Expr *lhs, Operator *op, Expr *rhs) : CompoundExpr(lhs,op,rhs) {}
    LogicalExpr(Operator *op, Expr *rhs) : CompoundExpr(op,rhs) {}
    void CheckStatements();
    Type *GetType() { return Type::boolType; }
    const char *GetTypeName() { return "bool"; }
};

// 赋值表达式
class AssignExpr : public CompoundExpr 
{
  public:
    AssignExpr(Expr *lhs, Operator *op, Expr *rhs) : CompoundExpr(lhs,op,rhs) {}
    void CheckStatements();
    Type *GetType() { return left->GetType(); }
    const char *GetTypeName() { return left->GetTypeName(); }
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
    void CheckStatements();
};

// 数组访问表达式
class ArrayAccess : public LValue 
{
  protected:
    Expr *base, *subscript;
    
  public:
    ArrayAccess(yyltype loc, Expr *base, Expr *subscript);
    void CheckStatements();
    Type *GetType();
    const char *GetTypeName();
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
    Type *type; // Expr::type is protected and thus not inherited here
  public:
    FieldAccess(Expr *base, Identifier *field); // ok to pass NULL base
    void CheckStatements(); // its type is decided here
    Identifier *GetField() { return field; }
    Type *GetType() { return type; }
    const char *GetTypeName() { if (type) return type->GetTypeName(); else return NULL; }
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
    void CheckArguments(FnDecl *fndecl); // check arguments against formal parameters
    void CheckStatements(); // its type is decided here
    Type *GetType() { return type; }
    const char *GetTypeName() { if (type) return type->GetTypeName(); else return NULL; }
};

class NewExpr : public Expr
{
  protected:
    NamedType *cType;
    
  public:
    NewExpr(yyltype loc, NamedType *clsType);
    void CheckStatements();
    Type *GetType() { return cType; }
    const char *GetTypeName() { if (cType) return cType->GetTypeName(); else return NULL;  }
};


class SpawnExpr : public Expr
{
  protected:
    NamedType *cType;
    
  public:
    SpawnExpr(yyltype loc, NamedType *clsType);
    void CheckStatements();
    Type *GetType() { return cType; }
    const char *GetTypeName() { if (cType) return cType->GetTypeName(); else return NULL;  }
};


class NewArrayExpr : public Expr
{
  protected:
    Expr *size;
    Type *elemType;
    
  public:
    NewArrayExpr(yyltype loc, Expr *sizeExpr, Type *elemType);
    void CheckStatements();
    const char *GetTypeName();
};

class ReadIntegerExpr : public Expr
{
  public:
    ReadIntegerExpr(yyltype loc);
};

class ReadLineExpr : public Expr
{
  public:
    ReadLineExpr(yyltype loc);
};

#endif
