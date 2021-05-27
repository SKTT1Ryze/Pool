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
 *
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
    ClassDecl*          classDecl;
    List< NamedType* >* interfaceList;
}


/* Tokens
 * ------
 * Here we tell yacc about all the token types that we are using.
 * Yacc will assign unique numbers to these and export the #define
 * in the generated y.tab.h header file.
 */
%token   T_Void T_Bool T_Int T_Double T_String T_Class 
%token   T_LessEqual T_GreaterEqual T_Equal T_NotEqual T_Dims
%token   T_And T_Or T_Null T_Extends T_This T_Interface T_Implements
%token   T_While T_For T_If T_Else T_Return T_Break
%token   T_New T_NewArray T_Print T_ReadInteger T_ReadLine

%token   <identifier> T_Identifier
%token   <stringConstant> T_StringConstant 
%token   <integerConstant> T_IntConstant
%token   <doubleConstant> T_DoubleConstant
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
%type <classDecl>     ClassDecl
%type <declList>      FieldList
%type <interfaceList> InterfaceList
%type <decl>          Field
%type <interfaceList> AInterface

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
   
 */

Program   :    DeclList            { 
                                      @1; 
                                      /* pp2: The @1 is needed to convince 
                                       * yacc to set up yylloc. You can remove 
                                       * it once you have other uses of @n*/
                                      Program *program = new Program($1);
                                      // if no errors, advance to next phase
                                      if(ReportError::NumErrors() == 0) 
                                        program->Print(0);
                                    }
          ;

//1 o mas
DeclList  :    DeclList Decl        { ($$=$1)->Append($2); }
          |    Decl                 { ($$ = new List<Decl*>)->Append($1); }
          ;

Decl      :    VariableDecl          { $$ = $1; }
          |    InterfaceDecl         { $$ = $1; }
          |    ClassDecl             { $$ = $1; }
          |    FunctionDecl          { $$ = $1; }
          ;

VariableDecl  :  Variable ';' { $$ = $1; }
              ;

Variable  :    Type T_Identifier  { 
                                    Identifier *varName = new Identifier(@2, $2);
                                    $$ = new VarDecl( varName, $1 );
                                  }
          ;

Type      :    T_Int          { $$ = Type::intType; }
          |    T_Double       { $$ = Type::doubleType; }
          |    T_Bool         { $$ = Type::boolType; }
          |    T_String       { $$ = Type::stringType; }
          |    T_Void         { $$ = Type::voidType; }
          |    T_Identifier   {
                                Identifier *udfType = new Identifier(@1, $1);
                                $$ = new NamedType(udfType);
                              }
          |    Type T_Dims    { $$ = new ArrayType(@1, $1); }
          ;

InterfaceDecl : T_Interface T_Identifier '{' PrototypeList '}' {
                                              Identifier* interfaceName = new Identifier(@2, $2);
                                              $$ = new InterfaceDecl( interfaceName, $4 );
                                            }
              ;

//0 o mas
PrototypeList : Prototype PrototypeList     { ($$ = $2)->InsertAt($1, 0); }
              |                             { $$ = new List< Decl* >(); }
              ;

Prototype : Type T_Identifier '(' ParamsList ')' ';' {
                                              Identifier *funcName = new Identifier(@2, $2);
                                              $$ = new FnDecl(funcName, $1, $4);
                                            }
          ;

ParamsList : Param AParam     { ($$ = $2)->InsertAt($1, 0); }
           |                  { $$ = new List< VarDecl* >(); }
           ;

AParam : ',' Param AParam     { ($$ = $3)->InsertAt($2, 0); }
       |                      { $$ = new List< VarDecl* >(); } 
       ;

Param : Variable              { $$ = $1; }
      ;

FunctionDecl  : Type T_Identifier '(' ParamsList ')' StmtBlock {
                                              Identifier* functionName = new Identifier(@2, $2);
                                              $$ = new FnDecl(functionName, $1, $4);
                                              $$->SetFunctionBody($6);
                                            }
              ;

ClassDecl   : T_Class T_Identifier '{' FieldList '}'
              {
                $$ = new ClassDecl(new Identifier(@2, $2), 
                                    NULL, 
                                    new List< NamedType* >(), 
                                    $4);
              }
            | T_Class T_Identifier T_Extends T_Identifier '{' FieldList '}'
              {
                $$ = new ClassDecl(new Identifier(@2, $2), 
                                    new NamedType(new Identifier(@4, $4)), 
                                    new List< NamedType* >(), 
                                    $6);
              }
            | T_Class T_Identifier T_Implements InterfaceList '{' FieldList '}'
              {
                $$ = new ClassDecl(new Identifier(@2, $2), 
                                    NULL, 
                                    $4, 
                                    $6);
              }
            | T_Class T_Identifier T_Extends T_Identifier T_Implements InterfaceList '{' FieldList '}'
              {
                $$ = new ClassDecl(new Identifier(@2, $2), 
                                    new NamedType(new Identifier(@4, $4)), 
                                    $6, 
                                    $8);
              }
            ;

InterfaceList   : T_Identifier AInterface     { ($$ = $2)->InsertAt(new NamedType(new Identifier(@1, $1)), 0); }
                ;

AInterface  : ',' T_Identifier AInterface     { ($$ = $3)->InsertAt(new NamedType(new Identifier(@2, $2)), 0); }
            |                                 { $$ = new List< NamedType* >(); }
            ;

FieldList   : Field FieldList     { ($$ = $2)->InsertAt($1, 0); }
            |                     { $$ = new List< Decl* >(); }
            ;

Field : VariableDecl              { $$ = $1; }
      | FunctionDecl              { $$ = $1; }
      ;

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

PrintStmt   : T_Print '(' PrintList ')' ';' { $$ = new PrintStmt($3); }
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
      | T_NewArray '(' Expr ',' Type ')' { $$ = new NewArrayExpr(@1, $3, $5);  }
      ;

LValue  : T_Identifier           { $$ = new FieldAccess(NULL, new Identifier(@1, $1)); }
        | Expr '.' T_Identifier  { $$ = new FieldAccess($1, new Identifier(@3, $3)); }
        | Expr '[' Expr ']'      { $$ = new ArrayAccess(@1, $1, $3); }
        ;

Constant  : T_IntConstant         { $$ = new IntConstant(@1, $1); }
          | T_DoubleConstant      { $$ = new DoubleConstant(@1, $1); }
          | T_BoolConstant        { $$ = new BoolConstant(@1, $1); }
          | T_StringConstant      { $$ = new StringConstant(@1, $1); }
          | T_Null                { $$ = new NullConstant(@1); }
          ;

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
   yydebug = false  ;
}
