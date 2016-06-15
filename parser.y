%error-verbose

%{
	#include "heading.h"
	#include <map>
	int yyerror(const char *s);
	int cus_error(const char *s, const char *symbol);
	int yylex(void);
	vector<string> instr;
	map<int, string> usedReg;
	vector<string> stack;
	map<string, int>symbol_table;
	int getReg()
	{
		for(int i = 0; i < 10; ++i)
		{
			if(usedReg.find(i) == usedReg.end())
			  return i;
		}
		//if all registers are occupied
		//create stack instruction
		instr.push_back("addi $sp, $sp, -4\n\tsw $t0, 0($sp)\n\t");
		instr.push_back("addi $sp, $sp, -4\n\tsw $t1, 0($sp)\n\t");
		instr.push_back("addi $sp, $sp, -4\n\tsw $t2, 0($sp)\n\t");
		//all old stack pointer plus 1
		for(unsigned int i = 0; i < stack.size(); ++i)
		{
			symbol_table[stack.at(i)] += 3;
		}
		//put the first three element in register into stack
		stack.push_back(usedReg[0]);
		stack.push_back(usedReg[1]);
		stack.push_back(usedReg[2]);
		symbol_table[usedReg[2]] = 10;	
		symbol_table[usedReg[1]] = 11;	
		symbol_table[usedReg[0]] = 12;	
		usedReg.erase(usedReg.find(0));
		usedReg.erase(usedReg.find(1));
		usedReg.erase(usedReg.find(2));
		return 0;
	}

	void releaseReg(int regNum)
	{
		if(usedReg.find(regNum) != usedReg.end())
		  usedReg.erase(usedReg.find(regNum));
	}

%}

%union{
	string *op_val;
	Expr *expr;
}

%start Program

%token <op_val> epsilon id num READ PRINT ';' WHILE IF ELSE BREAK RET CHAR INT 

%type <expr> Program
%type <op_val> DeclList FunDecl VarDeclList ParamDeclList ParamDeclListTail ParamDecl Block Type StmtList Stmt Expr Expr_ ExprList ExprListTail

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
	DeclList	{	
					FILE *fp = fopen("result.asm", "w");
					fprintf(fp, "	.globl main\n	.text\nmain:\n\t");
					for(unsigned int i = 0; i < instr.size(); ++i)
					{
						fprintf(fp,"%s\n\t",instr.at(i).c_str());
					}
					fprintf(fp, "li $v0, 10\n\tsyscall\n");
				}
	;
DeclList:
	Type id ';'DeclList
	|Type id '[' num ']' ';'DeclList
	|Type id FunDecl DeclList
	|{ }
	;
FunDecl:
	'(' ParamDeclList ')' Block
	;
VarDeclList:
	Type id ';' VarDeclList
	|Type id '[' num ']' ';' VarDeclList
	|{ }
	;
ParamDeclList:
	ParamDeclListTail
	|{ }
	;
ParamDeclListTail:
	ParamDecl
	|ParamDecl ',' ParamDeclListTail
	;
ParamDecl:
	Type id
	|Type id '[' ']'
	;
Block:
	'{' VarDeclList StmtList '}'
	;
Type:
	INT
	|CHAR
	;
StmtList:
	Stmt StmtList
	|Stmt
	;
Stmt:
	';'
	|Expr ';'
	|RET Expr ';'
	|BREAK ';'
	|IF '(' Expr ')' Stmt ELSE Stmt
	|WHILE '(' Expr ')' Stmt
	|Block
	|PRINT id ';'	{
						cout << "$2:" << *$2 << endl;
					} 
	|READ id ';'	{
						printf("here read\n");
						string id = *$2;
						if(symbol_table.find(id) == symbol_table.end())	//not declared yet
						  cus_error("undefined symbol", id.c_str());
						instr.push_back("li $v0, 5\n\tsyscall\n\t");
						char tmp_instr[30];
						if(symbol_table[id] >= 10)	//id is in stack
						  sprintf(tmp_instr, "sw $v0, %d($sp)\n\t", symbol_table[id]-10);
						else
						  sprintf(tmp_instr, "move $t%d, $v0\n\t", symbol_table[id]);
						instr.push_back(tmp_instr);
					}
	;
Expr:
	MINUS Expr
	|NOT Expr
	|Expr_
	|Expr_ '+' Expr
	|Expr_ '-' Expr
	|Expr_ '*' Expr
	|Expr_ '/' Expr
	|Expr_ EQ Expr
	|Expr_ NEQ Expr
	|Expr_ LT Expr
	|Expr_ LE Expr
	|Expr_ GT Expr
	|Expr_ GE Expr
	|Expr_ AND Expr
	|Expr_ OR Expr
	|id '[' Expr ']' ASSIGN Expr
	|id ASSIGN Expr
	;
Expr_:
	num
	|'(' Expr ')'
	|id
	|id '(' ExprList ')'
	|id '[' Expr ']'
	;

ExprList:
	ExprListTail
	|{ }
	;
ExprListTail:
	Expr ',' ExprListTail
	|Expr
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

int cus_error(const char *s, const char *symbol)
{
	extern int yylineno;

	cerr << "ERROR: " << s << " at symbol \"" << symbol;
	cerr << "\" on line " << yylineno << endl;
	exit(1);
}
