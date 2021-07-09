## 概述
现代计算机科学技术的发展离不开一个基石：编程语言，编程语言作为计算机体系结构三大部分的其中之一，为计算机从业者提供高效的程序开发方法，并与指令集和硬件相配合，使得人类可以在机器上运行“程序”，让机器完成一些人类无法完成的工作。  
编译原理作为研究如何实现编程语言的学科，逐渐成为一个相对独立而又价值非凡的领域，它研究一个编译程序的实现过程，和一种高级语言源文件到机器代码的转换过程，是计算机体系结构领域的重要方向。  
随着编译原理学科的发展和进步，衍生出了一些现代编程语言：Java，Rust，Go 等等，这些现代编程语言相比传统的 C 语言，提供了更为复杂的编程模型，以适应更加复杂的生产环境。  
本实验旨在动手从头实现一个高级语言编译器，实现从源文件到目标代码的转换，而该高级语言是笔者自己定义的“池语言”。  

## 实验一 池语言定义
### 基本概念
在 decaf 语言的基础上定义一门新的编程语言-池语言。  
池语言的设计思路来源于大自然中的“池塘”，下面简述一下池语言的基本概念：   
+ 池语言编写的程序相当于一个“池塘”，里面孕育着许多“生命”
+ 生命对应着传统面向对象编程语言的对象
+ 生命有很多种类，它们统称为生命类型，生命类型相当于传统面向对象编程语言中的类
+ 生命类型之前有继承关系，这个关系和传统面向对象编程语言的继承语义一致

### 文法设计
符号集：和传统编程语言保持一致。  
保留子集：  
```
void | bool | string | null | extends | this | interface | implements | while | for | if | else | return | break | New | NewArray | println! | ReadInteger | ReadLine |
Pool | life | spawn | let | usize | f32 | fn | -> | in | continue | const | loop 
```
整形：  
```
/*十进制数字*/
DIGIT             ([0-9])
/*十六进制数字*/
HEX_DIGIT         ([0-9a-fA-F])
/*十六进制整形*/
HEX_INTEGER       (0[Xx]{HEX_DIGIT}+)
/*整形*/
INTEGER           ({DIGIT}+)
```
浮点数：  
```
/*指数*/
EXPONENT          ([Ee][-+]?{INTEGER})
/*浮点数*/
DOUBLE            ({INTEGER}"."{DIGIT}*{EXPONENT}?)
```
字符串：  
```
/*没闭合的字符串*/
BEG_STRING        (\"[^"\n]*)
/*闭合的字符串*/
STRING            ({BEG_STRING}\")
```
标识符：  
```
IDENTIFIER        ([_a-zA-Z][a-zA-Z_0-9]*)
```
运算符：  
```
([-+/*%=.,;!<>()[\]{}])
```
注释：  
```
/*块注释开头*/
BEG_COMMENT       ("/*")
/*块注释结尾*/
END_COMMENT       ("*/")
/*单行注释*/
SINGLE_COMMENT    ("//"[^\n]*)
```

文法：  
```
Pool : DeclList

DeclList : DeclList Decl
	     | Decl

Decl : VariableDecl 
     | FunctionDecl 
     | LifeDecl 
     | InterfaceDecl

VariableDecl : 'let' Variable ';'

Variable : ident ':' Type

Type : usize 
	 | 'f32'
	 | 'bool'
	 | 'string'
	 | 'void'
	 | ident 
	 | Type[]



InterfaceDecl : 'interface' ident '{' PrototypeList '}'

PrototypeList : Prototype PrototypeList
			  | EPSILON

Prototype : Type ident ( ParamsList ) ; | EPSILON

ParamsList : Param AParam
		   | EPSILON

AParam : ',' Param AParam
       | EPSILON



FunctionDecl :  'fn' ident ( ParamsList ) ':' Type StmtBlock 

StmtBlock : '{' VariableDeclList StmtList '}'

VariableDeclList : VariableDecl VariableDeclList
                 | EPSILON

StmtList : Stmt StmtList
         | EPSLION

Stmt : <Expr>; 
				| IfStmt | WhileStmt | ForStmt | BreakStmt | ReturnStmt | PrintStmt | StmtBlock



LifeDecl ::= life ident <inherit ident> <hunts ident+ ,> <implements ident+ ,> { Field∗ }
Field ::= VariableDecl | FunctionDecl

IfStmt ::= if ( Expr ) Stmt <else Stmt>
WhileStmt  while ( Expr ) Stmt
ForStmt ::= for ( <Expr>; Expr ; <Expr>) Stmt

ReturnStmt 	: 'return' Expr ';'
						| 'return' ';'

BreakStmt ::= break ;
PrintStmt ::= Print ( Expr+ , ) ;
Expr ::= LValue = Expr 
					| Constant 
					| LValue 
					| this 
					| Call 
					| ( Expr ) 
					| Expr + Expr 
					| Expr - Expr 
					| Expr * Expr 
					| Expr / Expr 
					| Expr % Expr 
					| - Expr 
					| Expr < Expr 
					| Expr <= Expr 
					| Expr > Expr 
					| Expr >= Expr 
					| Expr == Expr 
					| Expr != Expr 
					| Expr && Expr 
					| Expr || Expr 
					| ! Expr 
					| ReadInteger ( ) | ReadLine ( ) | New ( ident ) | NewArray ( Expr , Type )
LValue ::= ident | Expr . ident | Expr [ Expr ]
Call ::= ident ( Actuals ) | Expr . ident ( Actuals )
Actuals ::= Expr+ , |
Constant 	: intConstant 
					| doubleConstant
					| boolConstant
					| stringConstant
					| null

```
## 实验二 词法分析器设计与实现
### 词法分析基本概念
词法分析也叫分词，此阶段编译器从左到右扫描源文件，将其字符流分割成一个个词（token），所谓 token，就是源文件中不可再进一步分割的一串字符，类似于英文中单词。  
### flex 简介
flex 是一个快速词法分析生成器，它可以将用户用正则表达式写的分词匹配模式构造成一个有限状态自动机，目前很多编译器都采用它来生成词法分析器。  
首先安装 flex：  
```bash
$ sudo apt-get insatll flex
```

然后新建一个文本文件，输入以下内容：  
```lex
%%
[0-9]+  printf("?");
#       return 0;
.       ECHO;
%%

int main(int argc, char* argv[]) {
    yylex();
    return 0;
}

int yywrap() { 
    return 1;
}
```
另存为 test.l。  
然后终端输入：  
```bash
$ flex test.l
```
此时目录下多了一个 `lex.yy.c` 文件，把这个 C 文件编译并运行一遍：  
```bash
$ gcc -o test lex.yy.c
$ ./test
```
以上就是 `flex` 的基本使用方法。  

