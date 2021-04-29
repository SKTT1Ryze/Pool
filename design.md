# 池语言文法设计

## 语言命名
+ 中文名：池语言

(下面用 null 表示不存在任何符号)

## 符号集
和传统编程语言保持一致。  

## 保留字集
Rust 语言的保留字集的字集加上池语言特有保留字集。  
池语言特有保留字集：{Pool(池), Life(生命), spawn(孵化，对应于传统面向对象编程语言中的 new), inherit(继承), compete(竞争), cooperate(合作), hunt(捕食)}，等等。  

## 运算符
和 Rust 语言保持一致。  

## 界符
和 Rust 语言保持一致。  

## 标识符文法
```
identifier  ::= F T
F           ::= _ | WORD
T           ::= T S | null
S           ::= _ | WORD | NUM
WORD        ::= a | b | c | d | e | f | g | h | i | j | k | l | m | n |
    o | p | q | r | s | t | u | v | w | x | y | z
NUM         ::= 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
```

## 常数文法
```
Constant        ::= IntConstant | BoolConstant | StringConstant

IntConstant     ::= IntConstant16 | IntConstant10
IntConstant16   ::= 0x (Int16)*
Int16           ::= 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | a | b | c | d | e | f
IntConstant10   ::= F Z
F               ::= + | - | null
Z               ::= Z D | null
D               ::= 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

BoolConstant    ::= true | false

StringConstant  ::= "(单词)*"
```

## 字符串文法
字符串文法和上面的 StringConstant 定义一样。  

## 初步文法
```
App                 ::= PoolDef LifeDef+
// 池定义
PoolDef             ::= Pool identifier { Field* }

// 类型
Type                ::= usize | bool | string | life identifier | Type []

// 生命类型定义
LifeDef             ::= Life identifier <inherit identifier> <compete identifier> <cooperate identifier> <hunt identifier> { Field* }

// 生命实例定义
LifeInstanceDef     ::= LifeInstance ;
LifeInstance        ::= let identifier: Type

FunctionDef         ::= fn identifier ( Formals )
```