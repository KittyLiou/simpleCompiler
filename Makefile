OBJS	= bison.o lex.o main.o

CC		= g++
CFLAGS	= -g -Wall -pedantic

parser: $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o parser -ll

lex.o: lex.c
	$(CC) $(CFLAGS) -c lex.c -o lex.o

lex.c: lexer.l
	flex lexer.l
	cp lex.yy.c lex.c

bison.o: bison.c
	$(CC) $(CFLAGS) -c bison.c -o bison.o

bison.c: parser.y
	bison -d -v parser.y
	cp parser.tab.c bison.c
	cmp -s parser.tab.h tok.h || cp parser.tab.h tok.h

main.o: main.c
	$(CC) $(CFLAGS) -c main.c -o main.o

lex.o yac.o main.o: heading.h
lex.o main.o: tok.h

clean:
	rm -f *.o *~ lex.c lex.yy.c bison.c tok.h parser.tab.c parser.tab.h parser.output parser