### 编写词法分析文件
创建文件 `scanner.l`，下面根据 flex 的写法编写词法分析规则。  
宏定义：  
```lex
/*初始状态*/
%s N
/*
 * %x 是状态定义
 * 这里定义了两个状态
 */
%x COPY COMM
%option stack

/*十进制数字*/
DIGIT             ([0-9])
/*十六进制数字*/
HEX_DIGIT         ([0-9a-fA-F])
/*十六进制整形*/
HEX_INTEGER       (0[Xx]{HEX_DIGIT}+)
/*整形*/
INTEGER           ({DIGIT}+)
/*指数*/
EXPONENT          ([Ee][-+]?{INTEGER})
/*浮点数*/
DOUBLE            ({INTEGER}"."{DIGIT}*{EXPONENT}?)
/*没闭合的字符串*/
BEG_STRING        (\"[^"\n]*)
/*闭合的字符串*/
STRING            ({BEG_STRING}\")
/*标识符*/
IDENTIFIER        ([_a-zA-Z][a-zA-Z_0-9]*)
/*运算符*/
OPERATOR          ([-+/*%=.,;!<>()[\]{}])
/*块注释开头*/
BEG_COMMENT       ("/*")
/*块注释结尾*/
END_COMMENT       ("*/")
/*单行注释*/
SINGLE_COMMENT    ("//"[^\n]*)
```
上面定义了一些正则表达式，方便后面词法规则的书写：  
下面是一些词法规则的定义。  
注释词法规则：  
```lex
 /* -------------------- 注释 ----------------------------- */
{BEG_COMMENT}           { BEGIN(COMM); /*进入块注释状态*/}
<COMM>{END_COMMENT}     { BEGIN(N); /*结束块注释状态，进入默认状态*/}
<COMM><<EOF>>           { ReportError::UntermComment(); return 0; /*块注释没闭合，错误*/ }
<COMM>.                 { /* 跳过 */ }
{SINGLE_COMMENT}        { /* 跳过单行注释 */ }
```

关键字词法规则：  
```lex
 /* --------------------- 关键字 ------------------------------- */
"void"              { return T_Void;        }
"bool"              { return T_Bool;        }
"string"            { return T_String;      }
"null"              { return T_Null;        }
"inherit"           { return T_Inherit;     }
"hunts"             { return T_Hunts;       }
"this"              { return T_This;        }
"interface"         { return T_Interface;   }
"implements"        { return T_Implements;  }
"while"             { return T_While;       }
"for"               { return T_For;         }
"if"                { return T_If;          }
"else"              { return T_Else;        }
"return"            { return T_Return;      }
"break"             { return T_Break;       }
"New"               { return T_New;         }
"NewArray"          { return T_NewArray;    }
"println!"          { return T_Println;       }
"ReadInteger"       { return T_ReadInteger; }
"ReadLine"          { return T_ReadLine;    }
"Pool"               { return T_Pool; }
"life"               { return T_Life; }
"spawn"              { return T_Spawn; }
"let"				      { return T_Let; }
"usize"				   { return T_Usize; }
"f32"                { return T_F32; }
"fn"                 { return T_Fn; }
"->"				      { return T_FuncReturn; }
"in"				      { return T_In; }
"continue"			   { return T_Continue; }
"const"				   { return T_Const; }
"loop"				   { return T_Loop; }
":"                  { return T_Colon; }
```

操作符词法规则：  
```lex
 /* -------------------- 操作符 ----------------------------- */
"<="                { return T_LessEqual;   }
">="                { return T_GreaterEqual;}
"=="                { return T_Equal;       }
"!="                { return T_NotEqual;    }
"&&"                { return T_And;         }
"||"                { return T_Or;          }
{OPERATOR}          { return yytext[0];     }
    
"[]"                { return T_Dims;        }
```

常量词法规则：  
```lex
 /* -------------------- 常量 ------------------------------ */
"true"|"false"      { yylval.boolConstant = (yytext[0] == 't'); // yylval 在 parser.y 里面定义
                         return T_BoolConstant; }
{INTEGER}           { yylval.integerConstant = strtol(yytext, NULL, 10); // strtol: 将字符串转换为 long 类型，第三个参数指定进制
                         return T_IntConstant; }
{HEX_INTEGER}       { yylval.integerConstant = strtol(yytext, NULL, 16);
                         return T_IntConstant; }
{DOUBLE}            { yylval.doubleConstant = atof(yytext); // atof: 将字符串转换成 double
                         return T_DoubleConstant; }
{STRING}            { yylval.stringConstant = strdup(yytext); 
                         return T_StringConstant; }
{BEG_STRING}        { ReportError::UntermString(&yylloc, yytext); 
                        /*没闭合的字符串*/ 
                    }
```

标识符词法规则：  
```lex
 /* -------------------- 标识符 --------------------------- */
{IDENTIFIER}         {
                        if (strlen(yytext) > MaxIdentLen) ReportError::LongIdentifier(&yylloc, yytext);
                        strncpy(yylval.identifier, yytext, MaxIdentLen); // strncpy: 复制字符串的前 n 个字符
                        yylval.identifier[MaxIdentLen] = '\0'; // todo: 这里的逻辑有点不清楚
                        return T_Identifier;
                     }
```

辅助函数部分：  
```C
/* Function: InitScanner
 * 任意时候调用 yylex() 之前都会调用这个函数
 */
void InitScanner()
{
    PrintDebug("lex", "Initializing scanner");
    yy_flex_debug = false; // 这里初始化是否打印调试信息
    BEGIN(N);
    yy_push_state(COPY); // copy first line at start
    curLineNum = 1;
    curColNum = 1;
}


/* Function: DoBeforeEachAction()
 * 记录代码扫描位置
 */
static void DoBeforeEachAction()
{
   yylloc.first_line = curLineNum; // yylloc 是位置信息，会反馈给 bison
   yylloc.first_column = curColNum;
   yylloc.last_column = curColNum + yyleng - 1;
   curColNum += yyleng;
}

/* Function: GetLineNumbered()
 * 返回给定行号的代码
 * scanner 复制了一份源码保存在 savedLines 中
 */
const char *GetLineNumbered(int num) {
   if (num <= 0 || num > savedLines.NumElements()) return NULL;
   return savedLines.Nth(num-1); 
}
```
flex 会将该 `scanner.l` 文件转换成 C 文件，可以被 GCC 编译生成可执行文件，词法分析器就实现了。  
词法分析器用于实验三语法分析器的实现，结果放到实验三一起呈现。  

## 实验三 池语言语法分析器设计与实现
### 语法分析基本概念
词法分析过后，源文件的字符流就被分割成 token 流了，接下来就开始进行语法分析，分析出源程序的语法结构，将线性的 token 流转化成树状结构，为后续的语义分析和代码生成做准备。  
### bison 简介
bison 配合使用，它可以将用户提供的语法规则转化成一个语法分析器，通过一系列的复杂的构造流程，读取用户提供的语法的产生式，生成一个 C 语言格式的 LALR(1) 动作表，并将其包含进一个名为 `yyparse` 的 C 函数，这个函数的作用就是利用这个动作表来解析 token stream，而这个 token 流是由 flex 生成的语法分析器扫描源程序得到的。  
下面是一个例子。  
首先安装 bison:  
```bash
sudo apt-get install bison
```
安装完成后新建一个文本文件，输入内容：  
```lex
%{
#include "y.tab.h"
%}

%%
[0-9]+          { yylval = atoi(yytext); return T_NUM; }
[-/+*()\n]      { return yytext[0]; }
.               { return 0; /* end when meet everything else */ }
%%

int yywrap(void) { 
    return 1;
}
```
这个文件转存为 `calc.l`。  
再新建一个文件 `calc.y`，输入内容：  
```lex
%{
#include <stdio.h>
void yyerror(const char* msg) {}
%}

%token T_NUM

%left '+' '-'
%left '*' '/'

%%

S   :   S E '\n'        { printf("ans = %d\n", $2); }
    |   /* empty */     { /* empty */ }
    ;

E   :   E '+' E         { $$ = $1 + $3; }
    |   E '-' E         { $$ = $1 - $3; }
    |   E '*' E         { $$ = $1 * $3; }
    |   E '/' E         { $$ = $1 / $3; }
    |   T_NUM           { $$ = $1; }
    |   '(' E ')'       { $$ = $2; }
    ;

%%

int main() {
    return yyparse();
}
```
终端输入以下命令生成可执行文件：  
```bash
$ bison -vdty calc.y
$ flex calc.l
$ gcc -o calc y.tab.c lex.yy.c
```
得到 `calc` 可执行文件，然后运行它：  
```bash
$ ./calc
```
终端输入以下算术表达式并回车：  
```
1+2+3
ans = 6
2*(2+7)+8
ans = 26
```
终端输出算术表达式的结果。  
以上就是 bison 的基本工作流程。  
### 编写语法分析文件
首先定义一些 `union`，用于非终结符到具体数据结构的转换:  
```lex
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
```

