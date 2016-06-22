%error-verbose

%{
	#include "heading.h"
	#include <map>
	map<string, int>symbol_table;
	map<int, string> usedReg;
	vector<string> declars;
	int yyerror(const char *s);
	int yylex(void);
	void no_reg_error(const char *s);
	void add_symbol(vector<string> *v, string id);
	int getReg(vector<string> *v, string s);
	void releaseReg(int reg);
	int framePtr = 1;
	int label = 0;
	int while_label = 0;
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
		for(unsigned int i = 0; i < declars.size(); ++i)
		  fprintf(fp,"%s",declars.at(i).c_str());
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
		$$ = new vector<string>();
		if(symbol_table.find(*$2) == symbol_table.end())
			add_symbol($$, *$2);
		for(unsigned int i = 0; i < (*$4).size(); ++i)
		  (*$$).push_back((*$4).at(i));
		delete $4;
	}
	|Type id '[' num ']' ';'DeclList{
		printf("DeclList => Type id [ num ] ; DeclList\n");
		$$ = new vector<string>();
		char tmp_instr[30];
		//if the array is not yet defined, define it
		if(symbol_table.find(*$2) == symbol_table.end())
		{
			sprintf(tmp_instr, "%s:\t.space %d\n", (*$2).c_str(), 4*atoi((*$4).c_str()));
			declars.push_back(tmp_instr);
			symbol_table[(*$2)] = 0;
		}
		for(unsigned int i = 0; i < (*$7).size(); ++i)
			(*$$).push_back((*$7).at(i));
		delete $7;
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
		char tmp_instr[30];
		if(symbol_table.find(*$2) == symbol_table.end())
		{
			sprintf(tmp_instr, "%s:\t.space %d\n", (*$2).c_str(), 4*atoi((*$4).c_str()));
			declars.push_back(tmp_instr);
			symbol_table[(*$2)] = 0;
		}
		for(unsigned int i = 0; i < (*$7).size(); ++i)
			(*$$).push_back((*$7).at(i));
		delete $7;
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
		releaseReg(r);
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
		$$ = new vector<string>();
		char tmp_instr[30];
		sprintf(tmp_instr, "\tj While_break%d\n", while_label);
		(*$$).push_back(tmp_instr);
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
		  (*$$).push_back((*$7).at(i));
		sprintf(tmp_instr, "\tj Conti%d\n", conti);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "IfLabel%d:\n", label++);
		(*$$).push_back(tmp_instr);
		for(unsigned int i = 0; i < (*$5).size(); ++i)
		  (*$$).push_back((*$5).at(i));
		sprintf(tmp_instr, "Conti%d:\n", conti++);
		(*$$).push_back(tmp_instr);
		releaseReg(result_reg);
		delete $3;
		delete $5;
		delete $7;
	}
	|WHILE '(' Expr ')' Stmt	{
		printf("Stmt => WHILE ( Expr ) Stmt\n");
		$$ = new vector<string>();
		string expr = (*$3).at((*$3).size()-1);
		(*$3).pop_back();
		int result_reg = atoi(expr.c_str());
		char tmp_instr[30];
		sprintf(tmp_instr, "While%d:\n", while_label);
		(*$$).push_back(tmp_instr);
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		sprintf(tmp_instr, "\tbeq $t%d, $0, While_break%d\n", result_reg, while_label);
		(*$$).push_back(tmp_instr);
		for(unsigned int i = 0; i < (*$5).size(); ++i)
		  (*$$).push_back((*$5).at(i));
		sprintf(tmp_instr, "\tj While%d\n", while_label);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "While_break%d:\n", while_label++);
		(*$$).push_back(tmp_instr);
		releaseReg(result_reg);
		delete $3;
		delete $5;
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
		if(symbol_table.find(id) == symbol_table.end())
			add_symbol($$, id);
		int reg = getReg($$, id);
		(*$$).push_back("\tli $v0, 1\n");
		//store $a0
		(*$$).push_back("\tadd $sp, $sp, -4\n");
		(*$$).push_back("\tsw $a0, 0($sp)\n");
		sprintf(tmp_instr, "\tmove $a0, $t%d\n", reg);
		(*$$).push_back(tmp_instr);
		(*$$).push_back("\tsyscall\n");
		//restore $a0
		(*$$).push_back("\tlw $a0, 0($sp)\n\tadd $sp, $sp, 4\n");
		releaseReg(reg);
	} 
	|READ id ';'{
		printf("Stmt => READ id\n");
		$$ =  new vector<string>();
		string id = *$2;
		char tmp_instr[30];
		if(symbol_table.find(id) == symbol_table.end())
			add_symbol($$, id);
		int reg = getReg($$, id);
		if(reg == 9)
			no_reg_error("Stmt => READ id");
		(*$$).push_back("\tli $v0, 5\n\tsyscall\n");
		sprintf(tmp_instr, "\tsw $v0, -%d($fp)\n", 4*symbol_table[id]);
		(*$$).push_back(tmp_instr);
		releaseReg(reg);
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
		releaseReg(r);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
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
		releaseReg(r);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
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
		releaseReg(r1);
		releaseReg(r2);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
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
		releaseReg(r1);
		releaseReg(r2);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
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
		releaseReg(r1);
		releaseReg(r2);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
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
		releaseReg(r1);
		releaseReg(r2);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmflo $t%d\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
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
		releaseReg(r1);
		releaseReg(r2);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
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
		releaseReg(r1);
		releaseReg(r2);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
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
		releaseReg(r1);
		releaseReg(r2);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
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
		releaseReg(r1);
		releaseReg(r2);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
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
		releaseReg(r1);
		releaseReg(r2);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
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
		releaseReg(r1);
		releaseReg(r2);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
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
		releaseReg(r1);
		releaseReg(r2);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
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
		releaseReg(r1);
		releaseReg(r2);
		int reg = getReg($$, "");
		sprintf(tmp_instr, "\tmove $t%d, $t9\n", reg);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg);
		(*$$).push_back(tmp_instr);
		delete $1;
		delete $3;
	}
	|id '[' Expr ']' ASSIGN Expr{
        printf("Expr => id '[' Expr ']' ASSIGN Expr\n");	
		string expr = (*$3).at((*$3).size()-1);
		(*$3).pop_back();
		string expr_to_assign = (*$6).at((*$6).size()-1);
		(*$6).pop_back();
		$$ = new vector<string>();
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		for(unsigned int i = 0; i < (*$6).size(); ++i)
		  (*$$).push_back((*$6).at(i));
		char tmp_instr[30];
		int expr_reg = atoi(expr.c_str());
		int reg_to_assign = atoi(expr_to_assign.c_str());
		int addr = getReg($$, "");
		sprintf(tmp_instr, "\tla $t%d, %s\n", addr, (*$1).c_str());
		(*$$).push_back(tmp_instr);
		//four times of the index
		sprintf(tmp_instr, "\tadd $t%d, $t%d, $t%d\n", expr_reg, expr_reg, expr_reg);
		(*$$).push_back(tmp_instr);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "\tadd $t%d, $t%d, $t%d\n", addr, expr_reg, addr);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "\tsw $t%d, 0($t%d)\n", reg_to_assign, addr);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", reg_to_assign);
		(*$$).push_back(tmp_instr);
		releaseReg(addr);
		releaseReg(expr_reg);
		delete $3;
		delete $6;
	}
	|id ASSIGN Expr{
		printf("Expr => id ASSIGN Expr\n");
		string expr = (*$3).at((*$3).size()-1);
		(*$3).pop_back();
		$$ = new vector<string>();
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		char tmp_instr[30];
		int expr_reg = atoi(expr.c_str());
		if(symbol_table.find(*$1) == symbol_table.end())
			add_symbol($$, *$1);
		sprintf(tmp_instr, "\tsw $t%d, -%d($fp)\n", expr_reg, 4*symbol_table[(*$1)]);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", expr_reg);
		(*$$).push_back(tmp_instr);
		delete $3;
	}
	;
