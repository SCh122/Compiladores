/* Diseño de las reglas de un MINIC */
%{
	#include <stdio.h>
	#include <math.h>
	#include <ctype.h>
	#include <stdlib.h>
	#include <string.h>

	//extern int yylineno;
	//ordena a flex a generar un analizador que mantenga el número de la línea actual leída desde su entrada
	
	//Tipo de valores
	typedef union {
		int entero;
		float real;
		int boleano;
	} TipoValor;

	//Tabla de Simbolos
	typedef struct{
		char nombre[30];
		int a1;// a1 : Tipo INT/FLOAT
		int a2;// a2 : Ambito FUN/VAR 
		TipoValor a3; // a3 : guarda valor
	} TipoTablasSimbolo;
	
	extern char * yytext;
	TipoTablasSimbolo TS[100];
	int tamTS = 0;
	int insertaSimbolo(char *, int); //(nombre,tipo)
	int localizaSimbolo(char *); // (nombre) retorna -1 si no ha sido localizado
	int getSimbolo(char *); //funcion para semantica, llama a error cuando no existe el simbolo
	int IS(char * name); //insertar simbolo (función principal)
	void muestraSimbolo();


	//Tabla de Funciones
	typedef struct {
		char nombre[256];
		int a1; // a1 : Tipo INT/FLOAT que retorna
		int a2[100];// a2 : id de los parametros
		int tamA2;
	} TipoTablasFunciones;
	
	int indiceFunTemp = 0;

	TipoTablasFunciones TF[100];
	int tamTF = 0;// tamanio tabla de funciones
	int insertarFuncion(char *, int);
	int localizaFuncion(char *);
	int getFuncion(char *);
	int IFu(char * name);// insertar funcion
	void muestraFuncion();

	int generateFuncion(char * fun);

	
	//Tipo de Codigo instrucciones
	typedef struct{
		int op;// operacion MOVER, SUMAR, RESTAR 
		int a1;// temporal a asignar
		int a2;//  operando1
		int a3;// operando2
	} TipoCodigo;

	TipoCodigo TC[100];
	int tamTC = 0;
	int indiceVarTemp = 0;

	void genCodigo(int, int, int, int);
	void addCodigo(int pos, int, int, int, int);
	int genVarTemp();
	void muestraCodigo();
	int parseBolean(int);// true 1    false 0

	int tipoVar = 0;
	int ambitoActual = 0;
	int tipoActual = 0;
	int TStempTipo[100];
	int TStempAmbito[100];
	int TStempParam[100];
	int tamTStempTipo = 0;
	int tamTStempAmbito = 0;
	int tamTStempParam = 0;

	void setTipoTS(int tipo);
	void setAmbito(char * ambito);
	void setParam(int funcion);

	TipoCodigo TCtemp[100];
	int tamTCtemp = 0;
	void addCodTemp(int, int, int ,int);
	void genCodTemp();

	void genCodAsig(int op_asig, int destino, int source);
	int getOpTipe(int tipe1, int tipe2);
	void opMover(int destino, int source);
	void runCode(char * funcion);

	void interprete();
	
	//Codigo de funciones
	typedef struct{
		char * nombre;
		int tamCod;
		TipoCodigo cod[100];// int float
	}CodFunciones;

	CodFunciones Funciones[100];
	int tamFunciones = 0;
	int buscarFuncion(char * name);

	//Parametros
	typedef struct{
		int vars[100];// variables en array
		int tamVars;// cantidad de variables
	}Parametros;

	Parametros params[100];
	int tamParams = 0;

	int varReturn[100]; 
	int actualVarReturn = -1;

	// Definición de las operaciones de lenguaje intermedio

	#define AMBITO_GLOBAL 0
	#define DIR_NULL -1
	#define MOVER 1
	#define SUMAR 2
	#define SALTAR 3
	#define SALTARV 4
	#define SALTARF 5
	#define RESTAR 6
	#define MULTIPLICAR 7
	#define DIVIDIR 8
	#define FUNC 11
	#define END 12
	#define OP_IGUAL 13
	#define OP_MAYOR 14
	#define OP_MENOR 16
	#define OP_NOIGUAL 18
	#define OP_OR 19
	#define OP_AND 20
	#define INST_RETURN 21
	#define IMPRIMIR 22 


%}

%union { int ival; float fval;char *sval; }

