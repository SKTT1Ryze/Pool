/* File: parser.y
 * --------------
 * Yacc input file to generate the parser for the compiler.
 *
 * pp2: your job is to write a parser that will construct the parse tree
 *      and if no parse errors were found, print it.  The parser should 
 *      accept the language as described in specification, and as augmented 
 *      in the pp2 handout.
 */

%{

/* Just like lex, the text within this first region delimited by %{ and %}
 * is assumed to be C/C++ code and will be copied verbatim to the y.tab.c
 * file ahead of the definitions of the yyparse() function. Add other header
 * file inclusions or C++ variable declarations/prototypes that are needed
 * by your code here.
 */
#include "scanner.h" // for yylex
#include "parser.h"
#include "errors.h"

void yyerror(char *msg); // standard error-handling routine

%}

/* The section before the first %% is the Definitions section of the yacc
 * input file. Here is where you declare tokens and types, add precedence
 * and associativity options, and so on.
 */
 
/* yylval 
 * ------
 * Here we define the type of the yylval global variable that is used by
 * the scanner to store attibute information about the token just scanned
 * and thus communicate that information to the parser. 
 * 定义全局变量 yylval，用于 scanner 保存 token 的属性并且让其通过这个和 parser 交互
 * pp2: You will need to add new fields to this union as you add different 
 *      attributes to your non-terminal symbols.
 */
%union {
    int            integerConstant;
    bool           boolConstant;
    char*          stringConstant;
    double         doubleConstant;
    char           identifier[MaxIdentLen+1]; // +1 for terminating null
    Decl*          decl;
    FnDecl*        fnDecl;
    List< Decl* >*      declList;
    Type*               varType;
    VarDecl*            varDecl;
    InterfaceDecl*      interfaceDecl;
    List< Decl* >*      prototypeList;
    List< VarDecl* >*   varDeclList;
    StmtBlock*          stmtBlock;
    Stmt*               stmt;
    List< Stmt* >*      stmtList;
    Expr*               expr;
    List< Expr* >*      exprList;
    Call*               call;
    WhileStmt*          whileStmt;
    ForStmt*            forStmt;
    ReturnStmt*         returnStmt;
    IfStmt*             ifStmt;
    PrintStmt*          printStmt;
    LifeDecl*           lifeDecl;
    List< NamedType* >* interfaceList;
}


/* Tokens
 * ------
 * Here we tell yacc about all the token types that we are using.
 * Yacc will assign unique numbers to these and export the #define
 * in the generated y.tab.h header file.
 * 终结符
 * 这些值会被生成到 y.tab.h 头文件里面去
 */
%token   T_Void T_Bool T_String
%token   T_LessEqual T_GreaterEqual T_Equal T_NotEqual T_Dims
%token   T_And T_Or T_Null T_Extends T_Inherit T_This T_Interface T_Implements
%token   T_While T_For T_If T_Else T_Return T_Break
%token   T_New T_NewArray T_Println T_ReadInteger T_ReadLine
%token   T_Pool T_Life T_Spawn T_Let T_Usize T_F32 T_Fn T_FuncReturn T_In T_Continue T_Const T_Loop T_Colon

/*标识符*/
%token   <identifier> T_Identifier
/*字符串常量*/
%token   <stringConstant> T_StringConstant 
/*整形常量*/
%token   <integerConstant> T_IntConstant
/*浮点数常量*/
%token   <doubleConstant> T_DoubleConstant
/*布尔类型常量*/
%token   <boolConstant> T_BoolConstant


/* Non-terminal types
 * ------------------
 * In order for yacc to assign/access the correct field of $$, $1, we
 * must to declare which field is appropriate for the non-terminal.
 * As an example, this first type declaration establishes that the DeclList
 * non-terminal uses the field named "declList" in the yylval union. This
 * means that when we are setting $$ for a reduction for DeclList ore reading
 * $n which corresponds to a DeclList nonterminal we are accessing the field
 * of the union named "declList" which is of type List<Decl*>.
 * pp2: You'll need to add many of these of your own.
 * 非终结符
 */
