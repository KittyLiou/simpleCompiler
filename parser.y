%error-verbose

%{
	#include "heading.h"
	#include <map>
	int yyerror(const char *s);
	int yylex(void);
	void no_reg_error(const char *s);
	vector<string> stack;
	map<string, int>symbol_table;
	map<int, string> usedReg;
	int getReg(vector<string> *v);
	int getReg(vector<string> *v, string id);
 	void releaseReg(int num, vector<string> *v);
	void pull_stack(vector<string> *v, string id);
	int framePtr = 11;
	int label = 0;
	int conti = 0;
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
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  fprintf(fp,"%s",(*$1).at(i).c_str());
		fprintf(fp, "\tli $v0, 10\n\tsyscall\n");
		fclose(fp);
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
		//not yet finished
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
		//not yet finished
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
		$$ = new vector<string>();
	}
	|Expr ';'{
		printf("Stmt => Expr;\n");
		int r = atoi((*$1).at((*$1).size()-1).c_str());
		(*$1).pop_back();
		$$ = new vector<string>;
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		 (*$$).push_back((*$1).at(i));
		releaseReg(r, $$);
		delete $1;
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
		$$ = new vector<string>();
		string expr = (*$3).at((*$3).size()-1);
		(*$3).pop_back();
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		int result_reg = atoi(expr.c_str());
		char tmp_instr[30];
		sprintf(tmp_instr, "\tbne $t%d, $0, IfLabel%d\n", result_reg, label);
		(*$$).push_back(tmp_instr);
		for(unsigned int i = 0; i < (*$7).size(); ++i)
		{  (*$$).push_back((*$7).at(i));
			cout << (*$7).at(i) << endl;}
		sprintf(tmp_instr, "\tj Conti%d\n", conti);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "IfLabel%d:\n", label++);
		(*$$).push_back(tmp_instr);
		for(unsigned int i = 0; i < (*$5).size(); ++i)
		  (*$$).push_back((*$5).at(i));
		sprintf(tmp_instr, "Conti%d:\n", conti++);
		(*$$).push_back(tmp_instr);
		releaseReg(result_reg, $$);
		delete $3;
		delete $5;
		delete $7;
	}
	|WHILE '(' Expr ')' Stmt	{
		printf("Stmt => WHILE ( Expr ) Stmt\n");
	}
	|'{' VarDeclList StmtList '}'{
		printf("{Stmt => VarDeclList StmtList}\n");
		$$ = new vector<string>();
		for(unsigned int i = 0; i < (*$2).size(); ++i)
		  (*$$).push_back((*$2).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		delete $2;
		delete $3;
	}
	|PRINT id ';'{
		printf("Stmt => PRINT id:%s;\n", (*$2).c_str());
		$$ =  new vector<string>();
		string id = *$2;
		char tmp_instr[30];
		int reg;
		(*$$).push_back("\tadd $sp, $sp, -4\n");
		(*$$).push_back("\tsw $a0, 0($sp)\n");
		stack.push_back("tmp");
		symbol_table["tmp"] = framePtr++;
		//(*$$).push_back("\tadd $sp, $sp, -4\n\tsw $a0, 0($sp)\n");	//store $a0
		(*$$).push_back("\tli $v0, 1\n");
		if(symbol_table.find(id) != symbol_table.end())
		{
			reg = getReg($$, id);
			if(reg < 0 || reg == 9)
			  no_reg_error("Stmt => PRINT id");
		}
		else
		{
			reg = getReg($$);
			if(reg < 0 || reg == 9)
			  no_reg_error("Stmt => PRINT id");
			symbol_table[id] = reg;
			usedReg[reg] = id;
		}
		sprintf(tmp_instr, "\tmove $a0, $t%d\n", reg);
		(*$$).push_back(tmp_instr);
		(*$$).push_back("\tsyscall\n");
		//restore $a0
		sprintf(tmp_instr, "\tlw $a0, -%d($fp)\n", 4*(symbol_table["tmp"]-10));
		(*$$).push_back(tmp_instr);
		pull_stack($$, "tmp");
//		(*$$).push_back("\tlw $a0, 0($sp)\n");	//restore $a0
		releaseReg(reg, $$);
	} 
	|READ id ';'{
		printf("Stmt => READ id\n");
		$$ =  new vector<string>();
		string id = *$2;
		char tmp_instr[30];
		int reg;
		(*$$).push_back("\tli $v0, 5\n\tsyscall\n");
		if(symbol_table.find(id) != symbol_table.end())
		{
			reg = getReg($$, id);
			if(reg < 0 || reg == 9)
			  no_reg_error("Stmt => READ id");
		}
		else
		{
			reg = getReg($$);
			if(reg == 9)
			  no_reg_error("Stmt => READ id");
			symbol_table[id] = reg;
			usedReg[reg] = id;
		}
		sprintf(tmp_instr, "\tmove $t%d, $v0\n", reg);
		(*$$).push_back(tmp_instr);
		releaseReg(reg, $$);
	}
	;
Expr:
	MINUS Expr{
		printf("Expr => MINUS Expr\n");
		$$ = new vector<string>();
		int r = atoi((*$2).at((*$2).size()-1).c_str());
		for(unsigned int i = 0; i < (*$2).size(); ++i)
		  (*$$).push_back((*$2).at(i));
		char tmp_instr[30];
		sprintf(tmp_instr, "\tsub $t9, $0, $t%d\n", r);
		(*$$).push_back(tmp_instr);
		releaseReg(r, $$);
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", r);
		(*$$).push_back(tmp_instr);
		usedReg[r] = "";	//declared reg r1 is used but not for an id
		sprintf(tmp_instr, "%d", r);
		(*$$).push_back(tmp_instr);
		delete $2;
	}
	|NOT Expr{
        printf("Expr => NOT Expr\n");
		$$ = new vector<string>();
		int r = atoi((*$2).at((*$2).size()-1).c_str());
		(*$2).pop_back();
		for(unsigned int i = 0; i < (*$2).size(); ++i)
		  (*$$).push_back((*$2).at(i));
		char tmp_instr[30];
		(*$$).push_back("\tli $t9, 1\n");	//assume original value is 0
		sprintf(tmp_instr, "\tbeq $t%d, $0, Conti%d\n", r, conti);	//actually 0
		(*$$).push_back(tmp_instr);
		(*$$).push_back("\tli $t9, 0\n");
		sprintf(tmp_instr, "Conti%d:\n", conti++);
		(*$$).push_back(tmp_instr);
		releaseReg(r, $$);
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", r);
		(*$$).push_back(tmp_instr);
		usedReg[r] = "";	//declared reg r1 is used but not for an id
		sprintf(tmp_instr, "%d", r);
		(*$$).push_back(tmp_instr);
		delete $2;
	}
	|Expr_{
		printf("Expr => Expr_\n");
		$$ = $1;
	}
	|Expr '+' Expr_{
		printf("Expr => Expr '+' Expr_\n");
		string expr1 = (*$1).at((*$1).size()-1);
		(*$1).pop_back();
		string expr2 = (*$3).at((*$3).size()-1);
		(*$3).pop_back();
		$$ = new vector<string>();
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		int r1 = atoi(expr1.c_str());
		int r2 = atoi(expr2.c_str());
		char tmp_instr[30];
		sprintf(tmp_instr, "\tadd $t9, $t%d, $t%d\n", r1, r2);
		(*$$).push_back(tmp_instr);
		releaseReg(r1, $$);
		releaseReg(r2, $$);
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", r1);
		usedReg[r1] = "";
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", r1);
		(*$$).push_back(tmp_instr);
		delete $1;
		delete $3;
	}
	|Expr '-' Expr_{
		printf("Expr => Expr '-' Expr_\n");
		string expr1 = (*$1).at((*$1).size()-1);
		(*$1).pop_back();
		string expr2 = (*$3).at((*$3).size()-1);
		(*$3).pop_back();
		$$ = new vector<string>();
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		int r1 = atoi(expr1.c_str());
		int r2 = atoi(expr2.c_str());
		char tmp_instr[30];
		sprintf(tmp_instr, "\tsub $t9, $t%d, $t%d\n", r1, r2);
		(*$$).push_back(tmp_instr);
		releaseReg(r1, $$);
		releaseReg(r2, $$);
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", r1);
		usedReg[r1] = "";
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", r1);
		(*$$).push_back(tmp_instr);
		delete $1;
		delete $3;
	}
	|Expr '*' Expr_{
        printf("Expr => Expr '*' Expr_\n");	
		string expr1 = (*$1).at((*$1).size()-1);
		(*$1).pop_back();
		string expr2 = (*$3).at((*$3).size()-1);
		(*$3).pop_back();
		$$ = new vector<string>();
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		int r1 = atoi(expr1.c_str());
		int r2 = atoi(expr2.c_str());
		char tmp_instr[30];
		sprintf(tmp_instr, "\tmul $t9, $t%d, $t%d\n", r1, r2);
		(*$$).push_back(tmp_instr);
		releaseReg(r1, $$);
		releaseReg(r2, $$);
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", r1);
		usedReg[r1] = "";
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", r1);
		(*$$).push_back(tmp_instr);
		delete $1;
		delete $3;
	}
	|Expr '/' Expr_{
        printf("Expr => Expr '/' Expr_\n");	
		string expr1 = (*$1).at((*$1).size()-1);
		(*$1).pop_back();
		string expr2 = (*$3).at((*$3).size()-1);
		(*$3).pop_back();
		$$ = new vector<string>();
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		int r1 = atoi(expr1.c_str());
		int r2 = atoi(expr2.c_str());
		char tmp_instr[30];
		sprintf(tmp_instr, "\tdiv $t%d, $t%d\n", r1, r2);
		(*$$).push_back(tmp_instr);
		releaseReg(r1, $$);
		releaseReg(r2, $$);
		sprintf(tmp_instr, "\tmflo $t%d\n", r1);
		usedReg[r1] = "";
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", r1);
		(*$$).push_back(tmp_instr);
		delete $1;
		delete $3;
	}
	|Expr EQ Expr_{
        printf("Expr => Expr EQ Expr_\n");	
		$$ = new vector<string>();
		int r1 = atoi((*$1).at((*$1).size()-1).c_str());
		int r2 = atoi((*$3).at((*$3).size()-1).c_str());
		(*$1).pop_back();
		(*$3).pop_back();
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		char tmp_instr[30];
		(*$$).push_back("\tli $t9, 0\n");	//default result is 0 (not equal)
		sprintf(tmp_instr, "\tsub $t9, $t%d, $t%d\n", r1, r2);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "\tbne $t9, $0, Conti%d\n", conti);	//really not equal
		(*$$).push_back(tmp_instr);
		(*$$).push_back("\tnop\n");
		(*$$).push_back("\tli $t9, 1\n");	//actually equal
		sprintf(tmp_instr, "Conti%d:\n", conti++);
		(*$$).push_back(tmp_instr);
		releaseReg(r1, $$);
		releaseReg(r2, $$);
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", r1);
		(*$$).push_back(tmp_instr);
		usedReg[r1] = "";	//declared reg r1 is used but not for an id
		sprintf(tmp_instr, "%d", r1);
		(*$$).push_back(tmp_instr);
		delete $1;
		delete $3;
	}
	|Expr NEQ Expr_{
        printf("Expr => Expr NEQ Expr_\n");	
		$$ = new vector<string>();
		int r1 = atoi((*$1).at((*$1).size()-1).c_str());
		int r2 = atoi((*$3).at((*$3).size()-1).c_str());
		(*$1).pop_back();
		(*$3).pop_back();
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		char tmp_instr[30];
		sprintf(tmp_instr, "\tsub $t9, $t%d, $t%d\n", r1, r2);
		(*$$).push_back(tmp_instr);
		releaseReg(r1, $$);
		releaseReg(r2, $$);
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", r1);
		(*$$).push_back(tmp_instr);
		usedReg[r1] = "";	//declared reg r1 is used but not for an id
		sprintf(tmp_instr, "%d", r1);
		(*$$).push_back(tmp_instr);
		delete $1;
		delete $3;
	}
	|Expr LT Expr_{
        printf("Expr => Expr LT Expr_\n");	
		$$ = new vector<string>();
		int r1 = atoi((*$1).at((*$1).size()-1).c_str());
		int r2 = atoi((*$3).at((*$3).size()-1).c_str());
		(*$1).pop_back();
		(*$3).pop_back();
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		char tmp_instr[30];
		sprintf(tmp_instr, "\tslt $t9, $t%d, $t%d\n", r1, r2);
		(*$$).push_back(tmp_instr);
		releaseReg(r1, $$);
		releaseReg(r2, $$);
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", r1);
		(*$$).push_back(tmp_instr);
		usedReg[r1] = "";	//declared reg r1 is used but not for an id
		sprintf(tmp_instr, "%d", r1);
		(*$$).push_back(tmp_instr);
		delete $1;
		delete $3;
	}
	|Expr LE Expr_{
        printf("Expr => Expr LE Expr_\n");	
		$$ = new vector<string>();
		int r1 = atoi((*$1).at((*$1).size()-1).c_str());
		int r2 = atoi((*$3).at((*$3).size()-1).c_str());
		(*$1).pop_back();
		(*$3).pop_back();
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		char tmp_instr[30];
		sprintf(tmp_instr, "\tsle $t9, $t%d, $t%d\n", r1, r2);
		(*$$).push_back(tmp_instr);
		releaseReg(r1, $$);
		releaseReg(r2, $$);
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", r1);
		(*$$).push_back(tmp_instr);
		usedReg[r1] = "";	//declared reg r1 is used but not for an id
		sprintf(tmp_instr, "%d", r1);
		(*$$).push_back(tmp_instr);
		delete $1;
		delete $3;
	}
	|Expr GT Expr_{
        printf("Expr => Expr GT Expr_\n");	
		$$ = new vector<string>();
		int r1 = atoi((*$1).at((*$1).size()-1).c_str());
		int r2 = atoi((*$3).at((*$3).size()-1).c_str());
		(*$1).pop_back();
		(*$3).pop_back();
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		char tmp_instr[30];
		sprintf(tmp_instr, "\tsgt $t9, $t%d, $t%d\n", r1, r2);
		(*$$).push_back(tmp_instr);
		releaseReg(r1, $$);
		releaseReg(r2, $$);
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", r1);
		(*$$).push_back(tmp_instr);
		usedReg[r1] = "";	//declared reg r1 is used but not for an id
		sprintf(tmp_instr, "%d", r1);
		(*$$).push_back(tmp_instr);
		delete $1;
		delete $3;
	}
	|Expr GE Expr_{
        printf("Expr => Expr GE Expr_\n");	
		$$ = new vector<string>();
		int r1 = atoi((*$1).at((*$1).size()-1).c_str());
		int r2 = atoi((*$3).at((*$3).size()-1).c_str());
		(*$1).pop_back();
		(*$3).pop_back();
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		char tmp_instr[30];
		sprintf(tmp_instr, "\tsge $t9, $t%d, $t%d\n", r1, r2);
		(*$$).push_back(tmp_instr);
		releaseReg(r1, $$);
		releaseReg(r2, $$);
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", r1);
		(*$$).push_back(tmp_instr);
		usedReg[r1] = "";	//declared reg r1 is used but not for an id
		sprintf(tmp_instr, "%d", r1);
		(*$$).push_back(tmp_instr);
		delete $1;
		delete $3;
	}
	|Expr AND Expr{
        printf("Expr => Expr AND Expr\n");	
		$$ = new vector<string>();
		int r1 = atoi((*$1).at((*$1).size()-1).c_str());
		int r2 = atoi((*$3).at((*$3).size()-1).c_str());
		(*$1).pop_back();
		(*$3).pop_back();
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		char tmp_instr[30];
		(*$$).push_back("\tli $t9, 0\n");	//default result is 0
		sprintf(tmp_instr, "\tbeq $t%d, $0, Conti%d\n", r1, conti);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "\tbeq $t%d, $0, Conti%d\n", r2, conti);
		(*$$).push_back(tmp_instr);
		(*$$).push_back("\tli $t9, 1\n");
		sprintf(tmp_instr, "Conti%d:\n", conti++);
		(*$$).push_back(tmp_instr);
		releaseReg(r1, $$);
		releaseReg(r2, $$);
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", r1);
		(*$$).push_back(tmp_instr);
		usedReg[r1] = "";	//declared reg r1 is used but not for an id
		sprintf(tmp_instr, "%d", r1);
		(*$$).push_back(tmp_instr);
		delete $1;
		delete $3;
	}
	|Expr OR Expr{
        printf("Expr => Expr OR Expr\n");
		$$ = new vector<string>();
		int r1 = atoi((*$1).at((*$1).size()-1).c_str());
		int r2 = atoi((*$3).at((*$3).size()-1).c_str());
		(*$1).pop_back();
		(*$3).pop_back();
		for(unsigned int i = 0; i < (*$1).size(); ++i)
		  (*$$).push_back((*$1).at(i));
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		char tmp_instr[30];
		sprintf(tmp_instr, "\tor $t9, $t%d, $t%d\n", r1, r2);
		(*$$).push_back(tmp_instr);
		releaseReg(r1, $$);
		releaseReg(r2, $$);
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", r1);
		(*$$).push_back(tmp_instr);
		usedReg[r1] = "";
		sprintf(tmp_instr, "%d", r1);
		(*$$).push_back(tmp_instr);
		delete $1;
		delete $3;
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
		int expr_reg = atoi(expr.c_str());
		sprintf(tmp_instr, "\tmove $t%d, $t%d\n", reg, expr_reg);
		(*$$).push_back(tmp_instr);
		releaseReg(expr_reg, $$);
		if(reg == 9)
		{
			sprintf(tmp_instr, "\tmove $t%d, $t9\n", expr_reg);
			(*$$).push_back(tmp_instr);
			usedReg[expr_reg] = (*$1);
			symbol_table[(*$1)] = expr_reg;
			//release reg 9
			usedReg.erase(usedReg.find(9));
		}
		sprintf(tmp_instr, "%d", symbol_table[(*$1)]);
		(*$$).push_back(tmp_instr);
		delete $3;
	}
	;