下面定义一些 `token`:  
```lex
%token   T_Void T_Bool T_String
%token   T_LessEqual T_GreaterEqual T_Equal T_NotEqual T_Dims
%token   T_And T_Or T_Null T_Inherit T_Hunts T_This T_Interface T_Implements
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
```
这些值会被生成到 y.tab.h 头文件去。  

定义一些 `type`，它们表示非终结符：  
```lex
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
```

定义运算符优先级：  
```lex
%nonassoc '='
%left T_Or
%left T_And
%left T_Equal T_NotEqual
%nonassoc '<' T_LessEqual '>' T_GreaterEqual
%left '+' '-'
%left '*' '/' '%'
%right '!' UMINUS
%left '[' '.' /* eso creo, no estoy seguro */
```

下面定义一些规约规则。  
总程序规约规则：  
```lex
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
```
声明列表产生式规约规则：  
```lex
DeclList  :    DeclList Decl        { ($$=$1)->Append($2); /*先对 DeclList 进行规约，然后将 Decl 添加到规约后的结果中*/}
          |    Decl                 { ($$ = new List<Decl*>)->Append($1); /*新建一个列表，存放声明*/}
          ;
```

声明规约规则：  
```lex
Decl      :    VariableDecl          { /*变量声明*/ $$ = $1; }
          |    InterfaceDecl         { /*接口声明*/ $$ = $1; }
          |    LifeDecl             { /*池声明*/ $$ = $1; }
          |    FunctionDecl          { /*函数声明*/ $$ = $1; }
          ;
```

变量声明产生式：  
```lex
VariableDecl  :  T_Let Variable ';' { $$ = $2; }
              ;
```
类型，标识符：  
```lex
Variable  :    T_Identifier T_Colon Type  { 
                                    Identifier *varName = new Identifier(@2, $1); // @n 表示产生式右部第 n 个元素的位置
                                    $$ = new VarDecl( varName, $3 );
                                  }
          ;
```

类型产生式：  
```lex
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
```
接口声明产生式：  
```lex
InterfaceDecl : T_Interface T_Identifier '{' PrototypeList '}' {
                                              Identifier* interfaceName = new Identifier(@2, $2);
                                              $$ = new InterfaceDecl( interfaceName, $4 );
                                            }
              ;
```
原型声明列表产生式：  
```lex
PrototypeList : Prototype PrototypeList     { ($$ = $2)->InsertAt($1, 0); /*添加的原型放在列表的头部*/}
              |                             { $$ = new List< Decl* >(); }
              ;
```
原型产生式：  
```lex
Prototype : T_Fn T_Identifier '(' ParamsList ')' T_FuncReturn Type ';' {
                                              Identifier *funcName = new Identifier(@2, $2);
                                              $$ = new FnDecl(funcName, $7, $4);
                                            }
          ;
```
参数列表声明产生式：  
```lex
ParamsList : Param AParam     { ($$ = $2)->InsertAt($1, 0); }
           |                  { $$ = new List< VarDecl* >(); /*创建一个空列表，元素是 VarDecl 的指针*/ }
           ;
```
第一个后面的参数的产生式：  
```lex
AParam : ',' Param AParam     { ($$ = $3)->InsertAt($2, 0); }
       |                      { $$ = new List< VarDecl* >(); } 
       ;
```
第一个参数的产生式：  
```lex
Param : Variable              { $$ = $1; }
      ;
```
函数声明产生式：  
```lex
FunctionDecl  : T_Fn T_Identifier '(' ParamsList ')' T_FuncReturn Type StmtBlock {
                                              Identifier* functionName = new Identifier(@2, $2);
                                              $$ = new FnDecl(functionName, $7, $4);
                                              $$->SetFunctionBody($8); /* 设置函数体 */
                                            }
              ;
```
生命类型声明产生式：  
```lex
LifeDecl   : T_Life T_Identifier '{' FieldList '}'
              {
                // 普通生命声明
                $$ = new LifeDecl(new Identifier(@2, $2), 
                                    NULL,
                                    new List< NamedType* >(),
                                    new List< NamedType* >(), 
                                    $4);
              }
            | T_Life T_Identifier T_Hunts InterfaceList '{' FieldList '}'
              {
                // 生命声明，有捕食关系
                $$ = new LifeDecl(new Identifier(@2, $2), 
                                    NULL,
                                    $4,
                                    new List< NamedType* >(), 
                                    $6);
              }
            | T_Life T_Identifier T_Inherit T_Identifier '{' FieldList '}'
              {
                // 继承接口的生命声明
                $$ = new LifeDecl(new Identifier(@2, $2), 
                                    new NamedType(new Identifier(@4, $4)), 
                                    new List< NamedType* >(),
                                    new List< NamedType* >(), 
                                    $6);
              }
            | T_Life T_Identifier T_Inherit T_Identifier T_Hunts InterfaceList '{' FieldList '}'
              {
                // 继承接口的生命声明，有捕食关系
                $$ = new LifeDecl(new Identifier(@2, $2), 
                                    new NamedType(new Identifier(@4, $4)), 
                                    $6,
                                    new List< NamedType* >(), 
                                    $8);
              }
            | T_Life T_Identifier T_Implements InterfaceList '{' FieldList '}'
              {
                // 实现接口的生命声明
                $$ = new LifeDecl(new Identifier(@2, $2), 
                                    NULL, 
                                    new List< NamedType* >(),
                                    $4, 
                                    $6);
              }
            | T_Life T_Identifier T_Hunts InterfaceList T_Implements InterfaceList '{' FieldList '}'
              {
                // 实现接口的生命声明，有捕食关系
                $$ = new LifeDecl(new Identifier(@2, $2), 
                                    NULL, 
                                    $4,
                                    $6, 
                                    $8);
              }
            | T_Life T_Identifier T_Inherit T_Identifier T_Implements InterfaceList '{' FieldList '}'
              {
                // 既继承接口又实现接口的生命声明
                $$ = new LifeDecl(new Identifier(@2, $2), 
                                    new NamedType(new Identifier(@4, $4)), 
                                    new List< NamedType* >(),
                                    $6, 
                                    $8);
              }
            | T_Life T_Identifier T_Inherit T_Identifier T_Hunts InterfaceList T_Implements InterfaceList '{' FieldList '}'
              {
                // 既继承接口又实现接口的生命声明，有捕食关系
                $$ = new LifeDecl(new Identifier(@2, $2), 
                                    new NamedType(new Identifier(@4, $4)), 
                                    $6,
                                    $8, 
                                    $10);
              }
            ;
```
接口列表：  
```lex
InterfaceList   : T_Identifier AInterface     { ($$ = $2)->InsertAt(new NamedType(new Identifier(@1, $1)), 0); }
                ;

AInterface  : ',' T_Identifier AInterface     { ($$ = $3)->InsertAt(new NamedType(new Identifier(@2, $2)), 0); }
            |                                 { $$ = new List< NamedType* >(); }
            ;
```
生命内部成员列表产生式：  
```lex
FieldList   : Field FieldList     { ($$ = $2)->InsertAt($1, 0); }
            |                     { $$ = new List< Decl* >(); }
            ;
```
类内部成员产生式：  
```lex
Field : VariableDecl              { $$ = $1; }
      | FunctionDecl              { $$ = $1; }
      ;
```
代码块产生式：  
```lex
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
```
左值产生式：  
```lex
LValue  : T_Identifier           { $$ = new FieldAccess(NULL, new Identifier(@1, $1)); }
        | Expr '.' T_Identifier  { $$ = new FieldAccess($1, new Identifier(@3, $3)); }
        | Expr '[' Expr ']'      { $$ = new ArrayAccess(@1, $1, $3); }
        ;
```
常量产生式：  
```lex
Constant  : T_IntConstant         { $$ = new IntConstant(@1, $1); }
          | T_DoubleConstant      { $$ = new DoubleConstant(@1, $1); }
          | T_BoolConstant        { $$ = new BoolConstant(@1, $1); }
          | T_StringConstant      { $$ = new StringConstant(@1, $1); }
          | T_Null                { $$ = new NullConstant(@1); }
          ;
```
函数调用产生式：  
```lex
Call  : T_Identifier '(' Actuals ')' {
                                    $$ = new Call(@1, NULL, new Identifier(@1, $1), $3);
                                  }
      | Expr '.' T_Identifier '(' Actuals ')' {
                                    $$ = new Call(@1, $1, new Identifier(@3, $3), $5);
                                  }
      ;
```
其他：  
```lex
Actuals : Expr AExpr              { ($$ = $2)->InsertAt($1, 0); }
        |                         { $$ = new List< Expr* >(); }
        ;

AExpr   : ',' Expr AExpr          { ($$ = $3)->InsertAt($2, 0); }
        |                         { $$ = new List< Expr* >(); }
        ;
```
### 抽象语法树 C++ 实现
上面已经完成了 `parser.y` 文件，规约规则在这个文件里面得到体现。  
下面通过 C++ 实现抽象语法树的数据结构。  
语法树节点：  
```C++
class Node 
{
  protected:
    yyltype *location;
    Node    *parent;
    
  public:
    Node(yyltype loc);
    Node();
    
    yyltype *GetLocation()   { return location; }
    void SetParent(Node *p)  { parent = p; }
    Node *GetParent()        { return parent; }

    virtual const char *GetPrintNameForNode() = 0;
    
    // Print() is deliberately _not_ virtual
    // subclasses should override PrintChildren() instead
    void Print(int indentLevel, const char *label = NULL); 
    virtual void PrintChildren(int indentLevel)  {}
};
```
然后每个类型的语法单元或词法单元都继承于这个类。  
比如标识符：  
```C++
class Identifier : public Node 
{
  protected:
    char *name;
    
  public:
    Identifier(yyltype loc, const char *name);
    const char *GetPrintNameForNode()   { return "Identifier"; }
    void PrintChildren(int indentLevel);
};
```
再比如声明：  
```C++
class Decl : public Node 
{
  protected:
    Identifier *id;
  
  public:
    Decl(Identifier *name);
};
```
对于类 `Decl`，也被各种类型的声明继承，比如：  
```C++
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
```
凡是继承了类 `Node` 的类，在抽象语法树上都表示为一个或多个节点。  

