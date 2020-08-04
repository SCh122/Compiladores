%{
	#include "y.tab.h"
	#include <stdlib.h>
	#include <stdio.h>
%}

lineComm \/\/.*\n
white [ \t\r\f\n]+
integer [0-9]+
floating [0-9]+\.[0-9]+
real [+-][0-9]+\.[0-9]+
identifier [a-zA-Z]+[0-9]*
blockComm \/\*(.*[\n\t\r\f]*)*\*\/

%%


{lineComm}  {}
{blockComm} {}
{white} 	{}

"int"		{yylval.ival = INT; return INT;};
"float"		{yylval.ival = FLOAT; return FLOAT;};
"bool"		{yylval.ival = BOOL; return BOOL;}
"void"		{yylval.ival = VOID; return VOID;}
"("		return PI;
")"		return PD;
"{"		return LLI;
"}"		return LLD;
","		return COMA;
";"		return PYC;
"while"		return WHILE;
"if"		return IF;
"else"		return ELSE;
"true"		return BOOLTRUE;
"false"		return BOOLFALSE;
"print"		return IMPRINUM;
"=="		return IGUAL;
">"		return MAYOR;
"<"		return MENOR;
"!="		return NOIGUAL;
"="		return ASIGNACION;
"+="		return ASIGNACION_MAS;
"-="		return ASIGNACION_MENOS;
"or"		return OR;
"and"		return AND;
"+"		return MAS;
"-"		return MENOS;
"*"		return MULT;
"/"		return DIV;
"return"	return RETURN;
{real}		{yylval.fval = atof(yytext); return NUM_INT;}
{floating} 	{yylval.fval = atof(yytext); return NUM_FLOAT;}
{integer} 	{yylval.ival = atoi(yytext); return NUM_INT;}
{identifier} {yylval.sval = strdup(yytext); return ID;}
%%