Expr_:
	num	{
		printf("Expr_ => num\n");
		$$ = new vector<string>();
		int reg = getReg($$);
		if(reg == 9)
		  no_reg_error("Expr_ => num");
		usedReg[reg] = "";
		char tmp_instr[30];
		sprintf(tmp_instr, "\tli $t%d, %d\n", reg, atoi((*$1).c_str()));
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
		(*$$).push_back(tmp_instr);	//used to pass the register where the num is stored
	}
	|'(' Expr ')'{
		printf("Expr_ => '(' Expr ')'\n");
		$$ = $2;
	}
	|id	{
		printf("Expr_ => id\tid is now %s\n", (*$1).c_str());
		$$ = new vector<string>();
		char tmp_instr[30];
		if(symbol_table.find(*$1) == symbol_table.end())
		{
			int reg = getReg($$);
			if(reg == 9)
		  	  no_reg_error("Expr_ => num");
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
		$$ = $1;
	}
	|{ }{
		printf("ExprList => { }\n");
		$$ = new vector<string>();
	}
	;
ExprListTail:
	Expr ',' ExprListTail{
		printf("ExprListTail => Expr ',' ExprListTail\n");
	}
	|Expr{
		printf("ExprListTail => Expr\n");
		$$ = $1;
	}
	;
%%


void no_reg_error(const char *s)
{
	printf("ERROR: no free reg available while converting %s\n", s);
	exit(1);
}

int yyerror(const char *s)
{
	extern int yylineno;
	extern char *yytext;

	cerr << "ERROR: " << s << " at symbol \"" << yytext;
	cerr << "\" on line " << yylineno << endl;
	exit(1);
}

void pull_stack(vector<string> *v, string id)
{
	string last = stack.at(stack.size()-1);
	if(id.compare(last) == 0)
	{
		stack.pop_back();
		symbol_table.erase(symbol_table.find(id));
	}
	else
	{
		char tmp_instr[30];
		sprintf(tmp_instr, "\tlw $t9, -%d($fp)\n", 4*(symbol_table[last]-10));
		(*v).push_back(tmp_instr);
		sprintf(tmp_instr, "\tsw $t9, -%d($fp)\n", 4*(symbol_table[id]-10));
		(*v).push_back(tmp_instr);
		(*v).push_back("\tadd $sp, $sp, 4\n");
		symbol_table[last] = symbol_table[id];
		symbol_table.erase(symbol_table.find(id));
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
				sprintf(tmp_instr, "\tlw $t%d, -%d($fp)\n", i, 4*(symbol_table[id]-10));
				(*v).push_back(tmp_instr);
				usedReg[i] = id;
				symbol_table[id] = i;
			}
			else
			{
				sprintf(tmp_instr, "\tlw $t9, -%d($fp)\n", 4*(symbol_table[last]-10));
				(*v).push_back(tmp_instr);
				cout << tmp_instr << endl;
				cout << "symbol_table[" << id << "]: " << symbol_table[id] << endl << "";
				sprintf(tmp_instr, "\tlw $t%d, -%d($fp)\n", i, 4*(symbol_table[id]-10));
				cout << tmp_instr << endl;
				(*v).push_back(tmp_instr);
				sprintf(tmp_instr, "\tsw $t9, -%d($fp)\n", 4*(symbol_table[id]-10));
				cout << tmp_instr << endl;
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
	return 9;	//no reg is now available
}

int getReg(vector<string> *v)
{
	for(int i = 0; i < 9; ++i)	//$t9 is reserved
	{
		if(usedReg.find(i) == usedReg.end())
		{
			usedReg[i] = "";
		  	return i;
		}
	}
	return 9;	//no reg is now available
}

void releaseReg(int num, vector<string> *v)
{
 	if(usedReg.find(num) == usedReg.end())
	  return;
	if(symbol_table.find(usedReg[num]) == symbol_table.end())
	  usedReg.erase(usedReg.find(num));
	else
	{
		//save the data in the current register into stack
		char tmp_instr[30];
		
		(*v).push_back("\tadd $sp, $sp, -4\n");
		sprintf(tmp_instr, "\tsw $t%d, 0($sp)\n", num);
		(*v).push_back(tmp_instr);
		stack.push_back(usedReg[num]);
		//update the symbol table
		symbol_table[usedReg[num]] = framePtr++; 
		cout << usedReg[num] << ":" << symbol_table[usedReg[num]] << endl;
	  	//mark the current reg as available
		usedReg.erase(usedReg.find(num));
	}
}

void create_new_symbol(vector<string> *v, string id)
{
	
}
