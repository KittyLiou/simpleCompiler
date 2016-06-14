%error-verbose

%{
	#include "heading.h"
	int yyerror(const char *s);
	int yylex(void);
%}

%union{
	string *op_val;
}

%start Program

%token <op_val> epsilon id num READ PRINT ';' WHILE IF ELSE BREAK RET CHAR INT 

%type <op_val> Program DeclList DeclList_ Decl VarDecl VarDecl_ FunDecl VarDeclList ParamDeclList ParamDeclListTail ParamDeclListTail_ ParamDecl ParamDecl_ Block Type StmtList StmtList_ Stmt Expr ExprIdTail ExprArrayTail Expr_ ExprList ExprListTail ExprListTail_ UnaryOp BinOp

%left ','
%right ASSIGN
%left AND
%left OR
%left EQ NEQ 
%left GT LT GE LE
%left '+' '-'
%left '*' '/'
%right MINUS NOT 
%left '(' ')' '[' ']' '{' '}'

%%
Program:
	DeclList
	;
DeclList:
	DeclList_ DeclList
	|{ }
	;
DeclList_:
	Type id Decl
	;
Decl:
	VarDecl_
	|FunDecl
	;
VarDecl:
	Type id VarDecl_
	;
VarDecl_:
	';'
	|'[' num ']' ';'
	;
FunDecl:
	'(' ParamDeclList ')' Block
	;
VarDeclList:
	VarDecl VarDeclList
	|{ }
	;
ParamDeclList:
	ParamDeclListTail
	|{ }
	;
ParamDeclListTail:
	ParamDecl ParamDeclListTail_
	;
ParamDeclListTail_:
	',' ParamDeclListTail
	|{ }
	;
ParamDecl:
	Type id ParamDecl_
	;
ParamDecl_:
	'[' ']'
	|{ }
	;
Block:
	'{' VarDeclList StmtList '}'
	;
Type:
	INT
	|CHAR
	;
StmtList:
	Stmt StmtList_
	;
StmtList_:
	StmtList
	|{ }
	;
Stmt:
	';'
	|Expr ';'
	|RET Expr ';'
	|BREAK ';'
	|IF '(' Expr ')' Stmt ELSE Stmt
	|WHILE '(' Expr ')' Stmt
	|Block
	|PRINT id ';' 
	|READ id ';'
	;
Expr:
	UnaryOp Expr
	|num Expr_
	|'(' Expr ')' Expr_
	|id ExprIdTail
	;
ExprIdTail:
	Expr_
	|'(' ExprList ')' Expr_
	|'[' Expr ']' ExprArrayTail
	|ASSIGN Expr
	;
ExprArrayTail:
	Expr_
	|ASSIGN Expr
	;
Expr_:
	BinOp Expr
	|{ }
	;
ExprList:
	ExprListTail
	|{ }
	;
ExprListTail:
	Expr ExprListTail_
	;
ExprListTail_:
	',' ExprListTail
	|{ }
	;
UnaryOp:
	MINUS
	|NOT
	;
BinOp:
	'+'
	|'-'
	|'*'
	|'/'
	|EQ
	|NEQ
	|LT
	|LE
	|GT
	|GE
	|AND
	|OR
	;
%%


int yyerror(const char *s)
{
	extern int yylineno;
	extern char *yytext;

	cerr << "ERROR: " << s << " at symbol \"" << yytext;
	cerr << "\" on line " << yylineno << endl;
	exit(1);
}
