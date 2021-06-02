# 池语言文法设计

## 语言命名
+ 中文名：池语言

(下面用 null 表示不存在任何符号)

## 符号集
和传统编程语言保持一致。  

## 保留字集
```
void | bool | string | null | extends | this | interface | implements | while | for | if | else | return | break | New | NewArray | println! | ReadInteger | ReadLine |
Pool | life | spawn | let | usize | f32 | fn | -> | in | continue | const | loop 
```  

## 运算符
```
([-+/*%=.,;!<>()[\]{}])
```

## 界符
```
{ | }
```
## 标识符文法
```
([_a-zA-Z][a-zA-Z_0-9]*)
```

## 常数文法
```
Constant        ::= IntConstant | IntConstant16 | BoolConstant | StringConstant | DoubleConstant

DIGIT           ::= ([0-9])
HEX_DIGIT       ::= ([0-9a-fA-F])
IntConstant     ::= ({DIGIT}+)
IntConstant16   ::= (0[Xx]{HEX_DIGIT}+)

BoolConstant    ::= true | false
/*没闭合的字符串*/
BEG_STRING      ::= (\"[^"\n]*)
StringConstant  ::= ({BEG_STRING}\")

/*指数*/
EXPONENT        ::= ([Ee][-+]?{IntConstant})
DoubleConstant  ::= ({IntConstant}"."{DIGIT}*{EXPONENT}?)
```

## 字符串文法
字符串文法和上面的 StringConstant 一致。  

## 初步文法
```
// 池定义
Pool : DeclList

// 生命的列表
DeclList : DeclList Decl
	     | Decl

Decl : VariableDecl 
     | FunctionDecl 
     | LifeDecl 
     | InterfaceDecl

// 变量声明
VariableDecl : 'let' Variable ';'

Variable : ident ':' Type

Type : usize 
	 | 'f32'
	 | 'bool'
	 | 'string'
	 | 'void'
	 | ident 
	 | Type[]


// 接口声明
InterfaceDecl : 'interface' ident '{' PrototypeList '}'

// 原型声明的列表
PrototypeList : Prototype PrototypeList
			  | EPSILON

// 原型声明
Prototype : Type ident ( ParamsList ) ; | EPSILON

// 参数列表
ParamsList : Param AParam
		   | EPSILON

AParam : ',' Param AParam
       | EPSILON


// 函数声明
FunctionDecl :  'fn' ident ( ParamsList ) ':' Type StmtBlock 

StmtBlock : '{' VariableDeclList StmtList '}'

// 变量声明列表
VariableDeclList : VariableDecl VariableDeclList
                 | EPSILON

StmtList : Stmt StmtList
         | EPSLION

Stmt : <Expr>; 
				| IfStmt | WhileStmt | ForStmt | BreakStmt | ReturnStmt | PrintStmt | StmtBlock


// 声明类型声明
LifeDecl ::= life ident <extends ident> <hunts ident+ ,> <implements ident+ ,> { Field∗ }
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