%token <ival> INT FLOAT BOOL VOID // tipos de variables
%token PI PD // ( )
%token LLI LLD // { }
%token COMA PYC// , ;
%token WHILE 
%token IF ELSE
%token ASIGNACION ASIGNACION_MAS ASIGNACION_MENOS // = += -= 
%token OR AND// or and
%token MAS MENOS MULT DIV // + - * /
%token IGUAL MAYOR  MENOR NOIGUAL// == > < !=
%token RETURN
%token BOOLTRUE BOOLFALSE// true false
%token <ival> NUM_INT // numero entero
%token <fval> NUM_FLOAT // numero flotante
%token <sval> ID // un string  : nombre de variable o funcion
%token IMPRINUM // print 
%right ASIGNACION_MAS ASIGNACION_MENOS// += -=
%right ASIGNACION// =
%left OR// or
%left AND// and
%left IGUAL NOIGUAL// == !=
%left MENOR MAYOR// < >
%left MAS MENOS// + -
%left MULT DIV// * /

%start programC

%%
programC	: listaDeclC ;
listaDeclC	: listaDeclC declC | /* vacio */ ;
declC 		: Tipo listaVar PYC {setTipoTS($<ival>1); setAmbito("global");}
		  | VOID ID declFun bloqueFun 
				{int pos = IFu($2);
				 TF[pos].a1 = $<ival>1;
				 setAmbito($2); 
				 setParam(pos);
				 addCodigo($<ival>3, FUNC, pos, DIR_NULL, DIR_NULL);
				 genCodigo(END, DIR_NULL, DIR_NULL, DIR_NULL);};
		  | Tipo ID declFun bloqueFun 
				{int pos = IFu($2);
				 TF[pos].a1 = $<ival>1;
				 setAmbito($2); 
				 setParam(pos);
				 addCodigo($<ival>3, FUNC, pos, DIR_NULL, DIR_NULL);
				 genCodigo(END, DIR_NULL, DIR_NULL, DIR_NULL);};
declFun		: PI Params PD {$<ival>$ = tamTC;};
listaVar 	: declAsig COMA listaVar//int a = 1,b=2;
		  | ID COMA listaVar {int pos = IS($1);TStempTipo[tamTStempTipo++] = pos; TStempAmbito[tamTStempAmbito++] = pos;}
		  | declAsig
		  | ID {int pos = IS($1); TStempTipo[tamTStempTipo++] = pos; TStempAmbito[tamTStempAmbito++] = pos;};
Params		: listaPar | /* vacio */;
listaPar	: Tipo ID COMA listaPar 
			{int pos = IS($2);
			 TS[pos].a1 = $<ival>1;
			 TStempAmbito[tamTStempAmbito++] = TStempParam[tamTStempParam++] = pos;}
		  | Tipo ID 
			{int pos = IS($2);
			 TS[pos].a1 = $<ival>1;
			 TStempAmbito[tamTStempAmbito++] = TStempParam[tamTStempParam++] = pos;};
bloqueFun 	: LLI listaInstruc LLD ;
listaInstruc	: listaInstruc instruc | /* vacio */;
instruc 	: Tipo listaVar PYC {setTipoTS($<ival>1);}
		  | asig PYC
		  | declBucle
		  | declCondicional
		  | IMPRINUM expr PYC {genCodigo(IMPRIMIR, $<ival>2, DIR_NULL, DIR_NULL);}
		  | RETURN expr PYC {genCodigo(INST_RETURN, $<ival>2, DIR_NULL, DIR_NULL);};
		  | ID callFunc PYC 
				{int fun = getFuncion($1);
				 genCodigo(SALTAR, fun, DIR_NULL, $<ival>2);
				 if(TF[fun].tamA2 != params[$<ival>2].tamVars){
				 	char cad[80];
					strcpy(cad, "error en los parametros de ");
					strcat(cad, TF[fun].nombre);
					yyerror(cad);
				 }};
declAsig	: ID op_asig asig 
				{int pos = IS($1);
				 TStempTipo[tamTStempTipo++] = TStempAmbito[tamTStempAmbito++] = pos;
				 genCodAsig($<ival>2, pos, $<ival>3);};
		  | ID op_asig expr 
				{int pos = IS($1);
				 TStempTipo[tamTStempTipo++] = pos;
				 TStempAmbito[tamTStempAmbito++] = pos;
				 genCodAsig($<ival>2, pos, $<ival>3);};
		  | ID op_asig ID callFunc 
				 {int pos = IS($1);
				  int fun = getFuncion($3);
				  TStempTipo[tamTStempTipo++] = TStempAmbito[tamTStempAmbito++] = pos;
				  genCodigo(SALTAR, fun, pos, $<ival>4);
				  if(TF[fun].tamA2 != params[$<ival>4].tamVars){
				 	char cad[80];
					strcpy(cad, "error en los parametros de ");
					strcat(cad, TF[fun].nombre);
					yyerror(cad);
				 }};
