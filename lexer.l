%option yylineno

%option noinput
%option nounput

%{
	#include "heading.h"
	#include "tok.h"
	#include "parser.tab.h"
	extern int yylex();
%}


	int cur_line = 1;
	char keyword[20] = "<Keyword>"; 
	char op[20] = "<Operator>"; 
	char identifier[20] = "<Identifier>"; 
	char symbol[20] = "<Special Symbol>"; 
	char number[20] = "<Number>"; 
	char character[20] = "<Char>"; 
	char comment[20] = "<Comment>";
	char error[20] = "<Error>";

%%
[\n]	;
[ \t]	;

int		{
			printf("Line %d %-20s int\n", yylineno, keyword);
			yylval.op_val = new std::string(yytext);
			return INT;
		}
char	{
			printf("Line %d %-20s char\n", yylineno, keyword);	
			yylval.op_val = new std::string(yytext);
			return CHAR;
		}
return	{
			printf("Line %d %-20s return\n", yylineno, keyword);	
			yylval.op_val = new std::string(yytext);
			return RET;
		}
if		{
			printf("Line %d %-20s if\n", yylineno, keyword);	
			yylval.op_val = new std::string(yytext);
			return IF;
		}
else	{
			printf("Line %d %-20s else\n", yylineno, keyword);	
			yylval.op_val = new std::string(yytext);
			return ELSE;
		}
while	{
			printf("Line %d %-20s while\n", yylineno, keyword);	
			yylval.op_val = new std::string(yytext);
			return WHILE;
		}
break	{
			printf("Line %d %-20s break\n", yylineno, keyword);	
			yylval.op_val = new std::string(yytext);
			return BREAK;
		}
print	{
			printf("Line %d %-20s print\n", yylineno, keyword);	
			yylval.op_val = new std::string(yytext);
			return PRINT;
		}
read	{
			printf("Line %d %-20s read\n", yylineno, keyword);	
			yylval.op_val = new std::string(yytext);
			return READ;
		}

=                  	{
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return ASSIGN;
					}
!					{
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return NOT;
					}
\+					{
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return '+';
					}
\-					{
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return '-';
					}
\*                  {
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return '*';
					}
\/                  {
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return '/';
					}
\<                  {
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return LT;
					}
\>                  {
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return GT;
					}
==                  {
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return EQ;
					}
!=                  {
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return NEQ;
					}
\<=                 {
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return LE;
					}
\>=                 {
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return GE;
					}
&&					{
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return AND;
					}
"||"				{
						printf("Line %d %-20s %s\n", yylineno, op, yytext);
						yylval.op_val = new std::string(yytext);
						return OR;
					}


id[A-Z][a-z]*		{
						printf("Line %d %-20s %s\n", yylineno, identifier, yytext);
						yylval.op_val = new std::string(yytext);
						return id;
					}	

"["					{
						printf("Line %d %-20s %s\n", yylineno, symbol, yytext);
						yylval.op_val = new std::string(yytext);
						return '[';
					}	
"]"					{
						printf("Line %d %-20s %s\n", yylineno, symbol, yytext);
						yylval.op_val = new std::string(yytext);
						return ']';
					}	
"("					{
						printf("Line %d %-20s %s\n", yylineno, symbol, yytext);
						yylval.op_val = new std::string(yytext);
						return '(';
					}	
")"					{
						printf("Line %d %-20s %s\n", yylineno, symbol, yytext);
						yylval.op_val = new std::string(yytext);
						return ')';
					}	
"{"					{
						printf("Line %d %-20s %s\n", yylineno, symbol, yytext);
						yylval.op_val = new std::string(yytext);
						return '{';
					}	
"}"					{
						printf("Line %d %-20s %s\n", yylineno, symbol, yytext);
						yylval.op_val = new std::string(yytext);
						return '}';
					}	
";"					{
						printf("Line %d %-20s %s\n", yylineno, symbol, yytext);
						yylval.op_val = new std::string(yytext);
						return ';';
					}	
","					{
						printf("Line %d %-20s %s\n", yylineno, symbol, yytext);
						yylval.op_val = new std::string(yytext);
						return ',';
					}	
[1-9][0-9]*|0		{
						printf("Line %d %-20s %s\n", yylineno, number, yytext);
						yylval.op_val = new std::string(yytext);
						return num;
					}	
\".\"				{
						printf("Line %d %-20s %s\n", yylineno, character, yytext);
					}
\/\/[^\n]*			{printf("Line %d %-20s %s\n", yylineno, comment, yytext);}

.					{
						printf("Line %d %-20s %s\n", yylineno, error, yytext);
						yylval.op_val = new std::string(yytext);
						std::cerr << "SCANNER ";
						exit(1);
					}


%%
