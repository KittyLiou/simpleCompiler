%error-verbose

%{
	#include "heading.h"
	#include <map>
	int yyerror(const char *s);
	int yylex(void);
	vector<string> stack;
	map<string, int>symbol_table;
	map<int, string> usedReg;
	int getReg(vector<string> *v);
 	void releaseReg(int num);
	int framePtr = 11;
%}

%union{
	int NUM;
	string *op_val;
	Stat *stat;
}

%start Program

%token <op_val> epsilon id num READ PRINT ';' WHILE IF ELSE BREAK RET CHAR INT
%type <stat> Program DeclList FunDecl VarDeclList ParamDeclList ParamDeclListTail ParamDecl Type StmtList Stmt Expr Expr_ ExprList ExprListTail

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
					fprintf(fp, "	.globl main\n	.text\nmain:\n");
					fprintf(fp, "\tadd $sp, $sp, -4\n\tsw $fp, 0($sp)\n");	//store the fp
					fprintf(fp, "\tmove $fp, $sp\n");	//move fp to sp
					printf("size:%d\n", (*$1).size());
					for(unsigned int i = 0; i < (*$1).size(); ++i)
					{
						fprintf(fp,"%s",(*$1).at(i).c_str());
					}
					fprintf(fp, "\tli $v0, 10\n\tsyscall\n");
				}
	;
DeclList:
	Type id ';'DeclList	{
							//printf("Type id ; DeclList\n");
							$$ = $4;
						}
	|Type id '[' num ']' ';'DeclList	{
											printf("Type id [ num ] ;\n");
										}
	|Type id FunDecl DeclList	{
									printf("Type id FunDecl DeclList\n");
									$$ = new vector<string>();
									for(unsigned int i = 0; i < (*$4).size(); ++i)
									  (*$$).push_back((*$4).at(i));
									char tmp_instr[30];
									sprintf(tmp_instr, "\n%s:\n", (*$2).c_str());
									(*$$).push_back(tmp_instr);
									for(unsigned int i = 0; i < (*$3).size(); ++i)
									  (*$$).push_back((*$3).at(i));
									delete $3;
									delete $4;
								}
	|{ }	{
				printf("DeclLisst:{ }\n");
				$$ = new vector<string>();
			}
	;
FunDecl:
	'(' ParamDeclList ')' '{' VarDeclList StmtList '}' {
		printf("(ParamDeclList) { VarDeclList StmtList}\n");
		$$ = new vector<string>();
		for(unsigned int i = 0; i < (*$6).size(); ++i)
		  (*$$).push_back((*$6).at(i));
		delete $2;
		delete $5;
		delete $6;
		//ParamDeclList is not yet handled

	}
	;
VarDeclList:
	Type id ';' VarDeclList {
		printf("Type id ';' VarDeclList\n");
		$$ = new vector<string>();
		delete $4;
	}
	|Type id '[' num ']' ';' VarDeclList {
		printf("Type id '[' num ']' ';' VarDeclList\n");
		$$ = new vector<string>();
		delete $4;
	}
	|{ }{
		printf("VarDeclList:{ }\n");
		$$ = new vector<string>();
	}
	;
ParamDeclList:
	ParamDeclListTail 
	|{ }{
		$$ = new vector<string>();
	}
	;
ParamDeclListTail:
	ParamDecl
	|ParamDecl ',' ParamDeclListTail
	;
ParamDecl:
	Type id
	|Type id '[' ']'
	;
Type:
	INT {printf("INT\n");}
	|CHAR {printf("CHAR\n");}
	;
StmtList:
	Stmt StmtList{
		printf("Stmt StmtList\n");
		$$ = new vector<string>;
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		 (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$2).size(); ++i)
		  (*$$).push_back((*$2).at(i));
		delete $1;
		delete $2;
	}
	|Stmt	{
				printf("Stmt\n");
				$$ = $1;
			}
	;