asig 		: ID op_asig asig
				{int pos = getSimbolo($1);
				 genCodAsig($<ival>2, pos, $<ival>3);
				 $<ival>$ = pos;}
		  | ID op_asig expr 
				{int pos = getSimbolo($1);
				 genCodAsig($<ival>2, pos, $<ival>3);
				 $<ival>$ = pos;}
		  | ID op_asig ID callFunc 
				{int pos = getSimbolo($1);
				 int fun = getFuncion($3);
				 genCodigo(SALTAR, fun, pos, $<ival>4);
				 $<ival>$ = pos;
				 if(TF[fun].tamA2 != params[$<ival>4].tamVars){
				 	char cad[80];
					strcpy(cad, "error en los parametros de ");
					strcat(cad, TF[fun].nombre);
					yyerror(cad);
				 }};
op_asig		: ASIGNACION {$<ival>$ = ASIGNACION;}
		  | ASIGNACION_MENOS {$<ival>$ = ASIGNACION_MENOS;}
		  | ASIGNACION_MAS {$<ival>$ = ASIGNACION_MAS;}

callFunc 	: PI listaParam PD {$<ival>$ = $<ival>2; tamParams++;}
declBucle	: bucleWhile PI condicionWhile parBucle bloqueBucle
				{addCodigo($<ival>4, FUNC, $<ival>1, DIR_NULL, DIR_NULL);
				 genCodigo(SALTAR, $<ival>3, DIR_NULL, DIR_NULL);
				 genCodigo(END, DIR_NULL, DIR_NULL, DIR_NULL);
				 genCodigo(SALTAR, $<ival>3, DIR_NULL, DIR_NULL);	}
declCondicional : condicionalIf condicionalElse
				{if($<ival>2 != -1){
				 	genCodigo(SALTARF, $<ival>2, $<ival>1, DIR_NULL);
				 }};
condicionalIf	: tokenIf PI condicionIf parDerIf bloqueFun
				{ $<ival>$ = $<ival>3;
				 addCodigo($<ival>4, FUNC, $<ival>1, DIR_NULL, DIR_NULL);
				 genCodigo(END, DIR_NULL, DIR_NULL, DIR_NULL);
				 genCodigo(SALTARV, $<ival>1, $<ival>3, DIR_NULL);};						

condicionalElse	: tokenElse condicionalIf condicionalElse
				{$<ival>$ = generateFuncion("ELSE_IF");
				 addCodigo($<ival>1, FUNC, $<ival>$, DIR_NULL, DIR_NULL);
				 if($<ival>3 != -1){
			 	 	genCodigo(SALTARF, $<ival>3, $<ival>2, DIR_NULL);
			 	 }
			 	 genCodigo(END, DIR_NULL, DIR_NULL, DIR_NULL);
			 	 };

		  | tokenElse bloqueFun 
				{$<ival>$ = generateFuncion("ELSE");
				 addCodigo($<ival>1, FUNC, $<ival>$, DIR_NULL, DIR_NULL);
				 genCodigo(END, DIR_NULL, DIR_NULL, DIR_NULL);}
		  | {$<ival>$ = -1;};
tokenElse	: ELSE {$<ival>$ = tamTC;};
tokenIf		: IF {$<ival>$ = generateFuncion("IF");};
condicionIf 	: expr {$<ival>$ = $<ival>1;};
parDerIf	: PD {$<ival>$ = tamTC;};
bucleWhile	: WHILE {$<ival>$ = generateFuncion("WHILE");}
condicionWhile  : expr {$<ival>$ = generateFuncion("IF-WHILE");
					 addCodigo(tamTC - 1, FUNC, $<ival>$, DIR_NULL, DIR_NULL);
					 genCodigo(SALTARV, $<ival>$ - 1, $<ival>1, DIR_NULL);
					 genCodigo(END, DIR_NULL, DIR_NULL, DIR_NULL);
					}
parBucle	: PD {$<ival>$ = tamTC;};

listaParam	: expr COMA listaParam {$<ival>$ = $<ival>3; params[$<ival>$].vars[params[$<ival>$].tamVars++] = $<ival>1;}
		  | expr {$<ival>$ = tamParams; params[$<ival>$].vars[params[$<ival>$].tamVars++] = $<ival>1;}
		  | {$<ival>$ = -1;}

