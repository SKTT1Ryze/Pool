# 华中科技大学编译原理实验报告

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

## 实验四 符号表管理属性计算
## 实验五 静态语义分析
## 总结
### 实验完成情况
### 实验感想
### 展望