### 编写 Makefile
本项目中我们通过 `make` 工具进行项目管理，因此我们需要一个 Makefile：  
```
.PHONY: clean strip

COMPILER = dcc
PRODUCTS = $(COMPILER) 
default: $(PRODUCTS)

SRCS = ast.cc ast_decl.cc ast_expr.cc ast_stmt.cc ast_type.cc errors.cc utility.cc main.cc \
	
OBJS = y.tab.o lex.yy.o $(patsubst %.cc, %.o, $(filter %.cc,$(SRCS))) $(patsubst %.c, %.o, $(filter %.c, $(SRCS)))

JUNK =  *.o lex.yy.c dpp.yy.c y.tab.c y.tab.h *.core core $(COMPILER).purify purify.log 

CC= g++
LD = g++
LEX = flex
YACC = bison

CFLAGS = -g -Wall -Wno-unused -Wno-sign-compare

LEXFLAGS = -d

YACCFLAGS = -dvty

LIBS = -lc -lm -ll

.yy.o: $*.yy.c
	$(CC) $(CFLAGS) -c -o $@ $*.cc

lex.yy.c: scanner.l  parser.y y.tab.h 
	$(LEX) $(LEXFLAGS) scanner.l

y.tab.o: y.tab.c
	$(CC) $(CFLAGS) -c -o y.tab.o y.tab.c

y.tab.h y.tab.c: parser.y
	@$(YACC) $(YACCFLAGS) parser.y > /dev/null 2>&1
.cc.o: $*.cc
	$(CC) $(CFLAGS) -c -o $@ $*.cc

$(COMPILER) :  $(OBJS)
	$(LD) -o $@ $(OBJS) $(LIBS)

$(COMPILER).purify : $(OBJS)
	purify -log-file=purify.log -cache-dir=/tmp/$(USER) -leaks-at-exit=no $(LD) -o $@ $(OBJS) $(LIBS)

strip : $(PRODUCTS)
	strip $(PRODUCTS)
	rm -rf $(JUNK)

depend:
	makedepend -- $(CFLAGS) -- $(SRCS)

clean:
	rm -f $(JUNK) y.output $(PRODUCTS) samples/*.run samples/*.diff samples/dcc

```
终端运行：  
```bash
$ make
```
当前目录会生成一个 `dcc` 可执行文件，这就是实现的语法分析器。  
### 运行结果
创建一个测试源文件 `life.pool`，输入以下内容：  
```
life Animal {
  let name: string;
}

// 鱼声明类型的声明
life Fish inherit Animal hunts Shrimp implements Swim {
  let size: usize;
  fn swim() -> void {
    println!("swimming!");
  }
}

// 虾声明类型的声明
life Shrimp inherit Animal {
  let lenght: f32;
}

// 接口声明
interface Swim {
  fn swim() -> void;
}

fn main() -> void {
  let fish: Fish;
  let a: usize;
  let b: f32;
  let c: f32;
  fish = spawn(Fish);
  fish.swim();
  c = a + b;
  for (i = 0; i < 10; i= i + 1) {
    println!("for loop");
  }
  while(true) {}
  return;
}
```
将这个文件的内容作为 `dcc` 的输入去运行：  
```bash
$ ./dcc < life.pool
```
屏幕会输出分析好的语法树：  
```
   Pool:
  1   LifeDecl:
  1      Identifier: Animal
  2      VarDecl:
            Type: string
  2         Identifier: name
  6   LifeDecl:
  6      Identifier: Fish
  6      (inherit) NamedType:
  6         Identifier: Animal
  6      (hunts) NamedType:
  6         Identifier: Shrimp
  6      (implements) NamedType:
  6         Identifier: Swim
  7      VarDecl:
            Type: usize
  7         Identifier: size
  8      FnDecl:
            (return type) Type: void
  8         Identifier: swim
            (body) StmtBlock:
               PrintStmt:
  9               (args) StringConstant: "swimming!"
 14   LifeDecl:
 14      Identifier: Shrimp
 14      (inherit) NamedType:
 14         Identifier: Animal
 15      VarDecl:
            Type: f32
 15         Identifier: lenght
 19   InterfaceDecl:
 19      Identifier: Swim
 20      FnDecl:
            (return type) Type: void
 20         Identifier: swim
 23   FnDecl:
         (return type) Type: void
 23      Identifier: main
         (body) StmtBlock:
 24         VarDecl:
 24            NamedType:
 24               Identifier: Fish
 24            Identifier: fish
 25         VarDecl:
               Type: usize
 25            Identifier: a
 26         VarDecl:
               Type: f32
 26            Identifier: b
 27         VarDecl:
               Type: f32
 27            Identifier: c
 28         AssignExpr:
 28            FieldAccess:
 28               Identifier: fish
 28            Operator: =
 28            SpawnExpr:
 28               NamedType:
 28                  Identifier: Fish
 29         Call:
 29            FieldAccess:
 29               Identifier: fish
 29            Identifier: swim
 30         AssignExpr:
 30            FieldAccess:
 30               Identifier: c
 30            Operator: =
 30            ArithmeticExpr:
 30               FieldAccess:
 30                  Identifier: a
 30               Operator: +
 30               FieldAccess:
 30                  Identifier: b
            ForStmt:
 31            (init) AssignExpr:
 31               FieldAccess:
 31                  Identifier: i
 31               Operator: =
 31               IntConstant: 0
 31            (test) RelationalExpr:
 31               FieldAccess:
 31                  Identifier: i
 31               Operator: <
 31               IntConstant: 10
 31            (step) AssignExpr:
 31               FieldAccess:
 31                  Identifier: i
 31               Operator: =
 31               ArithmeticExpr:
 31                  FieldAccess:
 31                     Identifier: i
 31                  Operator: +
 31                  IntConstant: 1
               (body) StmtBlock:
                  PrintStmt:
 32                  (args) StringConstant: "for loop"
            WhileStmt:
 34            (test) BoolConstant: true
               (body) StmtBlock:
 35         ReturnStmt:
               Empty:
```
经检查，分析出的语法树正确。  