Expr_:
	num	{
		printf("Expr_ => num\n");
		$$ = new vector<string>();
		int reg = getReg($$, "");
		if(reg == 9)
		  no_reg_error("Expr_ => num");
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
		if(symbol_table.find(*$1) == symbol_table.end())
			add_symbol($$, (*$1));
		int reg = getReg($$, *$1);
		if(reg == 9)
			no_reg_error("Expr_ => id");
		char tmp_instr[30];
		sprintf(tmp_instr, "%d", reg);
		(*$$).push_back(tmp_instr);
	}
	|id '(' ExprList ')'{
		printf("Expr_ => id '(' ExprList ')'\n");
		
	}
	|id '[' Expr ']'{
		printf("Expr_ => id '[' Expr ']'\n");
		string expr = (*$3).at((*$3).size()-1);
		(*$3).pop_back();
		int expr_reg = atoi(expr.c_str());
		$$ = new vector<string>();
		for(unsigned int i = 0; i < (*$3).size(); ++i)
		  (*$$).push_back((*$3).at(i));
		char tmp_instr[30];
		int addr = getReg($$, "");
		sprintf(tmp_instr, "\tla $t%d, %s\n", addr, (*$1).c_str());
		(*$$).push_back(tmp_instr);
		//four times of the index
		sprintf(tmp_instr, "\tadd $t%d, $t%d, $t%d\n", expr_reg, expr_reg, expr_reg);
		(*$$).push_back(tmp_instr);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "\tadd $t%d, $t%d, $t%d\n", addr, expr_reg, addr);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "\tlw $t%d, 0($t%d)\n", expr_reg, addr);
		(*$$).push_back(tmp_instr);
		sprintf(tmp_instr, "%d", expr_reg);
		(*$$).push_back(tmp_instr);
		releaseReg(addr);
		delete $3;
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

void add_symbol(vector<string> *v, string id)
{
	if(symbol_table.find(id) != symbol_table.end())
	  return;
	char tmp_instr[30];
	sprintf(tmp_instr, "\tadd $sp, $sp, -4\n");	//allocate memory for the new symbol
	(*v).push_back(tmp_instr);
	symbol_table[id] = framePtr++;
}

int getReg(vector<string> *v, string s)
{
	for(int i = 0; i < 9; ++i)	//$t9 is reserved
	{
		if(usedReg.find(i) == usedReg.end())
		{
			usedReg[i] = s;
			if(symbol_table.find(s) == symbol_table.end())
		  		return i;
			char tmp_instr[30];
			sprintf(tmp_instr, "\tlw $t%d, -%d($fp)\n", i, 4*symbol_table[s]);	//allocate memory for the new symbol
			(*v).push_back(tmp_instr);
		  	return i;
		}
	}
	return 9;	//no reg is now available
}

void releaseReg(int reg)
{
 	if(usedReg.find(reg) == usedReg.end())
		return;
	usedReg.erase(usedReg.find(reg));
}
