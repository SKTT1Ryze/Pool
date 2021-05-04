# 该 Makefile 用于生成池语言词法分析器

build: pool-lex

pool-lex: lex.yy.c pool.h
	gcc -o $@ $<

lex.yy.c: pool.l
	flex $<

clean:
	rm lex.yy.c
	rm pool-lex