## 实验四 符号表管理属性计算
### 符号表基本概念
+ 符号表用来体现作用域与可见性信息
+ 符号表的作用：
    * 收集符号属性（词法分析）
    * 上下文语义合法性检查的依据（语法分析）
    * 作为目标代码生成阶段地址分配的依据（语义分析）
+ 符号表中符号可分为关键字符号，操作符符号和标识符符号
+ 符号表中的标识符一般设置的属性项目有：
    * 符号名
    * 符号的类型
    * 符号的存储类型
    * 符号的作用域和可见性
    * 符号变量的存储分配信息
    * 符号的其他属性
+ 实现符号表常用的数据结构
    * 线性表
    * 有序表
    * 二叉搜索树
    * 哈希表

### 实现符号表
下面通过哈希表来实现符号表：  
```C++
template<class Value> class Hashtable {

  private: 
     multimap<const char*, Value, ltstr> mmap;
 
   public:
            // ctor creates a new empty hashtable
     Hashtable() {}

     // 返回条目的数量
     int NumEntries() const;

     // 插入条目
     void Enter(const char *key, Value value,
		    bool overwriteInsteadOfShadow = true);

     // 删除条目.
     void Remove(const char *key, Value value);

     // 根据 key 搜索相应的 value
     Value Lookup(const char *key);

     // 返回迭代器方便遍历
     Iterator<Value> GetIterator();

};
```
然后抽象语法树的每个节点都有一个获取符号表的虚函数：  
```C++
class Node 
{
  protected:
    yyltype *location;
    Node    *parent;
    
  public:
    Node(yyltype loc);
    Node();
    
    yyltype *GetLocation()   { return location; }
    void SetParent(Node *p)  { parent = p; }
    Node *GetParent()        { return parent; }
    virtual void CheckDeclError() {}
    virtual void CheckStatements() {}
    virtual Hashtable<Decl*> *GetSymTable() { return NULL; }
};
```
然后在类声明里面添加符号表的私有成员，比如：  
```C++
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
```
这样在计算节点的属性的时候可以获得符号表的地址，进而获得需要的信息和在抽象语法树上传递属性信息。  

## 实验五 静态语义分析
### 静态语义分析基本概念
+ 和语法分析，词法分析的同时进行词法检查，语法检查一样，语义分析也伴随语义检查
+ 动态语义检查需要生成相应的目标代码，它是在运行时进行的
+ 静态语义检查是在编译期完成的，主要涉及类型检查，控制流检查，一致性检查等
+ 语法制导翻译：为每个产生式配上一个翻译子程序，并在语法分析的同时执行这些子程序
+ 文法符号的属性：
    * 继承属性：从上向下传递，由父节点属性计算得到，由根节点到分支子结点
    * 综合属性：自底向上传递，由子结点属性计算得到，传递方向与继承属性相反


