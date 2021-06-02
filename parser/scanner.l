/* File:  scanner.l
 * ----------------
 * Lex inupt file to generate the scanner for the compiler.
 */

%{

#include <string.h>
#include "scanner.h"
#include "utility.h" // for PrintDebug()
#include "errors.h"
#include "parser.h" // for token codes, yylval
#include "list.h"

#define TAB_SIZE 8

/* Global variables
 * ----------------
 * (For shame!) But we need a few to keep track of things that are
 * preserved between calls to yylex or used outside the scanner.
 */
static int curLineNum, curColNum;
List<char*> savedLines;

static void DoBeforeEachAction(); 
#define YY_USER_ACTION DoBeforeEachAction();

%}

/* States
 * ------
 * A little wrinkle on states is the COPY exclusive state which
 * I added to first match each line and copy it ot the list of lines
 * read before re-processing it. This allows us to print the entire
 * line later to provide context on errors.
 * todo: 理解这里
 */

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


/* 词法规则定义 */
%%             

<COPY>.*                { 
                           char curLine[512];
                            //strncpy(curLine, yytext, sizeof(curLine));
                           savedLines.Append(strdup(yytext)); // strdup函数：分配空间，复制字符串，返回地址
                           curColNum = 1; /*行数自增*/
                           yy_pop_state(); /*从栈出弹出下一个状态成为当前状态*/
                           yyless(0); /*重新放入输入流*/
                        }

<COPY><<EOF>>           { yy_pop_state(); }

<*>([\r]?\n)                   { 
                           curLineNum++;
                           curColNum = 1;
                           if (YYSTATE == COPY) savedLines.Append("");
                           else yy_push_state(COPY);
                        }

[ ]+                    { /* 跳过所有空格 */  }

<*>[\t]                 { curColNum += TAB_SIZE - curColNum%TAB_SIZE + 1; }

 /* -------------------- 注释 ----------------------------- */
{BEG_COMMENT}           { BEGIN(COMM); /*进入块注释状态*/}
<COMM>{END_COMMENT}     { BEGIN(N); /*结束块注释状态，进入默认状态*/}
<COMM><<EOF>>           { ReportError::UntermComment(); return 0; /*块注释没闭合，错误*/ }
<COMM>.                 { /* 跳过 */ }
{SINGLE_COMMENT}        { /* 跳过单行注释 */ }


 /* --------------------- 关键字 ------------------------------- */
"void"              { return T_Void;        }
"double"            { return T_Double;      }
"bool"              { return T_Bool;        }
"string"            { return T_String;      }
"null"              { return T_Null;        }
"class"             { return T_Class;       }
"extends"           { return T_Extends;     }
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
"Print"             { return T_Print;       }
"ReadInteger"       { return T_ReadInteger; }
"ReadLine"          { return T_ReadLine;    }

 /* ---------下面是池语言特有的关键字----------- */
"Pool"               { return T_Pool; }
"life"               { return T_Life; }
"spawn"              { return T_Spawn; }
"let"				      { return T_Let; }
"usize"				   { return T_Usize; }
"f32"                { return T_F32; }
"->"				      { return T_FuncReturn; }
"in"				      { return T_In; }
"continue"			   { return T_Continue; }
"const"				   { return T_Const; }
"loop"				   { return T_Loop; }




 /* -------------------- 操作符 ----------------------------- */
"<="                { return T_LessEqual;   }
">="                { return T_GreaterEqual;}
"=="                { return T_Equal;       }
"!="                { return T_NotEqual;    }
"&&"                { return T_And;         }
"||"                { return T_Or;          }
{OPERATOR}          { return yytext[0];     }
    
"[]"                { return T_Dims;        }

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


 /* -------------------- 标识符 --------------------------- */
{IDENTIFIER}         {
                        if (strlen(yytext) > MaxIdentLen) ReportError::LongIdentifier(&yylloc, yytext);
                        strncpy(yylval.identifier, yytext, MaxIdentLen); // strncpy: 复制字符串的前 n 个字符
                        yylval.identifier[MaxIdentLen] = '\0'; // todo: 这里的逻辑有点不清楚
                        return T_Identifier;
                     }


 /* -------------------- 错误 -------------------- */
.                   { ReportError::UnrecogChar(&yylloc, yytext[0]); }

%%


/* Function: InitScanner
 * ---------------------
 * This function will be called before any calls to yylex().  It is designed
 * to give you an opportunity to do anything that must be done to initialize
 * the scanner (set global variables, configure starting state, etc.). One
 * thing it already does for you is assign the value of the global variable
 * yy_flex_debug that controls whether flex prints debugging information
 * about each token and what rule was matched. If set to false, no information
 * is printed. Setting it to true will give you a running trail that might
 * be helpful when debugging your scanner. Please be sure the variable is
 * set to false when submitting your final version.
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
 * ------------------------------
 * This function is installed as the YY_USER_ACTION. This is a place
 * to group code common to all actions.
 * On each match, we fill in the fields to record its location and
 * update our column counter.
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
 * ---------------------------
 * Returns string with contents of line numbered n or NULL if the
 * contents of that line are not available.  Our scanner copies
 * each line scanned and appends each to a list so we can later
 * retrieve them to report the context for errors.
 * 返回给定行号的代码
 * scanner 复制了一份源码保存在 savedLines 中
 */
const char *GetLineNumbered(int num) {
   if (num <= 0 || num > savedLines.NumElements()) return NULL;
   return savedLines.Nth(num-1); 
}