bloqueBucle : LLI listaInstrucBucle LLD ;
listaInstrucBucle: listaInstrucBucle instruc | /* vacio */ ;
			
expr 		: term op_bin_arit expr 
				{$<ival>$ = genVarTemp();
				 genCodigo($<ival>2, $<ival>$, $<ival>1, $<ival>3);
				 TS[$<ival>$].a1 = getOpTipe(TS[$<ival>1].a1, TS[$<ival>3].a1);}
		  | term op_bin_bool expr 
				{$<ival>$ = genVarTemp(); 
				 genCodigo($<ival>2, $<ival>$, $<ival>1, $<ival>3);
				 TS[$<ival>$].a1 = BOOL;}
		  | term {$<ival>$ = $<ival>1;}
		  | BOOLTRUE {$<ival>$ = genVarTemp(); 
				  TS[$<ival>$].a3.boleano = 1;
				  TS[$<ival>$].a1 = BOOL;}
		  | BOOLFALSE {$<ival>$ = genVarTemp(); 
				   TS[$<ival>$].a3.boleano = 0;
				   TS[$<ival>$].a1 = BOOL;}
term 		: ID {$<ival>$ = localizaSimbolo($1);}
		  | NUM_INT {	$<ival>$ = genVarTemp(); 
				 	TS[$<ival>$].a3.entero = $1;
				 	TS[$<ival>$].a1 = INT;
				 	}
		  | NUM_FLOAT {$<ival>$ = genVarTemp(); 
					 TS[$<ival>$].a3.real = $1;
					 TS[$<ival>$].a1 = FLOAT;
					}

		  | PI expr PD {$<ival>$ = $<ival>2;}
op_bin_arit	: MAS {$<ival>$ = SUMAR;}
		  | MENOS {$<ival>$ = RESTAR;}
		  | MULT {$<ival>$ = MULTIPLICAR;}
		  | DIV {$<ival>$ = DIVIDIR;}
op_bin_bool     : IGUAL {$<ival>$ = OP_IGUAL;}
		  | MAYOR {$<ival>$ = OP_MAYOR;}
		  | MENOR {$<ival>$ = OP_MENOR;}
		  | NOIGUAL {$<ival>$ = OP_NOIGUAL;}
		  | OR {$<ival>$ = OP_OR;}
		  | AND {$<ival>$ = OP_AND;};

Tipo 		: INT {$<ival>$ = $1;}
		  | FLOAT {$<ival>$ = $1;}
		  | BOOL {$<ival>$ = $1;}
%%


//Funciones TablaSimbolo

int localizaSimbolo(char * name){
	for(int i = 0; i < tamTS; i++){
		if(strcmp(name, TS[i].nombre) == 0 && TS[i].a2 == ambitoActual) return i;
	}
	return -1;
}

int getSimbolo(char * name){
	int res = localizaSimbolo(name);
	if(res < 0){
		char cad[80];
		strcpy(cad, "no existe la variable ");
		strcat(cad, name);
		yyerror(cad);
	}
	return res;
}

int insertaSimbolo(char * name, int tipo){
	if(localizaSimbolo(name) >= 0)
		return -1;
	strcpy(TS[tamTS].nombre,name);
	//TS[tamTS].a1  tipo;
	TS[tamTS].a2 = ambitoActual;
	return tamTS++;
}

int IS(char * name){
	int i = insertaSimbolo(name, tipoActual);
	if(i < 0){
		yyerror("el identificador esta ya declarado");
	} 
	return i;
}

void muestraSimbolo(){
	TipoTablasSimbolo * iter;
	int i = 0;
	for(i = 0, iter = TS; i < tamTS; i++, iter++){
		switch(iter->a1){
			case INT: printf("%20s %s %d %d\n", iter->nombre, "INT", iter->a2, iter->a3.entero); break;
			case FLOAT: printf("%20s %s %d %f\n", iter->nombre, "FLOAT", iter->a2, iter->a3.real); break;
			case BOOL: printf("%20s %s %d %d\n", iter->nombre, "BOOL", iter->a2, parseBolean(iter->a3.boleano)); break;
		}
	}
}


//Funciones TablaFunciones

int localizaFuncion(char * name){
	for(int i = 0; i < tamTF; i++){
		if(strcmp(name, TF[i].nombre) == 0){
			return i;		
		}
	}
	return -1;
}