### 编写语义规则文件
在实验三的基础上做了一点修改:  
```lex
#include "scanner.h" // for yylex
#include "parser.h"
#include "errors.h"

void yyerror(const char *msg); // standard error-handling routine

%}

%union {
    Pool *pool;
    LifeDecl* lifeDecl;
    int integerConstant;
    bool boolConstant;
    const char *stringConstant;
    double doubleConstant;
    char identifier[MaxIdentLen+1]; // +1 for terminating null
    Decl *decl;
  

    VarDecl *vardecl;
    FnDecl *fndecl;
    ClassDecl *classdecl;
    InterfaceDecl *interfacedecl;  
    
    Type *simpletype;
    NamedType *namedtype;
    ArrayType *arraytype;
    
    List<NamedType*> *implements;
    List<Decl*> *declList;
    List<VarDecl*> *vardecls;
      
   
    StmtBlock *stmtblock;
    Stmt *stmt;
    IfStmt *ifstmt;
    ForStmt *forstmt;
    WhileStmt *whilestmt;
    ReturnStmt *rtnstmt;	
    BreakStmt *brkstmt;
    SwitchStmt *switchstmt;
    CaseStmt *casestmt;
    DefaultStmt *defaultstmt;
    PrintStmt *pntstmt;
    List<Stmt*> *stmts;
    List<CaseStmt*> *casestmts;
    
    Expr *expr;
    Expr *optexpr;
    List<Expr*> *exprs;
    Call *call;
    
    IntConstant *intconst;
    DoubleConstant *doubleconst;
    BoolConstant *boolconst;
    StringConstant *stringconst;
    NullConstant *nullconst;
    
    ArithmeticExpr *arithmeticexpr;
    RelationalExpr *relationalexpr;
    EqualityExpr   *equalityexpr;
    LogicalExpr    *logicalexpr;
    AssignExpr     *assignexpr;
    PostfixExpr    *postfixexpr;
    
    LValue *lvalue;
    FieldAccess *fieldaccess;
    ArrayAccess *arrayaccess;
}


%token   T_Void T_Bool T_String
%token   T_LessEqual T_GreaterEqual T_Equal T_NotEqual T_Dims T_Increment T_Decrement
%token   T_And T_Or T_Null T_Inherit T_This T_Interface T_Implements
%token   T_While T_For T_If T_Else T_Return T_Break T_Switch T_Case T_Default
%token   T_New T_NewArray T_Println T_ReadInteger T_ReadLine
%token   T_Pool T_Life T_Spawn T_Let T_Usize T_F32 T_Fn T_FuncReturn T_In T_Continue T_Const T_Loop T_Colon


%token   <identifier> T_Identifier
%token   <stringConstant> T_StringConstant
%token   <integerConstant> T_IntConstant
%token   <doubleConstant> T_DoubleConstant
%token   <boolConstant> T_BoolConstant


%type <pool>          Pool
%type <lifeDecl>      LifeDecl
%type <declList>      DeclList
%type <decl>          Decl
%type <vardecl>       VarDecl
%type <fndecl>        FnDecl
%type <interfacedecl> InterfaceDecl
%type <simpletype>    Type
%type <namedtype>     NamedType
%type <arraytype>     ArrayType
%type <vardecls>      Formals
%type <vardecls>      Variables
%type <implements>    Implements
%type <implements>    Impl
%type <namedtype>     Extend
%type <decl>	      Field
%type <declList>      Fields
%type <decl>	      Prototype
%type <declList>      Prototypes
%type <vardecls>      VarDecls
%type <stmt>          Stmt
%type <stmts>         Stmts
%type <stmtblock>     StmtBlock
%type <ifstmt>        IfStmt
%type <whilestmt>     WhileStmt
%type <forstmt>	      ForStmt
%type <rtnstmt>       ReturnStmt
%type <brkstmt>	      BreakStmt
%type <switchstmt>    SwitchStmt
%type <casestmts>     Cases
%type <casestmt>      Case
%type <defaultstmt>   Default
%type <pntstmt>	  PrintStmt
%type <expr>          Expr
%type <expr>          OptExpr
%type <exprs>         Exprs
%type <exprs>	      Actuals
%type <expr>	      Constant
%type <intconst>      IntConstant 
%type <boolconst>     BoolConstant
%type <stringconst>   StringConstant
%type <doubleconst>   DoubleConstant
%type <nullconst>     NullConstant
%type <call>          Call
%type <arithmeticexpr> ArithmeticExpr
%type <relationalexpr> RelationalExpr
%type <equalityexpr>   EqualityExpr
%type <logicalexpr>    LogicalExpr
%type <assignexpr>     AssignExpr
%type <postfixexpr>    PostfixExpr
%type <lvalue>        LValue
%type <fieldaccess>   FieldAccess
%type <arrayaccess>   ArrayAccess

%nonassoc LOWER_THAN_ELSE
%nonassoc T_Else
%nonassoc '='
%left     T_Or
%left     T_And	
%nonassoc T_Equal T_NotEqual
%nonassoc '<' T_LessEqual '>' T_GreaterEqual
%left     '+' '-' 
%left     '*' '/' '%'
%nonassoc '!' UMINUS T_Increment T_Decrement
%nonassoc '[' '.'
 /* this solved the S/R conflict on Type -> Identifier 
    but there might be a better solution  */

Pool   :    DeclList              {
                                      @1;
                                      /* pp2: The @1 is needed to convince
                                       * yacc to set up yylloc. You can remove
                                       * it once you have other uses of @n*/
                                      $$ = new Pool($1);
                                      // if no errors, advance to next phase
                                      if (ReportError::NumErrors() == 0)
                                        {
                                          $$->CheckDeclError();
                                          $$->CheckStatements();
                                        }
                                     }
          ;

DeclList  :    DeclList Decl         { ($$ = $1)->Append($2); }
          |    Decl                  { ($$ = new List<Decl*>)->Append($1); }
          ;

Decl      :    VarDecl              
          |    FnDecl                  
          |    LifeDecl
          |    InterfaceDecl
          ;
          
VarDecl   :    T_Let T_Identifier T_Colon Type ';' { $$ = new VarDecl(new Identifier(@2, $2), $4); }     
          ;
        
Type      :    T_Usize               { $$ = Type::usizeType; }
          |    T_F32                 { $$ = Type::f32Type; }
          |    T_Bool                { $$ = Type::boolType; }
          |    T_String              { $$ = Type::stringType; }
          |    T_Void                { $$ = Type::voidType; }
          |    NamedType
          |    ArrayType
          ;

NamedType :    T_Identifier          { $$ = new NamedType(new Identifier(@1, $1)); }             
          ;

ArrayType :    Type T_Dims           { $$ = new ArrayType(@1, $1); }
          ;

/*
FnDecl    :    Type T_Identifier '(' Formals ')' StmtBlock
                                     { $$ = new FnDecl(new Identifier(@2, $2), $1, $4); 
                                       $$->SetFunctionBody($6); }
          |    T_Void T_Identifier '(' Formals ')' StmtBlock
                                     { $$ = new FnDecl(new Identifier(@2, $2), Type::voidType, $4); 
                                       $$->SetFunctionBody($6); }
          ;
*/

// 函数声明产生式
FnDecl    :     T_Fn T_Identifier '(' Formals ')' T_FuncReturn Type StmtBlock {
                                              Identifier* functionName = new Identifier(@2, $2);
                                              $$ = new FnDecl(functionName, $7, $4);
                                              $$->SetFunctionBody($8); /* 设置函数体 */
                                            }
              ;

Formals   :    Variables  
          |                          { $$ = new List<VarDecl*>; }
          ;
          
Variables :    Variables ',' T_Identifier T_Colon Type
                                     { ($$ = $1)->Append(new VarDecl(new Identifier(@4, $3), $5)); }
          |     T_Identifier T_Colon Type    { ($$ = new List<VarDecl*>)->Append(new VarDecl(new Identifier(@2, $1), $3)); }
          ;
          
LifeDecl :    T_Life T_Identifier Extend Impl '{' Fields '}'              
                                     { $$ = new LifeDecl(new Identifier(@2, $2), $3, $4, $6); }
          |   T_Life T_Identifier Extend Impl '{' '}'
                                     { $$ = new LifeDecl(new Identifier(@2, $2), $3, $4, new List<Decl*>); }                           
          ;

Extend    :    T_Inherit NamedType
                                     { $$ = $2; }
          |                          { $$ = NULL; }          
          ;
          
Impl      :    T_Implements Implements 
                                     { $$ = $2; }
          |                          { $$ = new List<NamedType*>; }
          ;
              
Implements :   Implements ',' NamedType 
                                     { ($$ = $1)->Append($3); }
           |   NamedType             { ($$ = new List<NamedType*>)->Append($1); }
           ;                      

Fields     :   Fields Field          { ($$ = $1)->Append($2); }
           |   Field                 { ($$ = new List<Decl*>)->Append($1);  }
           ;  

Field      :   VarDecl 
           |   FnDecl
           ;
           
InterfaceDecl : T_Interface T_Identifier '{' Prototypes '}'
                                     { $$ = new InterfaceDecl(new Identifier(@2, $2), $4); }
              | T_Interface T_Identifier '{' '}'
                                     { $$ = new InterfaceDecl(new Identifier(@2, $2), new List<Decl*>); }
              ;
/*         
Prototypes : Prototypes Prototype    { ($$ = $1)->Append($2); }
           | Prototype               { ($$ = new List<Decl*>)->Append($1); }
           ;
            
Prototype  : Type T_Identifier '(' Formals ')' ';'
                                     { $$ = new FnDecl(new Identifier(@2, $2), $1, $4); }
           | T_Void T_Identifier '(' Formals ')' ';'
                                     { $$ = new FnDecl(new Identifier(@2, $2), Type::voidType, $4); }
           ;                
*/

// 原型声明列表产生式
Prototypes : Prototype Prototypes     { ($$ = $2)->InsertAt($1, 0); /*添加的原型放在列表的头部*/}
              |                             { $$ = new List< Decl* >(); }
              ;

// 原型产生式
Prototype : T_Fn T_Identifier '(' Formals ')' T_FuncReturn Type ';' {
                                              Identifier *funcName = new Identifier(@2, $2);
                                              $$ = new FnDecl(funcName, $7, $4);
                                            }
          ;

StmtBlock  : '{' VarDecls Stmts '}'  { $$ = new StmtBlock($2, $3); }
           | '{' VarDecls '}'        { $$ = new StmtBlock($2, new List<Stmt*>); }
           ;
           
VarDecls   : VarDecls VarDecl        { ($$ = $1)->Append($2);    }
           |                         { $$ = new List<VarDecl*>;  }
           ;

Stmts      : Stmts Stmt              { ($$ = $1)->Append($2); }
           | Stmt                    { ($$ = new List<Stmt*>)->Append($1);  }
           ;
           
Stmt       : OptExpr ';'  
           | IfStmt
           | WhileStmt
           | ForStmt
           | BreakStmt
           | ReturnStmt
           | SwitchStmt
           | PrintStmt
           | StmtBlock
           ;
          
           
IfStmt     : T_If '(' Expr ')' Stmt  %prec LOWER_THAN_ELSE
                                     { $$ = new IfStmt($3, $5, NULL); }
           | T_If '(' Expr ')' Stmt T_Else Stmt
                                     { $$ = new IfStmt($3, $5, $7); }
           ;
                                     
           
WhileStmt  : T_While '(' Expr ')' Stmt
                                     { $$ = new WhileStmt($3, $5); }
           ;
           
ForStmt    : T_For '(' OptExpr ';' Expr ';' OptExpr ')' Stmt
                                     { $$ = new ForStmt($3, $5, $7, $9); }
           ;
           
ReturnStmt : T_Return OptExpr ';'    { $$ = new ReturnStmt(@2, $2); }
           ;
        
BreakStmt  : T_Break ';'             { $$ = new BreakStmt(@1); }                            
           ;
           
SwitchStmt : T_Switch '(' Expr ')' '{' Cases Default '}'
                                     { $$ = new SwitchStmt($3, $6, $7); }
           ;

Cases      : Cases Case              { ($$ = $1)->Append($2); }
           | Case                    { ($$ = new List<CaseStmt*>)->Append($1); }
           ;

Case       : T_Case IntConstant ':' Stmts        
                                     { $$ = new CaseStmt($2, $4); }
           | T_Case IntConstant ':'  { $$ = new CaseStmt($2, new List<Stmt*>); }
           ;
           
Default    : T_Default ':' Stmts     { $$ = new DefaultStmt($3); }
           |                         { $$ = NULL; }
           ;

PrintStmt  : T_Println '(' Exprs ')' ';' 
                                     { $$ = new PrintStmt($3); }
           ;
           
Expr       :  AssignExpr          
           |  Constant
           |  LValue
           |  T_This                 { $$ = new This(@1); }
           |  Call
           |  '(' Expr ')'           { $$ = $2; }
           |  ArithmeticExpr
           |  EqualityExpr
           |  RelationalExpr
           |  LogicalExpr
           |  PostfixExpr
    	     |  T_ReadInteger '(' ')'  { $$ = new ReadIntegerExpr(Join(@1, @3)); }
           |  T_ReadLine '(' ')'     { $$ = new ReadLineExpr(Join(@1, @3)); }
           |  T_New T_Identifier     { $$ = new NewExpr(Join(@1, @2), new NamedType(new Identifier(@2, $2))); }
           |  T_Spawn '(' T_Identifier ')' { $$ = new SpawnExpr(Join(@1, @3), new NamedType(new Identifier(@2, $3))); }
           |  T_NewArray '(' Expr ',' Type ')'
                                     { $$ = new NewArrayExpr(Join(@1, @6), $3, $5); }
           ;

AssignExpr     : LValue '=' Expr     
                                     { $$ = new AssignExpr($1, new Operator(@2, "="), $3); } 
               ;
   
ArithmeticExpr : Expr '+' Expr       { $$ = new ArithmeticExpr($1, new Operator(@2, "+"), $3); }
               | Expr '-' Expr       { $$ = new ArithmeticExpr($1, new Operator(@2, "-"), $3); } 
               | Expr '*' Expr       { $$ = new ArithmeticExpr($1, new Operator(@2, "*"), $3); }
               | Expr '/' Expr       { $$ = new ArithmeticExpr($1, new Operator(@2, "/"), $3); }
               | Expr '%' Expr       { $$ = new ArithmeticExpr($1, new Operator(@2, "%"), $3); }
               | '-' Expr %prec UMINUS
                                     { $$ = new ArithmeticExpr(new Operator(@1, "-"), $2); }
               ;

PostfixExpr    : LValue T_Increment  { $$ = new PostfixExpr(Join(@1, @2), $1, new Operator(@2, "++")); }
               | LValue T_Decrement  { $$ = new PostfixExpr(Join(@1, @2), $1, new Operator(@2, "--")); }
               ;
               
EqualityExpr   : Expr T_Equal Expr   
                                     { $$ = new EqualityExpr($1, new Operator(@2, "=="), $3); }
               | Expr T_NotEqual Expr
                                     { $$ = new EqualityExpr($1, new Operator(@2, "!="), $3); }                        
               ;
                                            
RelationalExpr : Expr '<' Expr
                                     { $$ = new RelationalExpr($1, new Operator(@2, "<"), $3); }
               | Expr '>' Expr
                                     { $$ = new RelationalExpr($1, new Operator(@2, ">"), $3); } 
               | Expr T_LessEqual Expr 
                                     { $$ = new RelationalExpr($1, new Operator(@2, "<="), $3); }                     
               | Expr T_GreaterEqual Expr 
                                     { $$ = new RelationalExpr($1, new Operator(@2, ">="), $3); } 
               ;

LogicalExpr    : Expr T_And Expr 
                                     { $$ = new LogicalExpr($1, new Operator(@2, "&&"), $3); }
               | Expr T_Or Expr 
                                     { $$ = new LogicalExpr($1, new Operator(@2, "||"), $3); }
               | '!' Expr            { $$ = new LogicalExpr(new Operator(@1, "!"), $2); }
               ;               


Exprs      : Exprs ',' Expr          { ($$ = $1)->Append($3); }
           | Expr                    { ($$ = new List<Expr*>)->Append($1); }
           ; 

OptExpr    : Expr
           |                         { $$ = new EmptyExpr(); }
           ;
 
            
LValue     : FieldAccess             
           | ArrayAccess 
           ; 

FieldAccess : T_Identifier           { $$ = new FieldAccess(NULL, new Identifier(@1, $1)); }
            | Expr '.' T_Identifier
                                     { $$ = new FieldAccess($1, new Identifier(@3, $3)); }
            ;

Call       : T_Identifier '(' Actuals ')' 
                                     { $$ = new Call(Join(@1, @4), NULL, new Identifier(@1, $1), $3); }  
           | Expr '.' T_Identifier '(' Actuals ')'
                                     { $$ = new Call(Join(@1, @6), $1, new Identifier(@3, $3), $5); }
           ;

ArrayAccess : Expr '[' Expr ']'      { $$ = new ArrayAccess(Join(@1, @4), $1, $3); }
            ;
           
Actuals    : Exprs 
           |                         { $$ = new List<Expr*>; }
           ;
           
Constant   : IntConstant            
           | DoubleConstant
           | BoolConstant
           | StringConstant
           | NullConstant
           ;

IntConstant    : T_IntConstant       { $$ = new IntConstant(@1, $1); }
               ;
            
DoubleConstant : T_DoubleConstant    { $$ = new DoubleConstant(@1, $1); }
               ;
               
BoolConstant   : T_BoolConstant      { $$ = new BoolConstant(@1, $1); }
               ;
               
StringConstant : T_StringConstant    { $$ = new StringConstant(@1, $1); }
               ;
               
NullConstant   : T_Null              { $$ = new NullConstant(@1); }
               ;
%%

void InitParser()
{
   PrintDebug("parser", "Initializing parser");
   yydebug = false;
}

```