%type <declList>      DeclList 
%type <decl>          Decl
%type <varType>       Type
%type <varDecl>       VariableDecl
%type <varDecl>       Variable
%type <interfaceDecl> InterfaceDecl
%type <decl>          Prototype
%type <prototypeList> PrototypeList
%type <varDecl>       Param
%type <varDeclList>   ParamsList
%type <varDeclList>   AParam
%type <fnDecl>        FunctionDecl
%type <stmtBlock>     StmtBlock
%type <varDeclList>   VariableDeclList
%type <stmtList>      StmtList
%type <stmt>          Stmt
%type <expr>          Expr
%type <expr>          Constant
%type <expr>          LValue
%type <call>          Call
%type <exprList>      AExpr
%type <exprList>      Actuals
%type <ifStmt>        IfStmt
%type <whileStmt>     WhileStmt
%type <forStmt>       ForStmt
%type <returnStmt>    ReturnStmt
%type <printStmt>     PrintStmt
%type <exprList>      PrintList
%type <lifeDecl>      LifeDecl
%type <declList>      FieldList
%type <interfaceList> InterfaceList
%type <decl>          Field
%type <interfaceList> AInterface

/*运算符*/
/*%left 左结合，%right 右结合，%nonassoc 无结合*/
%nonassoc '='
%left T_Or
%left T_And
%left T_Equal T_NotEqual
%nonassoc '<' T_LessEqual '>' T_GreaterEqual
%left '+' '-'
%left '*' '/' '%'
%right '!' UMINUS
%left '[' '.' /* eso creo, no estoy seguro */


%%
/* Rules
 * -----
 * All productions and actions should be placed between the start and stop
 * %% markers which delimit the Rules section.
 * 规约规则
 */
/*总程序，由一系列定义的列表组成*/
Pool   :    DeclList            { 
                                      @1; 
                                      /* pp2: The @1 is needed to convince 
                                       * yacc to set up yylloc. You can remove 
                                       * it once you have other uses of @n*/
                                      Pool *pool = new Pool($1);
                                      // if no errors, advance to next phase
                                      if(ReportError::NumErrors() == 0) 
                                        pool->Print(0);
                                    }
          ;

//1 o mas
/*声明列表产生式*/
DeclList  :    DeclList Decl        { ($$=$1)->Append($2); /*先对 DeclList 进行规约，然后将 Decl 添加到规约后的结果中*/}
          |    Decl                 { ($$ = new List<Decl*>)->Append($1); /*新建一个列表，存放声明*/}
          ;

Decl      :    VariableDecl          { /*变量声明*/ $$ = $1; }
          |    InterfaceDecl         { /*接口声明*/ $$ = $1; }
          |    LifeDecl             { /*池声明*/ $$ = $1; }
          |    FunctionDecl          { /*函数声明*/ $$ = $1; }
          ;

/*变量声明产生式*/
VariableDecl  :  T_Let Variable ';' { $$ = $2; }
              ;

/*类型 标识符*/
Variable  :    T_Identifier T_Colon Type  { 
                                    Identifier *varName = new Identifier(@2, $1); // @n 表示产生式右部第 n 个元素的位置
                                    $$ = new VarDecl( varName, $3 );
                                  }
          ;

/*类型的产生式*/
Type      :    T_Usize        { $$ = Type::usizeType; /*Type 类型在 ast_type.h 里面定义*/}
          |    T_F32          { $$ = Type::f32Type; }
          |    T_Bool         { $$ = Type::boolType; }
          |    T_String       { $$ = Type::stringType; }
          |    T_Void         { $$ = Type::voidType; }
          |    T_Identifier   {
                                // 自定义的类型
                                Identifier *udfType = new Identifier(@1, $1); // Identifier 类型在 ast.h 里面定义
                                $$ = new NamedType(udfType); /*NamedType 在 ast_type.h 里面定义*/
                              }
          |    Type T_Dims    { /*类型的列表*/ $$ = new ArrayType(@1, $1); }
          ;

