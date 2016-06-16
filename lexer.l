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
			yylval.op_val = new std::string(yytext);
			return INT;
		}
char	{
			yylval.op_val = new std::string(yytext);
			return CHAR;
		}
return	{
			yylval.op_val = new std::string(yytext);
			return RET;
		}
if		{
			yylval.op_val = new std::string(yytext);
			return IF;
		}
else	{
			yylval.op_val = new std::string(yytext);
			return ELSE;
		}
while	{
			yylval.op_val = new std::string(yytext);
			return WHILE;
		}
break	{
			yylval.op_val = new std::string(yytext);
			return BREAK;
		}
print	{
			yylval.op_val = new std::string(yytext);
			return PRINT;
		}
read	{
			yylval.op_val = new std::string(yytext);
			return READ;
		}

=                  	{
						yylval.op_val = new std::string(yytext);
						return ASSIGN;
					}
!					{
						yylval.op_val = new std::string(yytext);
						return NOT;
					}
\+					{
						yylval.op_val = new std::string(yytext);
						return '+';
					}
\-					{
						yylval.op_val = new std::string(yytext);
						return '-';
					}
\*                  {
						yylval.op_val = new std::string(yytext);
						return '*';
					}
\/                  {
						yylval.op_val = new std::string(yytext);
						return '/';
					}
\<                  {
						yylval.op_val = new std::string(yytext);
						return LT;
					}
\>                  {
						yylval.op_val = new std::string(yytext);
						return GT;
					}
==                  {
						yylval.op_val = new std::string(yytext);
						return EQ;
					}
!=                  {
						yylval.op_val = new std::string(yytext);
						return NEQ;
					}
\<=                 {
						yylval.op_val = new std::string(yytext);
						return LE;
					}
\>=                 {
						yylval.op_val = new std::string(yytext);
						return GE;
					}
&&					{
						yylval.op_val = new std::string(yytext);
						return AND;
					}
"||"				{
						yylval.op_val = new std::string(yytext);
						return OR;
					}


id[A-Z][a-z]*		{
						yylval.op_val = new std::string(yytext);
						return id;
					}	

"["					{
						yylval.op_val = new std::string(yytext);
						return '[';
					}	
"]"					{
						yylval.op_val = new std::string(yytext);
						return ']';
					}	
"("					{
						yylval.op_val = new std::string(yytext);
						return '(';
					}	
")"					{
						yylval.op_val = new std::string(yytext);
						return ')';
					}	
"{"					{
						yylval.op_val = new std::string(yytext);
						return '{';
					}	
"}"					{
						yylval.op_val = new std::string(yytext);
						return '}';
					}	
";"					{
						yylval.op_val = new std::string(yytext);
						return ';';
					}	
","					{
						yylval.op_val = new std::string(yytext);
						return ',';
					}	
[1-9][0-9]*|0		{
						yylval.op_val = new std::string(yytext);
						return num;
					}	
\".\"				{
					}
\/\/[^\n]*			{}

.					{
						printf("Line %d %-20s %s\n", yylineno, error, yytext);
						yylval.op_val = new std::string(yytext);
						std::cerr << "SCANNER ";
						exit(1);
					}


%%