### 语义检查 C++ 实现
抽象语法树的节点定义进行了修改，不再需要 `Print` 还有 `PrintChildren` 方法，取而代之的是一系列检查语义正确性的方法：  
```C++
class Node 
{
  protected:
    yyltype *location;
    Node    *parent;
    
  public:
    Node(yyltype loc);
    Node();
    
    yyltype *GetLocation()   { return location; }
    void SetParent(Node *p)  { parent = p; }
    Node *GetParent()        { return parent; }
    virtual void CheckDeclError() {}
    virtual void CheckStatements() {}
    virtual Hashtable<Decl*> *GetSymTable() { return NULL; }
};
```
下面是所有语义错误的定义：  
```C++
#ifndef _errors_h_
#define _errors_h_

#include <string>
#include "location.h"

using std::string;

class Type;
class Identifier;
class Expr;
class BreakStmt;
class ReturnStmt;
class This;
class Decl;
class Operator;
class FnDecl;

typedef enum {LookingForType, LookingForClass, LookingForInterface, LookingForVariable, LookingForFunction} reasonT;

class ReportError {
 public:

  // Errors used by scanner
  static void UntermComment(); 
  static void LongIdentifier(yyltype *loc, const char *ident);
  static void UntermString(yyltype *loc, const char *str);
  static void UnrecogChar(yyltype *loc, char ch);

  
  // Errors used by semantic analyzer for declarations
  static void DeclConflict(Decl *newDecl, Decl *prevDecl);
  static void OverrideMismatch(Decl *fnDecl);
  static void InterfaceNotImplemented(Decl *lifeDecl, Type *intfType);


  // Errors used by semantic analyzer for identifiers
  static void IdentifierNotDeclared(Identifier *ident, reasonT whyNeeded);


  // Errors used by semantic analyzer for expressions
  static void IncompatibleOperand(Operator *op, Type *rhs); // unary
  static void IncompatibleOperands(Operator *op, Type *lhs, Type *rhs); // binary
  static void ThisOutsideClassScope(This *th);

  
 // Errors used by semantic analyzer for array acesss & NewArray
  static void BracketsOnNonArray(Expr *baseExpr); 
  static void SubscriptNotInteger(Expr *subscriptExpr);
  static void NewArraySizeNotInteger(Expr *sizeExpr);


  // Errors used by semantic analyzer for function/method calls
  static void NumArgsMismatch(Identifier *fnIdentifier, int numExpected, int numGiven);
  static void ArgMismatch(Expr *arg, int argIndex, Type *given, Type *expected);
  static void PrintArgMismatch(Expr *arg, int argIndex, Type *given);


  // Errors used by semantic analyzer for field access
  static void FieldNotFoundInBase(Identifier *field, Type *base);
  static void InaccessibleField(Identifier *field, Type *base);


  // Errors used by semantic analyzer for control structures
  static void TestNotBoolean(Expr *testExpr);
  static void ReturnMismatch(ReturnStmt *rStmt, Type *given, Type *expected);
  static void NoReturnStmt(FnDecl *fun);
  static void BreakOutsideLoop(BreakStmt *bStmt);


  // Generic method to report a printf-style error message
  static void Formatted(yyltype *loc, const char *format, ...);


  // Returns number of error messages printed
  static int NumErrors() { return numErrors; }
  
 private:
  static void UnderlineErrorInLine(const char *line, yyltype *pos);
  static void OutputError(yyltype *loc, string msg);
  static int numErrors;
};
#endif
```
下面是声明类型声明的类：  
```C++
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
```
可以看到该类的私有成员里面有符号表 `sym_table`，当语义分析到某个具体生命类型定义的时候，就会在这个符号表里面寻找需要的信息。  
`LifeDecl` 类有两个检查语义正确性的方法，`CheckStatements`，`CheckDeclError`，在进行静态语义检查的时候，这两个方法会派上用场。  
下面是 `LifeDecl::CheckStatements` 的实现：  
```C++
void LifeDecl::CheckStatements() {
  if (this->members)
    {
      for (int i = 0; i < this->members->NumElements(); i++)
	this->members->Nth(i)->CheckStatements();
    }
}
```
实现方法是遍历 `List<Decl*> *members` 中所有成员，分别调用它们的 `CheckStatements` 方法，如果所有成员的该方法都没出错，那么该结点的 `CheckStatements` 就通过了。  
项目中其他的语法类型也是通过类似的方法进行语义检查的。  

