/* 池语言词法分析 Flex 源程序 */

%{
#include "pool.h"
int cur_line_num = 1;
int doc_comment_num = 0;
static char* token_strs[] = {
	"T_LessEqual", "T_GreaterEqual", "T_Equal", "T_NotEqual", "T_And", "T_Or",
	"T_Pool", "T_Life", "T_Spawn", "T_let",
	"T_Usize", "T_String", "T_Bool", "T_FuncReturn", "T_For", "T_In", "T_While", "T_If", "T_Else",
	"T_Return", "T_Break", "T_Continue", "T_Const", "T_True", "T_False", "T_Loop",
	"T_IntConstant", "T_StringConstant", "T_Char", "T_IDENTIFIER",
	"T_SingleComment", "T_DocComment1", "T_DocComment2"
};
void lex_error(LexErrorType e, int line);
%}

INTEGER         	([0-9]+|0x[0-9a-f]+)
UNTERM_STRING       (\042[^\042\n]*)
STRING              (\042[^\042\n]*\042)
UNTERM_CHAR         (\'[^\'])
CHAR              	(\'[^\']\')
UNVALID_CHAR        (\'[^\']*\')
IDENTIFIER          ([_a-zA-Z][_a-zA-Z0-9]*)
OPERATOR            ([+*-/%=,;!<>(){}:])
SINGLE_COMMENT		("//"[^\n]*)
DOC_COMMENT_1		("///"[^\n]*)
DOC_COMMENT_2		("//!"[^\n]*)

%%
[\n]				{
	// 换行符
	cur_line_num++;
}

[ \t\r\a]+			{
	// 忽视所有空格
}

{DOC_COMMENT_1}		{
	// 文档注释1
	doc_comment_num++;
	return T_SingleComment;
}
{DOC_COMMENT_2}		{
	// 文档注释2
	doc_comment_num++;
	return T_DocComment1;
}
{SINGLE_COMMENT}	{
	// 单行注释
	doc_comment_num++;
	return T_DocComment2;
}

{OPERATOR}			{
	// 运算符
	return yytext[0];
}

"<="                { return T_LessEqual; }
">="                { return T_GreaterEqual; }
"=="                { return T_Equal; }
"!="                { return T_NotEqual; }
"&&"                { return T_And; }
"||"                { return T_Or; }

"Pool"				{
	// 池定义关键字
	return T_Pool;
}

"Life"				{
	// 生命类型定义关键字
	return T_Life;
}

"spawn"				{
	// 孵化语义定义
	return T_Spawn;
}

"let"				{ return T_Let; }
"usize"				{ return T_Usize; }
"string"			{ return T_String; }
"bool"				{ return T_Bool; }
"->"				{ return T_FuncReturn; }
"for"				{ return T_For; }
"in"				{ return T_In; }
"while"				{ return T_While; }
"if"				{ return T_If; }
"else"				{ return T_Else; }
"return"			{ return T_Return; }
"break"				{ return T_Break; }
"continue"			{ return T_Continue; }
"const"				{ return T_Const; }
"true"				{ return T_True; }
"false"				{ return T_False; }
"loop"				{ return T_Loop; }

{INTEGER}       	{
	// 整形常量
	return T_IntConstant;
}

{STRING}			{
	// 字符串常量
	return T_StringConstant;	
}

{CHAR}				{
	// 字符常量
	return T_Char;
}

{IDENTIFIER}		{
	// 标识符
	return T_IDENTIFIER;
}

<<EOF>>         	{ return 0; }

{UNVALID_CHAR}		{
	// 不合法的字符
	lex_error(UnvalidChar, cur_line_num);
}

{UNTERM_CHAR}		{
	// 没闭合的字符
	lex_error(UnterminatedChar, cur_line_num);
}

{UNTERM_STRING}		{
	// 没闭合的字符串
	lex_error(UnterminatedString, cur_line_num);
}

.					{ lex_error(UnrecognizedCharacter, cur_line_num); }
%%


int main(int argc, char* argv[]) {
    int token_type;
	while (token_type = yylex()) {
		if(token_type < 256) {
			printf("T_Operator:\t%s\n", yytext);
		} else {
			printf("%s\t%s\n", token_strs[token_type - 256], yytext);
		}		
	}
	printf("lines: %d, doc comments: %d\n", cur_line_num, doc_comment_num);
    return 0;
}

void lex_error(LexErrorType e, int line) {
	if(e == UnterminatedString) {
		printf("Unterminated string at line %d: %s\n", line, yytext);
	} else if (e == UnterminatedChar) {
		printf("Unterminated char at line %d: %s\n", line, yytext);
	} else if (e == UnrecognizedCharacter) {
		printf("Unrecognized character at line %d: %s\n", line, yytext);
	} else if (e == UnvalidChar) {
		printf("Unvalid char at line %d: %s\n", line, yytext);
	}
	exit(-1);
}

int yywrap() {
    return 1;
}