/*接口声明的产生式*/
InterfaceDecl : T_Interface T_Identifier '{' PrototypeList '}' {
                                              Identifier* interfaceName = new Identifier(@2, $2);
                                              $$ = new InterfaceDecl( interfaceName, $4 );
                                            }
              ;

// 原型声明列表产生式
PrototypeList : Prototype PrototypeList     { ($$ = $2)->InsertAt($1, 0); /*添加的原型放在列表的头部*/}
              |                             { $$ = new List< Decl* >(); }
              ;

// 原型产生式
Prototype : Type T_Identifier '(' ParamsList ')' ';' {
                                              Identifier *funcName = new Identifier(@2, $2);
                                              $$ = new FnDecl(funcName, $1, $4);
                                            }
          ;

// 参数列表声明产生式
ParamsList : Param AParam     { ($$ = $2)->InsertAt($1, 0); }
           |                  { $$ = new List< VarDecl* >(); /*创建一个空列表，元素是 VarDecl 的指针*/ }
           ;

// 第一个后面的参数的产生式
AParam : ',' Param AParam     { ($$ = $3)->InsertAt($2, 0); }
       |                      { $$ = new List< VarDecl* >(); } 
       ;

// 第一个参数的产生式
Param : Variable              { $$ = $1; }
      ;

// 函数声明产生式
FunctionDecl  : T_Fn T_Identifier '(' ParamsList ')' T_FuncReturn Type StmtBlock {
                                              Identifier* functionName = new Identifier(@2, $2);
                                              $$ = new FnDecl(functionName, $7, $4);
                                              $$->SetFunctionBody($8); /* 设置函数体 */
                                            }
              ;


// 生命类型声明产生式
LifeDecl   : T_Life T_Identifier '{' FieldList '}'
              {
                // 普通类声明
                $$ = new LifeDecl(new Identifier(@2, $2), 
                                    NULL, 
                                    new List< NamedType* >(), 
                                    $4);
              }
            | T_Life T_Identifier T_Extends T_Identifier '{' FieldList '}'
              {
                // 继承接口的类声明
                $$ = new LifeDecl(new Identifier(@2, $2), 
                                    new NamedType(new Identifier(@4, $4)), 
                                    new List< NamedType* >(), 
                                    $6);
              }
            | T_Life T_Identifier T_Implements InterfaceList '{' FieldList '}'
              {
                // 实现接口的类声明
                $$ = new LifeDecl(new Identifier(@2, $2), 
                                    NULL, 
                                    $4, 
                                    $6);
              }
            | T_Life T_Identifier T_Extends T_Identifier T_Implements InterfaceList '{' FieldList '}'
              {
                // 既继承接口又实现接口的类声明
                $$ = new LifeDecl(new Identifier(@2, $2), 
                                    new NamedType(new Identifier(@4, $4)), 
                                    $6, 
                                    $8);
              }
            ;

// 接口列表
InterfaceList   : T_Identifier AInterface     { ($$ = $2)->InsertAt(new NamedType(new Identifier(@1, $1)), 0); }
                ;

AInterface  : ',' T_Identifier AInterface     { ($$ = $3)->InsertAt(new NamedType(new Identifier(@2, $2)), 0); }
            |                                 { $$ = new List< NamedType* >(); }
            ;

// 类内部成员列表产生式
FieldList   : Field FieldList     { ($$ = $2)->InsertAt($1, 0); }
            |                     { $$ = new List< Decl* >(); }
            ;

// 类内部成员产生式
Field : VariableDecl              { $$ = $1; }
      | FunctionDecl              { $$ = $1; }
      ;