int getFuncion(char * name){
	int res = localizaFuncion(name);
	if(res < 0){
		char cad[80];
		strcpy(cad, "no existe la funcion ");
		strcat(cad, name);
		yyerror(cad);
	}
}

int insertarFuncion(char * name, int tipo){
	if(localizaFuncion(name) >= 0)
		return -1;
	strcpy(TF[tamTF].nombre, name);
	return tamTF++;
}

int IFu(char * name){
	int i = insertarFuncion(name, tipoActual);
	if(i < 0){
		char cad[80];
		strcpy(cad, "función ya declarada. ");
		strcat(cad, name);
		yyerror(cad);
	}
	return i;
}

void muestraFuncion(){
	TipoTablasFunciones * iter;
	int i = 0;
	for(i = 0, iter = TF; i < tamTF; i++, iter++){
		printf("%20s %d", iter->nombre, iter->a1);
		for(int j = 0; j < iter->tamA2; j++){
			printf(" %s ", TS[iter->a2[j]].nombre);
		}
		printf("\n");
	}
}

int generateFuncion(char * fun){
	char t[30];
	sprintf(t, "_F%d_%s", indiceFunTemp++, fun);
	strcpy(TF[tamTF].nombre , t);
	return tamTF++;
}

void genCodigo(int op, int a1, int a2, int a3){
	TipoCodigo *p;
	p = &TC[tamTC];
	p->op = op;
	p->a1 = a1;
	p->a2 = a2;
	p->a3 = a3;
	tamTC++;
}

void addCodigo(int pos, int op, int a1, int a2, int a3){
	TipoCodigo temp1;
	TipoCodigo temp2;
	temp1 = TC[pos];
	temp2 = TC[pos];
	for(int i = pos + 1; i < tamTC + 1; i++){
		temp1 = temp2;
		temp2 = TC[i];
		TC[i] = temp1;
	}
	TipoCodigo *p;
	p = &TC[pos];
	p->op = op;
	p->a1 = a1;
	p->a2 = a2;
	p->a3 = a3;
	tamTC++;
}

int genVarTemp(){
	char t[30];
	sprintf(t, "_T%-2d", indiceVarTemp++);
	strcpy(TS[tamTS].nombre , t);
	TS[tamTS].a2 = ambitoActual;
	return tamTS++;
}

int parseBolean(int boleano){
	if(boleano)
	   return 1;
	return 0;
}

//TODO
void muestraCodigo(){
	int op, a1, a2, a3;
	for(int i = 0; i < tamTC; i++){
		op = TC[i].op;
		a1 = TC[i].a1;
		a2 = TC[i].a2;
		a3 = TC[i].a3;
		printf("%2d) ", i);
		switch(op){
			case MOVER: printf("MOVER %s %s\n", TS[a1].nombre, TS[a2].nombre); break;
			case SUMAR: printf("SUMAR %s %s %s\n", TS[a1].nombre, TS[a2].nombre, TS[a3].nombre); break;
			case RESTAR: printf("RESTAR %s %s %s\n", TS[a1].nombre, TS[a2].nombre, TS[a3].nombre); break;
			case MULTIPLICAR: printf("MULTIPLICAR %s %s %s\n", TS[a1].nombre, TS[a2].nombre, TS[a3].nombre); break;
			case DIVIDIR: printf("DIVIDIR %s %s %s\n", TS[a1].nombre, TS[a2].nombre, TS[a3].nombre); break;
			case OP_IGUAL: printf("OP_IGUAL %s %s %s\n", TS[a1].nombre, TS[a2].nombre, TS[a3].nombre); break;
			case OP_MAYOR: printf("OP_MAYOR %s %s %s\n", TS[a1].nombre, TS[a2].nombre, TS[a3].nombre); break;
			case OP_MENOR: printf("OP_MENOR %s %s %s\n", TS[a1].nombre, TS[a2].nombre, TS[a3].nombre); break;
			case OP_NOIGUAL: printf("OP_NOIGUAL %s %s %s\n", TS[a1].nombre, TS[a2].nombre, TS[a3].nombre); break;
			case OP_OR: printf("OP_OR %s %s %s\n", TS[a1].nombre, TS[a2].nombre, TS[a3].nombre); break;
			case OP_AND: printf("OP_AND %s %s %s\n", TS[a1].nombre, TS[a2].nombre, TS[a3].nombre); break;
			case FUNC: printf("FUNC %s\n", TF[a1].nombre); break;
			case END: printf("END\n"); break;
			case SALTARV: printf("SALTARV %s %s\n", TF[a1].nombre, TS[a2].nombre); break;
			case SALTARF: printf("SALTARF %s %s\n", TF[a1].nombre, TS[a2].nombre); break;	
			case INST_RETURN: printf("INST_RETURN %s\n", TS[a1].nombre); break;
			case IMPRIMIR: printf("IMPRIMIR %s\n", TS[a1].nombre); break;
			case SALTAR: {
				printf("SALTAR %s ", TF[a1].nombre);
				if(a2 == -1) printf("VOID ");
				else printf("%s ", TS[a2].nombre);
				if(a3 == -1) printf("VOID\n");
				else {
					for(int i = 0; i < params[a3].tamVars; i++){
						printf("%s ", TS[params[a3].vars[i]].nombre);
					}
					printf("\n");
				}
				break;
			}
		}
	}
}

