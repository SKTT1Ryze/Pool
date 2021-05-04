// 一些单词类型在这里定义

// 单词类型
typedef enum {
    T_LessEqual = 256,
    T_GreaterEqual,
    T_Equal,
    T_NotEqual,
    T_And,
    T_Or,
    // 池定义关键字
    T_Pool,
    // 生命类型定义关键字
    T_Life,
    // 孵化语义关键字
    T_Spawn,
    T_Let,
    T_Usize,
    T_String,
    T_Bool,
    T_FuncReturn,
    T_For,
    T_In,
    T_While,
    T_If,
    T_Else,
    T_Return,
    T_Break,
    T_Continue,
    T_Const,
    T_True,
    T_False,
    T_Loop,
    // 整形常量
    T_IntConstant,
    // 字符串常量
    T_StringConstant,
    // 字符常量
    T_Char,
    // 标识符
    T_IDENTIFIER,
    // 单行注释
    T_SingleComment,
    // 文档注释 1
    T_DocComment1,
    // 文档注释 2
    T_DocComment2
} TokenType;

// 词法错误类型
typedef enum {
    UnterminatedString,
    UnterminatedChar,
    UnvalidChar,
    UnrecognizedCharacter
} LexErrorType;