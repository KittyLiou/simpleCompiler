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
	int getReg(vector<string> *v, string id);
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
		printf("Program => DeclList\n");
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
		printf("DeclList => Type id ; DeclList\n");
		$$ = $4;
	}
	|Type id '[' num ']' ';'DeclList{
		printf("DeclList => Type id [ num ] ; DeclList\n");
	}
	|Type id FunDecl DeclList{
		printf("DeclList => Type id FunDecl DeclList\n");
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
	|{ }{
		printf("DeclList => { }\n");
		$$ = new vector<string>();
	}
	;
FunDecl:
	'(' ParamDeclList ')' '{' VarDeclList StmtList '}' {
		printf("FunDecl => (ParamDeclList) { VarDeclList StmtList}\n");
		$$ = new vector<string>();
		for(unsigned int i = 0; i < (*$5).size(); ++i)
		  (*$$).push_back((*$5).at(i));
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
		printf("VarDeclList => Type id ';' VarDeclList\n");
		$$ = $4;
	}
	|Type id '[' num ']' ';' VarDeclList {
		printf("VarDeclList => Type id '[' num ']' ';' VarDeclList\n");
		$$ = new vector<string>();
		delete $4;
	}
	|{ }{
		printf("VarDeclList: => { }\n");
		$$ = new vector<string>();
	}
	;
ParamDeclList:
	ParamDeclListTail{
		printf("ParamDeclList => ParamDeclListTail\n");
		$$ = $1;
	}
	|{ }{
		printf("ParamDeclList => { }\n");
		$$ = new vector<string>();
	}
	;
ParamDeclListTail:
	ParamDecl{
		printf("ParamDeclListTail => ParamDecl\n");
		$$ = $1;
	}
	|ParamDecl ',' ParamDeclListTail{
		printf("ParamDeclListTail => ParamDecl ',' ParamDeclListTail\n");
	}
	;
ParamDecl:
	Type id{
		printf("ParamDecl => Type id\n");
	}
	|Type id '[' ']'{
		printf("ParamDecl => Type id []\n");
	}
	;
Type:
	INT {printf("Type => INT\n");}
	|CHAR {printf("Type => CHAR\n");}
	;
StmtList:
	Stmt StmtList{
		printf("StmtList => Stmt StmtList\n");
		$$ = new vector<string>;
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		 (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$2).size(); ++i)
		  (*$$).push_back((*$2).at(i));
		delete $1;
		delete $2;
	}
	|Stmt{
		printf("StmtList => Stmt\n");
		$$ = $1;
	}
	;