void setTipoTS(int tipo){
	for(int i = 0; i < tamTStempTipo; i++){
		TS[TStempTipo[i]].a1 = tipo;
	}
	tamTStempTipo = 0;
}

void setAmbito(char * ambito){
	int ambt = localizaFuncion(ambito);
	if(ambt == -1) ambt = 0;
	for(int i = 0; i < tamTStempAmbito; i++){
		TS[TStempAmbito[i]].a2 = ambt;
	}
	tamTStempAmbito = 0;
}

void setParam(int funcion){
	for(int i = 0; i < tamTStempParam; i++){
		TF[funcion].a2[TF[funcion].tamA2++] = TStempParam[i];
	}
	tamTStempParam = 0;
}

void addCodTemp(int op, int a1, int a2, int a3){
	TipoCodigo *p;
	p = &TCtemp[tamTCtemp];
	p->op = op;
	p->a1 = a1;
	p->a2 = a2;
	p->a3 = a3;
	tamTCtemp++;
}

void genCodTemp(){
	int i = 0;
	TipoCodigo * iter;
	for(i = 0, iter = TCtemp; i < tamTCtemp; i++, iter++){
		genCodigo(iter->op, iter->a1, iter->a2, iter->a3);
	}
	tamTCtemp = 0;
}

void genCodAsig(int op_asig, int destino, int source){
	switch(op_asig){
		case ASIGNACION: genCodigo(MOVER, destino, source, DIR_NULL); break;
		case ASIGNACION_MENOS: genCodigo(RESTAR, destino, destino, source); break;
		case ASIGNACION_MAS: genCodigo(SUMAR, destino, destino, source); break;
	}
}

int getOpTipe(int tipe1, int tipe2){
	if(tipe1 == FLOAT || tipe2 == FLOAT)
		return FLOAT;
	return INT;
}

int buscarFuncion(char * name){
	for(int i = 0; i < tamFunciones; i++){
		if(strcmp(name, Funciones[i].nombre) == 0) return i;
	}
	return -1;
}


void setVal(TipoValor * val, void * numPtr, int tipoVal, int tipoNum){
	switch(tipoNum){
		case INT:{
			int num = *((int *) numPtr);
			switch(tipoVal){
				case INT: val->entero = num; break;
				case FLOAT: val->real = (float) num; break;
				case BOOL: val->boleano = num != 0; break;
			}
			break;
		}
		case FLOAT: {
			float num = *((float *) numPtr);
			switch(tipoVal){
				case INT: val->entero = (int) num; break;
				case FLOAT: val->real = num; break;
				case BOOL: val->boleano = num != 0; break;
			}
			break;
		}
		case BOOL: {
			int num = *((int *) numPtr);
			switch(tipoVal){
				case INT: val->entero = num; break;
				case FLOAT: val->real = (float) num; break;
				case BOOL: val->boleano = num != 0; break;
			}
			break;
		}
	}
}


void * getVal(TipoValor val, int tipo){
	void * res = NULL;
	switch(tipo){
		case INT: res = (void *) &(val.entero); break;
		case FLOAT: res = (void *) &(val.real); break;
		case BOOL: res = (void *) &(val.boleano); break;
	}
	return res;
}