### 运行结果
针对不同类型的语义错误，分别写了测试文件，用上述实现的语义分析器对它们进行语义检查，以测试实现的正确性。  
使用未定义的变量：  
```
fn main() -> void {
    a = 0;
}
```
结果：  
```
*** Error line 2.
    a = 0;
    ^
*** No declaration found for variable 'a'
```
调用未定义或未声明的函数：  
```
fn main() -> void {
    let a: usize;
    a = 0;
    undefined();
}
```
结果：  
```
*** Error line 4.
    undefined();
    ^^^^^^^^^
*** No declaration found for function 'undefined'
```
在同一作用域，名称重复定义：  
```
fn main() -> void {
    let a: usize;
    let a: f32;
    a = 0;
}
```
结果：  
```
*** Error line 3.
    let a: f32;
        ^
*** Declaration of 'a' here conflicts with declaration on line 2
```
对非函数名采用函数调用方式：  
```
fn main() -> void {
    let a: usize;
    a();    
}
```
结果：  
```
*** Error line 3.
    a();
    ^
*** No declaration found for function 'a'
```
函数调用时参数个数不匹配：  
```
fn add(x: usize, y: usize) -> usize {
    return x + y;
}

fn main() -> void {
    let a: usize;
    let b: usize;
    let c: usize;
    let d: usize;
    a = 1;
    b = 2;
    d = 3;
    // c = add(a, b);
    // c = add(a);
    c = add(a, b, d);
}
```
结果：  
```
*** Error line 15.
    c = add(a, b, d);
        ^^^
*** Function 'add' expects 2 arguments but 3 given
```
(测试没有全部列出)  
可以看到语义分析器工作正常。  
## 总结
### 实验完成情况
由于时间关系，8 个实验只完成了 5 个，后面几个实验可能难度相对较低，但前面实验花了较多功夫，后面的实验只能遗憾放弃。  
### 实验感想
通过本次编译原理实验，我收获良多，主要有下面几个方面：  
+ 熟悉了 flex 和 bison 工具的使用，词法分析，语法分析和语义分析都是基于这两个工具完成的
+ 在实践过程中熟悉了源代码文件到目标代码之间的全过程
+ 深刻感受到了编译原理这门学科的深奥和价值。  

### 展望
编译原理是一门深奥且有用的学科，在现代处理核大部分采用分支预测技术的背景下，编译原理可以结合处理核分支预测策略，进一步提高系统性能。  
此外，学习编译原理对于程序员代码能力的提高也是有好处的，深刻理解编译原理某种程度上可以提高自己的代码的表现力。  
希望本门实验课程可以在我将来的工作生产环境上派上用场。  
