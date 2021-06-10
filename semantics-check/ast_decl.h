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
#include "ast_type.h"
#include "hashtable.h"


class Identifier;
class StmtBlock;

// 所有定义的父类
class Decl : public Node 
{
  protected:
    Identifier *id;
  
  public:
    Decl(Identifier *name);
    Identifier *GetID() { return id; }
    friend ostream& operator<<(ostream &out, Decl *decl) { if (decl) return out << decl->id; else return out; }
    virtual const char *GetTypeName() { return NULL; }
    virtual Type *GetType() { return NULL; }
};

// 变量声明
class VarDecl : public Decl 
{
  protected:
    Type *type;
    
  public:
    VarDecl(Identifier *name, Type *type); // 变量名字，变量类型
    Type *GetType() { return type; }
    const char *GetTypeName() { if (type) return type->GetTypeName(); else return NULL; }
    bool HasSameTypeSig(VarDecl *vd);
    void CheckStatements();
    void CheckDeclError();
};

// 类声明
class ClassDecl : public Decl 
{
  protected:
    List<Decl*> *members;
    NamedType *inherit;
    List<NamedType*> *implements;
    Hashtable<Decl*> *sym_table;
  public:
    // 类名字，继承的接口，实现的接口，内部成员
    ClassDecl(Identifier *name, NamedType *inherit, 
              List<NamedType*> *implements, List<Decl*> *members);
    NamedType *GetExtends() { return inherit; }
    List<NamedType*> *GetImplements() { return implements; }
    void CheckStatements();
    void CheckDeclError();
    bool IsCompatibleWith(Decl *decl);
    Hashtable<Decl*> *GetSymTable() { return sym_table; }
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
    Hashtable<Decl*> *sym_table;
  public:
    // 池名字，继承的接口，实现的接口，内部成员
    LifeDecl(Identifier *name, NamedType *inherit,
              List<NamedType*> *implements, List<Decl*> *members);
    NamedType *GetExtends() { return inherit; }
    List<NamedType*> *GetImplements() { return implements; }
    void CheckStatements();
    void CheckDeclError();
    bool IsCompatibleWith(Decl *decl);
    Hashtable<Decl*> *GetSymTable() { return sym_table; }
};


// 接口声明
class InterfaceDecl : public Decl
{
  protected:
    List<Decl*> *members;
    Hashtable<Decl*> *sym_table;
  public:
    // 接口名字，接口成员
    InterfaceDecl(Identifier *name, List<Decl*> *members);
    void CheckDeclError();
    List<Decl*> *GetMembers() { return members; }
    Hashtable<Decl*> *GetSymTable() { return sym_table; }
};

// 函数声明
class FnDecl : public Decl 
{
  protected:
    List<VarDecl*> *formals;
    Type *returnType;
    StmtBlock *body;
    Hashtable<Decl*> *sym_table;

  // 函数名字，返回值类型，参数列表
  public:
    FnDecl(Identifier *name, Type *returnType, List<VarDecl*> *formals);
    void SetFunctionBody(StmtBlock *b);
    void CheckStatements();
    void CheckDeclError();
    Type *GetType() { return returnType; }
    List<VarDecl*> *GetFormals() { return formals; }
    const char *GetTypeName() { if (returnType) return returnType->GetTypeName(); else return NULL; }
    bool HasSameTypeSig(FnDecl *fd);
    Hashtable<Decl*> *GetSymTable() { return sym_table; }
};

#endif