// 代码块产生式
StmtBlock : '{' VariableDeclList StmtList '}' {
                                              $$ = new StmtBlock($2, $3);
                                            }
          ;

VariableDeclList : VariableDeclList VariableDecl {
                                              ($$ = $1)->Append($2); 
                                            }
                 |                          { $$ = new List< VarDecl* >(); }
                 ;

StmtList  : Stmt StmtList       { ($$ = $2)->InsertAt($1, 0); }
          |                     { $$ = new List< Stmt* >(); }
         ;

Stmt  : ';'                     { /* ? */ }
      | Expr ';'                { $$ = $1; }
      | IfStmt                  { $$ = $1; }
      | WhileStmt               { $$ = $1; }
      | ForStmt                 { $$ = $1; }
      | T_Break ';'             { $$ = new BreakStmt(@1); }
      | ReturnStmt              { $$ = $1; }
      | PrintStmt               { $$ = $1; }
      | StmtBlock               { $$ = $1; }
      ;

/* Dangling-else in our LALR: jUST rELAX */
IfStmt  : T_If '(' Expr ')' Stmt              { $$ = new IfStmt($3, $5, NULL); }
        | T_If '(' Expr ')' Stmt T_Else Stmt  { $$ = new IfStmt($3, $5, $7); }

WhileStmt : T_While '(' Expr ')' Stmt { $$ = new WhileStmt($3, $5); }

ForStmt   : T_For '(' Expr ';' Expr ';' Expr ')' Stmt { $$ = new ForStmt($3, $5, $7, $9); }
          | T_For '(' Expr ';' Expr ';' ')' Stmt      { $$ = new ForStmt($3, $5, new EmptyExpr(), $8); }
          | T_For '(' ';' Expr ';' Expr ')' Stmt      { $$ = new ForStmt(new EmptyExpr(), $4, $6, $8); }
          | T_For '(' ';' Expr ';' ')' Stmt           { $$ = new ForStmt(new EmptyExpr(), $4, new EmptyExpr(), $7); }


ReturnStmt  : T_Return Expr ';' { $$ = new ReturnStmt(@1, $2); }
            | T_Return ';'      { $$ = new ReturnStmt(@1, new EmptyExpr()); } 
            ;

PrintStmt   : T_Println '(' PrintList ')' ';' { $$ = new PrintStmt($3); }
            ;

PrintList  : Expr AExpr           { ($$ = $2)->InsertAt($1, 0); }
           /* | Expr                 { ($$ = new List< Expr* >())->InsertAt($1, 0); } */
          ;