void opBin(int destino, int val1, int val2, int op){
	int tipoDestino = TS[destino].a1;
	int tipoVal1 = TS[val1].a1;
	int tipoVal2 = TS[val2].a1;
	
	switch(op){
		case SUMAR: {
			switch(tipoVal1){
				case INT: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 + num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 + num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 + num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case FLOAT: {
					float num1 = *((float *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 + num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 + num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 + num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);
							break;
						}
					}
					break;
				}
				case BOOL: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 + num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 + num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 + num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
			}
			break;
		}
		case RESTAR: {
			switch(tipoVal1){
				case INT: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 - num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 - num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 - num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case FLOAT: {
					float num1 = *((float *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 - num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 - num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 - num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);
							break;
						}
					}
					break;
				}
				case BOOL: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 - num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 - num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 - num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
			}
			break;
		}
		case MULTIPLICAR: {
			switch(tipoVal1){
				case INT: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 * num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 * num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 * num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case FLOAT: {
					float num1 = *((float *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 * num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 * num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 * num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);
							break;
						}
					}
					break;
				}
				case BOOL: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 * num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 * num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 * num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
			}
			break;
		}
		case DIVIDIR: {
			switch(tipoVal1){
				case INT: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 / num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 / num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 / num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case FLOAT: {
					float num1 = *((float *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 / num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 / num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 / num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);
							break;
						}
					}
					break;
				}
				case BOOL: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 / num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							float res = num1 / num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, FLOAT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 / num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
			}
			break;
		}
		case OP_IGUAL: {
			switch(tipoVal1){
				case INT: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 == num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 == num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 == num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case FLOAT: {
					float num1 = *((float *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 == num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 == num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 == num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case BOOL: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 == num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 == num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 == num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
			}
			break;
		}
		case OP_MAYOR: {
			switch(tipoVal1){
				case INT: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 > num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 > num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 > num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case FLOAT: {
					float num1 = *((float *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 > num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 > num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 > num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case BOOL: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 > num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 > num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 > num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
			}
			break;
		}
		case OP_MENOR: {
			switch(tipoVal1){
				case INT: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 < num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 < num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 < num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case FLOAT: {
					float num1 = *((float *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 < num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 < num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 < num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case BOOL: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 < num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 < num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 < num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
			}
			break;
		}
		case OP_NOIGUAL: {
			switch(tipoVal1){
				case INT: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 != num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 != num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 != num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case FLOAT: {
					float num1 = *((float *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 != num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 != num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 != num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case BOOL: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 != num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 != num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 != num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
			}
			break;
		}
		case OP_OR: {
			switch(tipoVal1){
				case INT: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 || num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 || num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 || num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case FLOAT: {
					float num1 = *((float *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 || num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 || num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 || num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case BOOL: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 || num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 || num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 || num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
			}
			break;
		}
		case OP_AND: {
			switch(tipoVal1){
				case INT: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 && num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 && num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 && num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case FLOAT: {
					float num1 = *((float *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 && num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 && num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 && num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				case BOOL: {
					int num1 = *((int *) getVal(TS[val1].a3, tipoVal1));
					switch(tipoVal2){
						case INT: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 && num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
						case FLOAT: {
							float num2 = *((float *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 && num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);	
							break;
						}
						case BOOL: {
							int num2 = *((int *) getVal(TS[val2].a3, tipoVal2));
							int res = num1 && num2;
							setVal(&(TS[destino].a3), (void *) &res, tipoDestino, INT);
							break;
						}
					}
					break;
				}
				
			}
			break;
		}
	}
}

void opMover(int destino, int source){
	int tipoDestino = TS[destino].a1;
	int tipoSource = TS[source].a1;
	switch(tipoSource){
		case INT: {
			int num = *((int *) getVal(TS[source].a3, tipoSource));
			setVal(&(TS[destino].a3), (void *) &num, tipoDestino, tipoSource);
			break;
		}
		case FLOAT:{
			float num = *((float *) getVal(TS[source].a3, tipoSource));
			setVal(&(TS[destino].a3), (void *) &num, tipoDestino, tipoSource);
			break;
		}
		case BOOL:{
			int num = *((int *) getVal(TS[source].a3, tipoSource));
			setVal(&(TS[destino].a3), (void *) &num, tipoDestino, tipoSource);
			break;
		}

	}
}

void opNegacion(int destino, int source){
	int tipo = TS[source].a1;
	switch(tipo){
		case INT: TS[destino].a3.boleano = !TS[source].a3.entero; break;
		case FLOAT: TS[destino].a3.boleano = !TS[source].a3.real; break;
		case BOOL: TS[destino].a3.boleano = !TS[source].a3.boleano; break;
	}
}

void printSimbolo(int id){
	int tipo = TS[id].a1;
	switch(tipo){
		case INT: printf("%d\n", TS[id].a3.entero); break;
		case FLOAT: printf("%f\n", TS[id].a3.real); break;
		case BOOL: printf("%d\n", TS[id].a3.boleano); break;
	}
}

void inSimbolo(int id){
	int tipo = TS[id].a1;

	switch(tipo){
		case INT: scanf("%d", &(TS[id].a3.entero)); break;
		case FLOAT: scanf("%f", &(TS[id].a3.real)); break;
		case BOOL: scanf("%d", &(TS[id].a3.boleano)); break;
	}	
}

void runCode(char * funcion){
	int id = buscarFuncion(funcion);
	TipoCodigo * iter;
	int i = 0;
	int op, a1, a2, a3;
	int funGen[64];
	int actualfunGen = -1;
	for(i = 0, iter = Funciones[id].cod; i < Funciones[id].tamCod; i++, iter++){
		op = iter->op;
		a1 = iter->a1;
		a2 = iter->a2;
		a3 = iter->a3;
		if(actualfunGen != -1){
			if(op == FUNC){
				Funciones[tamFunciones].nombre = TF[a1].nombre;
				actualfunGen++;
				funGen[actualfunGen] = tamFunciones;
				tamFunciones++;
			}
			else if(op == END)
				actualfunGen--;
			else 
				Funciones[funGen[actualfunGen]].cod[Funciones[funGen[actualfunGen]].tamCod++] = Funciones[id].cod[i];
		}
		else{
			if(op == SUMAR || op == RESTAR || op == MULTIPLICAR || op == DIVIDIR || op == OP_IGUAL || op == OP_MAYOR || op == OP_MENOR || op == OP_NOIGUAL || op == OP_OR || op == OP_AND)  
					opBin(a1, a2, a3, op);
			else{
				switch(op){
					case FUNC: {
						Funciones[tamFunciones].nombre = TF[a1].nombre;
						actualfunGen++;
						funGen[actualfunGen] = tamFunciones;
						tamFunciones++;
						break;
					}
					case MOVER: opMover(a1, a2); break;
					case INST_RETURN:{
						opMover(varReturn[actualVarReturn], a1);
						actualVarReturn--;
						return;
						break;
					}
					case IMPRIMIR:{
						 printSimbolo(a1);
						 break;
					}
					case SALTAR: {
						if(a2 != DIR_NULL){
							actualVarReturn++;
							varReturn[actualVarReturn] = a2;
						}
						if(a3 != DIR_NULL){
							for(int i = 0; i < params[a3].tamVars; i++){
								opMover(TF[a1].a2[i], params[a3].vars[i]);
							}
						}
						runCode(TF[a1].nombre);
						break;
					}
					case SALTARV: {
						switch(TS[a2].a1){
							case INT: {if(TS[a2].a3.entero){runCode(TF[a1].nombre);}  break;} 
							case FLOAT: {if(TS[a2].a3.real){runCode(TF[a1].nombre);}  break;} 
							case BOOL: {if(TS[a2].a3.boleano){runCode(TF[a1].nombre);}  break;} 
						}
						break;
					}
					case SALTARF: {
						switch(TS[a2].a1){
							case INT: {if(!TS[a2].a3.entero){runCode(TF[a1].nombre);}  break;} 
							case FLOAT: {if(!TS[a2].a3.real){runCode(TF[a1].nombre);}  break;} 
							case BOOL: {if(!TS[a2].a3.boleano){runCode(TF[a1].nombre);}  break;} 
						}
						break;
					}
				}	
			}
			
		}
	}
}

void interprete(){
	Funciones[0].nombre = "global";
	for(int i = 0; i < tamTC; i++){
		Funciones[0].cod[Funciones[0].tamCod++] = TC[i];
	}
	tamFunciones++;
	printf("Programa en ejecución: \n");
	runCode("global");
}



int yyerror(char *m) {	
	fprintf(stderr,"Error : %s \n", m);
	getchar(); 
	exit(0);
}

int main(int argc, char ** argv) {
	insertarFuncion("global", 0);
	yyparse();	
	int m = getFuncion("main");
	if(m < 0){ 
		yyerror("No esta declarada la funcion main");
	}
	int varReturnMain = genVarTemp();
	TS[varReturnMain].a1 = INT;
	genCodigo(SALTAR, m, varReturnMain, DIR_NULL);

	muestraSimbolo();//tabla de simbolos
	printf("\n");
	muestraCodigo();//tabla de codigo
	printf("\n");
	interprete();
}
