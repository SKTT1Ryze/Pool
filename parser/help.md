# Flex/Bison 帮助文档

## 宏或者函数
+ ECHO: 把 yytex 输出
+ BEGIN(状态): 进入状态
+ REJECT: 回退并寻找次优匹配
+ yymore(): 下一次迭代中把匹配值附加到当前 yytext 后而非取代之
+ yyless(n): 把 yytext 除前 n 个外的字符送加输入流
+ unput(c): 把字符 c 送回输入流
+ input(): 读入一个字符
+ YY_FLUSH_BUFFER: 清空内部缓冲
+ yyterminate(): 结束扫描
+ yy_push_state(new_state): 把当前状态推入栈并把状态设为 new_state
+ yy_pop_state(): 把栈顶弹出成当前状态
+ yy_top_state(): 返回栈顶，但不弹出
+ yylloc: 其为位置信息，即匹配的 token 在整个输入流中的位置。flex 通过这个值反馈给 Bison 中的 yypars
+ yyleng: 匹配 token 对应字符串的长度
+ yylval: 在 bison yyparse  函数中调用，返回值可以理解为两部分，一个是在规则中的 return 值，此为返回的 token，另一个是与之一一对应的 yylval
+   