Stmt:
	';'	{printf(";\n");}
	|Expr ';'	{printf("Expr;\n");}
	|RET Expr ';'{
		//printf("RET Expr;\n");
		$$ = new vector<string>();
		delete $2;
	}
	|BREAK ';'{
		printf("BREAK\n");
	}
	|IF '(' Expr ')' Stmt ELSE Stmt	{printf("IF ( Expr ) Stmt ELSE Stmt\n");}
	|WHILE '(' Expr ')' Stmt	{printf("WHILE ( Expr ) Stmt\n");}
	|'{' VarDeclList StmtList '}'	{printf("{VarDeclList StmtList}\n");}
	|PRINT id ';'{
		printf("PRINT id;\n");
		$$ =  new vector<string>();
		string id = *$2;
		char tmp_instr[30];
		(*$$).push_back("\tadd $sp, $sp, -4\n\tsw $a0, 0($sp)\n");	//store $a0
		(*$$).push_back("\tli $v0, 1\n");
		if(symbol_table.find(id) != symbol_table.end())
		{
			if(symbol_table[id] > 10)	//id is in stack
			  sprintf(tmp_instr, "\tlw $a0, %d($fp)\n", (symbol_table[id]-10)*4);
			else
			  sprintf(tmp_instr, "\tmove $a0, $t%d\n", symbol_table[id]);			
		}
		else
		{
			int reg = getReg($$);
			symbol_table[id] = reg;
			usedReg[reg] = id;
		  	sprintf(tmp_instr, "\tmove $a0, $t%d\n", reg);
		}
		(*$$).push_back(tmp_instr);
		(*$$).push_back("\tsyscall\n");
		(*$$).push_back("\tlw $a0, 0($sp)\n\tadd $sp, $sp, 4\n");	//restore $a0
	} 
	|READ id ';'{
		printf("READ id\n");
		$$ =  new vector<string>();
		string id = *$2;
		char tmp_instr[30];
		(*$$).push_back("\tli $v0, 5\n\tsyscall\n");
		if(symbol_table.find(id) != symbol_table.end())
		{
			if(symbol_table[id] > 10)	//id is in stack
			  sprintf(tmp_instr, "\tsw $v0, %d($fp)\n", (symbol_table[id]-10)*4);
			else
			  sprintf(tmp_instr, "\tmove $t%d, $v0\n", symbol_table[id]);			
		}
		else
		{
			int reg = getReg($$);
			symbol_table[id] = reg;
			usedReg[reg] = id;
			sprintf(tmp_instr, "\tmove $t%d, $v0\n", reg);			
		}
		(*$$).push_back(tmp_instr);
	}
	;
Expr:
	MINUS Expr		
	|NOT Expr
	|Expr_{
		//printf("Expr_\n");
		$$ = $1;
	}
	|Expr_ '+' Expr{
		printf("Expr_ '+' Expr\n");
		string expr1 = (*$1).at((*$1).size()-1);
		(*$1).pop_back();
		string expr2 = (*$3).at((*$3).size()-1);
		(*$3).pop_back();
		$$ = new vector<string>();
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		char tmp_instr[30];
		sprintf(tmp_instr, "\tadd $t%s, $t%s, $t%s\n", expr1.c_str(), expr1.c_str(), expr2.c_str());
		(*$$).push_back(expr1.c_str());
		releaseReg(atoi(expr1.c_str()));
		delete $1;
		delete $3;
	}
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
	|id ASSIGN Expr{
		printf("id ASSIGN Expr\n");
	}
	;
Expr_:
	num	{
		$$ = new vector<string>();
		int reg = getReg($$);
		char tmp_instr[30];
		sprintf(tmp_instr, "\tli $t%d, %d\n", reg, atoi((*$1).c_str()));
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
		(*$$).push_back(tmp_instr);	//used to pass the register where the num is stored
	}
	|'(' Expr ')'
	|id	{
		printf("id\n");
		$$ = new vector<string>();
		char tmp_instr[30];
		if(symbol_table.find(*$1) == symbol_table.end())
		{
			int reg = getReg($$);
			symbol_table[(*$1)] = reg;
			usedReg[reg] = (*$1);
		}
		sprintf(tmp_instr, "%d", symbol_table[(*$1)]);
		(*$$).push_back(tmp_instr);	
	}
	|id '(' ExprList ')'
	|id '[' Expr ']'
	;

ExprList:
	ExprListTail	{printf("ExprListTail\n");}
	|{ }			{printf("ExprList:{ }\n");}
	;
ExprListTail:
	Expr ',' ExprListTail	{printf("Expr ',' ExprListTail\n");}
	|Expr		{printf("Expr\n");}
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

int getReg(vector<string> *v)
{
	for(int i = 0; i < 10; ++i)
	{
		if(usedReg.find(i) == usedReg.end())
		  return i;
	}
	(*v).push_back("\tadd $sp, $sp, -4\n\tsw $t0, 0($sp)\n");
	symbol_table[usedReg[0]] = framePtr++;
	usedReg.erase(usedReg.find(0));
	return 0;
}
 void releaseReg(int num)
 {
 	if(usedReg.find(num) != usedReg.end())
	  usedReg.erase(usedReg.find(num));
 }