Expr  : LValue '=' Expr           { $$ = new AssignExpr($1, new Operator(@2, "="), $3); }
      | Constant                  { $$ = $1; }
      | LValue                    { $$ = $1; }
      | T_This                    { $$ = new This(@1); }
      | Call                      { $$ = $1; }
      | '(' Expr ')'              { $$ = $2; }
      | Expr '+' Expr             { $$ = new ArithmeticExpr($1, new Operator(@2, "+"), $3); }
      | Expr '-' Expr             { $$ = new ArithmeticExpr($1, new Operator(@2, "-"), $3); }
      | Expr '*' Expr             { $$ = new ArithmeticExpr($1, new Operator(@2, "*"), $3); }
      | Expr '/' Expr             { $$ = new ArithmeticExpr($1, new Operator(@2, "/"), $3); }
      | Expr '%' Expr             { $$ = new ArithmeticExpr($1, new Operator(@2, "%"), $3); }
      | '-' Expr  %prec UMINUS    { $$ = new ArithmeticExpr(new Operator(@1, "-"), $2); }
      | Expr '<' Expr             { $$ = new RelationalExpr($1, new Operator(@2, "<"), $3); }
      | Expr T_LessEqual Expr     { $$ = new RelationalExpr($1, new Operator(@2, "<="), $3); }
      | Expr '>' Expr             { $$ = new RelationalExpr($1, new Operator(@2, ">"), $3); }
      | Expr T_GreaterEqual Expr  { $$ = new RelationalExpr($1, new Operator(@2, ">="), $3); }
      | Expr T_Equal Expr         { $$ = new EqualityExpr($1, new Operator(@2, "=="), $3); }
      | Expr T_NotEqual Expr      { $$ = new EqualityExpr($1, new Operator(@2, "!="), $3); }
      | Expr T_And Expr           { $$ = new LogicalExpr($1, new Operator(@2, "&&"), $3); }
      | Expr T_Or Expr            { $$ = new LogicalExpr($1, new Operator(@2, "||"), $3); }
      | '!' Expr                  { $$ = new LogicalExpr(new Operator(@1, "!"), $2); }
      | T_ReadInteger '(' ')'     { $$ = new ReadIntegerExpr(@1); }
      | T_ReadLine '(' ')'        { $$ = new ReadLineExpr(@1); }
      | T_New '(' T_Identifier ')' { 
                                    NamedType* newt = new NamedType(new Identifier(@3, $3));
                                    $$ = new NewExpr(@1, newt);
                                  }
      | T_Spawn '(' T_Identifier ')' { 
                                    NamedType* newt = new NamedType(new Identifier(@3, $3));
                                    $$ = new SpawnExpr(@1, newt);
                                  }
      | T_NewArray '(' Expr ',' Type ')' { $$ = new NewArrayExpr(@1, $3, $5);  }
      ;

// 左值产生式
LValue  : T_Identifier           { $$ = new FieldAccess(NULL, new Identifier(@1, $1)); }
        | Expr '.' T_Identifier  { $$ = new FieldAccess($1, new Identifier(@3, $3)); }
        | Expr '[' Expr ']'      { $$ = new ArrayAccess(@1, $1, $3); }
        ;

// 常量产生式
Constant  : T_IntConstant         { $$ = new IntConstant(@1, $1); }
          | T_DoubleConstant      { $$ = new DoubleConstant(@1, $1); }
          | T_BoolConstant        { $$ = new BoolConstant(@1, $1); }
          | T_StringConstant      { $$ = new StringConstant(@1, $1); }
          | T_Null                { $$ = new NullConstant(@1); }
          ;

// 函数调用产生式
Call  : T_Identifier '(' Actuals ')' {
                                    $$ = new Call(@1, NULL, new Identifier(@1, $1), $3);
                                  }
      | Expr '.' T_Identifier '(' Actuals ')' {
                                    $$ = new Call(@1, $1, new Identifier(@3, $3), $5);
                                  }
      ;

Actuals : Expr AExpr              { ($$ = $2)->InsertAt($1, 0); }
        |                         { $$ = new List< Expr* >(); }
        ;

AExpr   : ',' Expr AExpr          { ($$ = $3)->InsertAt($2, 0); }
        |                         { $$ = new List< Expr* >(); }
        ;

%%

/* The closing %% above marks the end of the Rules section and the beginning
 * of the User Subroutines section. All text from here to the end of the
 * file is copied verbatim to the end of the generated y.tab.c file.
 * This section is where you put definitions of helper functions.
 */

/* Function: InitParser
 * --------------------
 * This function will be called before any calls to yyparse().  It is designed
 * to give you an opportunity to do anything that must be done to initialize
 * the parser (set global variables, configure starting state, etc.). One
 * thing it already does for you is assign the value of the global variable
 * yydebug that controls whether yacc prints debugging information about
 * parser actions (shift/reduce) and contents of state stack during parser.
 * If set to false, no information is printed. Setting it to true will give
 * you a running trail that might be helpful when debugging your parser.
 * Please be sure the variable is set to false when submitting your final
 * version.
 */
void InitParser()
{
   PrintDebug("parser", "Initializing parser");
   yydebug = false;
}