Stmt:
	';'	{
		printf("Stmt => ;\n");
	}
	|Expr ';'{
		printf("Stmt => Expr;\n");
		(*$1).pop_back();
		$$ = $1;
	}
	|RET Expr ';'{
		printf("Stmt => RET Expr;\n");
		$$ = new vector<string>();
		delete $2;
		//not yet finished
	}
	|BREAK ';'{
		printf("Stmt => BREAK;\n");
	}
	|IF '(' Expr ')' Stmt ELSE Stmt	{
		printf("Stmt => IF ( Expr ) Stmt ELSE Stmt\n");
	}
	|WHILE '(' Expr ')' Stmt	{
		printf("Stmt => WHILE ( Expr ) Stmt\n");
	}
	|'{' VarDeclList StmtList '}'{
		printf("{Stmt => VarDeclList StmtList}\n");
	}
	|PRINT id ';'{
		printf("Stmt => PRINT id;\n");
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
		printf("Stmt => READ id\n");
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
	MINUS Expr{
		printf("Expr => MINUS Expr\n");
	}
	|NOT Expr{
        printf("Expr => NOT Expr\n");
	}
	|Expr_{
		printf("Expr => Expr_\n");
		$$ = $1;
	}
	|Expr_ '+' Expr{
		printf("Expr => Expr_ '+' Expr\n");
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
		int reg = getReg($$);
		usedReg[reg] = "";
		int r1 = atoi(expr1.c_str());
		int r2 = atoi(expr2.c_str());
		sprintf(tmp_instr, "\tadd $t%d, $t%d, $t%d\n", reg, r1, r2);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
		(*$$).push_back(tmp_instr);
		if(symbol_table.find(usedReg[r1]) == symbol_table.end())
		  releaseReg(r1);
		if(symbol_table.find(usedReg[r2]) == symbol_table.end())
		  releaseReg(r2);
		delete $1;
		delete $3;
	}
	|Expr_ '-' Expr{
		printf("Expr => Expr_ '-' Expr\n");
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
		int reg = getReg($$);
		usedReg[reg] = "";
		int r1 = atoi(expr1.c_str());
		int r2 = atoi(expr2.c_str());
		sprintf(tmp_instr, "\tsub $t%d, $t%d, $t%d\n", reg, r1, r2);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
		(*$$).push_back(tmp_instr);
		if(symbol_table.find(usedReg[r1]) == symbol_table.end())
		  releaseReg(r1);
		if(symbol_table.find(usedReg[r2]) == symbol_table.end())
		  releaseReg(r2);
		delete $1;
		delete $3;
	}
	|Expr_ '*' Expr{
        printf("Expr => Expr_ '*' Expr\n");	
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
		int reg = getReg($$);
		usedReg[reg] = "";
		int r1 = atoi(expr1.c_str());
		int r2 = atoi(expr2.c_str());
		sprintf(tmp_instr, "\tmul $t%d, $t%d, $t%d\n", reg, r1, r2);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
		(*$$).push_back(tmp_instr);
		if(symbol_table.find(usedReg[r1]) == symbol_table.end())
		  releaseReg(r1);
		if(symbol_table.find(usedReg[r2]) == symbol_table.end())
		  releaseReg(r2);
		delete $1;
		delete $3;
	}
	|Expr_ '/' Expr{
        printf("Expr => Expr_ '/' Expr\n");	
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
		int reg = getReg($$);
		usedReg[reg] = "";
		int r1 = atoi(expr1.c_str());
		int r2 = atoi(expr2.c_str());
		sprintf(tmp_instr, "\tdiv $t%d, $t%d\n", r1, r2);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "\tmflo $t%d\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
		(*$$).push_back(tmp_instr);
		if(symbol_table.find(usedReg[r1]) == symbol_table.end())
		  releaseReg(r1);
		if(symbol_table.find(usedReg[r2]) == symbol_table.end())
		  releaseReg(r2);
		delete $1;
		delete $3;
	}
	|Expr_ EQ Expr{
        printf("Expr => Expr_ EQ Expr\n");	
	}
	|Expr_ NEQ Expr{
        printf("Expr => Expr_ NEQ Expr\n");	
	}
	|Expr_ LT Expr{
        printf("Expr => Expr_ LT Expr\n");	
	}
	|Expr_ LE Expr{
        printf("Expr => Expr_ LE Expr\n");	
	}
	|Expr_ GT Expr{
        printf("Expr => Expr_ GT Expr\n");	
	}
	|Expr_ GE Expr{
        printf("Expr => Expr_ GE Expr\n");	
	}
	|Expr_ AND Expr{
        printf("Expr => Expr_ AND Expr\n");	
	}
	|Expr_ OR Expr{
        printf("Expr => Expr_ OR Expr\n");	
	}
	|id '[' Expr ']' ASSIGN Expr{
        printf("Expr => id '[' Expr ']' ASSIGN Expr\n");	
	}
	|id ASSIGN Expr{
		printf("Expr => id ASSIGN Expr\n");
		string expr = (*$3).at((*$3).size()-1);
		(*$3).pop_back();
		$$ = new vector<string>();
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		char tmp_instr[30];
		int reg;
		if(symbol_table.find(*$1) != symbol_table.end())
			reg = getReg($$, *$1);
		else
		{
			reg = getReg($$);
			symbol_table[(*$1)] = reg;
			usedReg[reg] = *$1;
		}
		int expr_loc = atoi(expr.c_str());
		if(expr_loc > 10)	//value of expr is in the memory
		{
			sprintf(tmp_instr, "\tlw $t%d, %d($fp)\n", reg, (expr_loc-10)*4);
		}
		else //value of expr is in the registers
		{
			sprintf(tmp_instr, "\tmove $t%d, $t%d\n", reg, expr_loc);
			releaseReg(expr_loc);
		}
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
		(*$$).push_back(tmp_instr);
		delete $3;
	}
	;
Expr_:
	num	{
		printf("Expr_ => num\n");
		$$ = new vector<string>();
		int reg = getReg($$);
		usedReg[reg] = "";
		char tmp_instr[30];
		sprintf(tmp_instr, "\tli $t%d, %d\n", reg, atoi((*$1).c_str()));
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
		(*$$).push_back(tmp_instr);	//used to pass the register where the num is stored
	}
	|'(' Expr ')'{
		printf("Expr_ => '(' Expr ')'\n");
	}
	|id	{
		printf("Expr_ => id\n");
		$$ = new vector<string>();
		char tmp_instr[30];
		if(symbol_table.find(*$1) == symbol_table.end())
		{
			int reg = getReg($$);
			symbol_table[(*$1)] = reg;
			usedReg[reg] = (*$1);
		}
		else
		  getReg($$, *($1));
		sprintf(tmp_instr, "%d", symbol_table[(*$1)]);
		(*$$).push_back(tmp_instr);	
	}
	|id '(' ExprList ')'{
		printf("Expr_ => id '(' ExprList ')'\n");
	}
	|id '[' Expr ']'{
		printf("Expr_ => id '[' Expr ']'\n");
	}
	;

ExprList:
	ExprListTail{
		printf("ExprList => ExprListTail\n");
	}
	|{ }{
		printf("ExprList => { }\n");
	}
	;
ExprListTail:
	Expr ',' ExprListTail{
		printf("ExprListTail => Expr ',' ExprListTail\n");
	}
	|Expr{
		printf("ExprListTail => Expr\n");
	}
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

int getReg(vector<string> *v, string id)
{
	if(symbol_table.find(id) == symbol_table.end())
	  return -1;
	if(symbol_table[id] < 10)
	  return symbol_table[id];
	//id is in the stack
	char tmp_instr[30];
	for(int i = 0; i < 9; ++i)
	{
		//there is an empty register
		if(usedReg.find(i) == usedReg.end())
		{
			string last = stack.at(stack.size()-1);
			if(id.compare(last) == 0)
			{
				stack.pop_back();
				sprintf(tmp_instr, "\tlw $t%d, %d($fp)\n", i, 4*(symbol_table[id]-10));
				(*v).push_back(tmp_instr);
				(*v).push_back("\tadd $sp, $sp, 4\n");
				usedReg[i] = id;
				symbol_table[id] = i;
			}
			else
			{
				sprintf(tmp_instr, "\tlw $t9, %d($fp)\n", 4*(symbol_table[last]-10));
				(*v).push_back(tmp_instr);
				sprintf(tmp_instr, "\tlw $t%d, %d($fp)\n", i, 4*(symbol_table[id]-10));
				(*v).push_back(tmp_instr);
				sprintf(tmp_instr, "\tsw $t9, %d($fp)\n", 4*(symbol_table[id]-10));
				(*v).push_back(tmp_instr);
				(*v).push_back("\tadd $sp, $sp, 4\n");
				usedReg[i] = id;
				symbol_table[last] = symbol_table[id];
				symbol_table[id] = i;
				for(unsigned int i = 0; i < stack.size(); ++i)
				{
					if(stack.at(i).compare(id) == 0)
					{
						stack[i] = last;
						stack.pop_back();
						break;
					}
				}
			}
			framePtr--;
			return i;
		}
	}
	(*v).push_back("\tmove $t9, $t0\n");
	sprintf(tmp_instr, "\tlw $t0, %d($fp)\n", 4*(symbol_table[id]-10));
	(*v).push_back(tmp_instr);
	sprintf(tmp_instr, "\tsw $t9, %d($fp)\n", 4*(symbol_table[id]-10));
	(*v).push_back(tmp_instr);
	(*v).push_back("\tadd $sp, $sp, 4\n");
	for(unsigned int i = 0; i < stack.size(); ++i)
	{
		if(stack.at(i).compare(id) == 0)
		{
			stack[i] = usedReg[0];
			break;
		}
	}
	symbol_table[usedReg[0]] = symbol_table[id];
	symbol_table[id] = 0;
	usedReg[0] = id;
	return 0;
}

int getReg(vector<string> *v)
{
	for(int i = 0; i < 9; ++i)	//$t9 is reserved
	{
		if(usedReg.find(i) == usedReg.end())
		  return i;
	}
	(*v).push_back("\tadd $sp, $sp, -4\n\tsw $t0, 0($sp)\n");
	symbol_table[usedReg[0]] = framePtr++;
	stack.push_back(usedReg[0]);
	usedReg.erase(usedReg.find(0));
	return 0;
}
 void releaseReg(int num)
 {
 	if(usedReg.find(num) != usedReg.end())
	  usedReg.erase(usedReg.find(num));
 }
