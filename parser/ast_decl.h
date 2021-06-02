/* File: ast_decl.h
 * ----------------
 * In our parse tree, Decl nodes are used to represent and
 * manage declarations. There are 4 subclasses of the base class,
 * specialized for declarations of variables, functions, classes,
 * and interfaces.
 */

#ifndef _H_ast_decl
#define _H_ast_decl

#include "ast.h"
#include "list.h"

class Type;
class NamedType;
class Identifier;
class Stmt;

// 所有定义的父类
class Decl : public Node 
{
  protected:
    Identifier *id;
  
  public:
    Decl(Identifier *name);
};

// 变量声明
class VarDecl : public Decl 
{
  protected:
    Type *type;
    
  public:
    VarDecl(Identifier *name, Type *type); // 变量名字，变量类型
    const char *GetPrintNameForNode() { return "VarDecl"; }
    void PrintChildren(int indentLevel); // 打印子结点
};

// 类声明
class ClassDecl : public Decl 
{
  protected:
    List<Decl*> *members;
    NamedType *inherit;
    List<NamedType*> *implements;

  public:
    // 类名字，继承的接口，实现的接口，内部成员
    ClassDecl(Identifier *name, NamedType *inherit, 
              List<NamedType*> *implements, List<Decl*> *members);
    const char *GetPrintNameForNode() { return "ClassDecl"; }
    void PrintChildren(int indentLevel);
};

// 声明类型声明
class LifeDecl : public Decl
{
  protected:
    List<Decl*> *members;
    // 继承的声明类型
    NamedType *inherit;
    // 捕食的声明类型
    List<NamedType*> *hunts;
    List<NamedType*> *implements;
  public:
    // 池名字，继承的接口，实现的接口，内部成员
    LifeDecl(Identifier *name, NamedType *inherit, List<NamedType*> *hunts,
              List<NamedType*> *implements, List<Decl*> *members);
    const char *GetPrintNameForNode() { return "LifeDecl"; }
    void PrintChildren(int indentLevel);
};


// 接口声明
class InterfaceDecl : public Decl
{
  protected:
    List<Decl*> *members;
    
  public:
    // 接口名字，接口成员
    InterfaceDecl(Identifier *name, List<Decl*> *members);
    const char *GetPrintNameForNode() { return "InterfaceDecl"; }
    void PrintChildren(int indentLevel);
};

// 函数声明
class FnDecl : public Decl 
{
  protected:
    List<VarDecl*> *formals;
    Type *returnType;
    Stmt *body;
  
  // 函数名字，返回值类型，参数列表
  public:
    FnDecl(Identifier *name, Type *returnType, List<VarDecl*> *formals);
    void SetFunctionBody(Stmt *b);
    const char *GetPrintNameForNode() { return "FnDecl"; }
    void PrintChildren(int indentLevel);
};

#endif
