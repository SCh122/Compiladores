%%
programC	: listaDeclC ;
listaDeclC	: listaDeclC declC | /* vacio */ ;
declC 		: Tipo listaVar PYC | T_VOID ID declFun bloqueFun | Tipo ID declFun bloqueFun ;
declFun		: PI Params PD ;
listaVar 	: declAsig COMA listaVar | ID COMA listaVar | declAsig | ID;
Params		: listaPar | /* vacio */;
listaPar	: Tipo ID COMA listaPar  | Tipo ID ;//int function(int a,int b)
bloqueFun 	: LLI listaInstruc LLD ;
listaInstruc	: listaInstruc instruc | /* vacio */;
instruc 	: Tipo listaVar PYC
		  | asig PYC
		  | declBucle
		  | declCondicional
		  | IMPRINUM expr PYC 
		  | LEERNUM ID PYC
		  | RETURN expr PYC
		  | ID callFunc PYC;
declAsig	: ID op_asig asig  | ID op_asig expr | ID op_asig ID callFunc;
asig 		: ID op_asig asig  | ID op_asig expr | ID op_asig ID callFunc;
op_asig		: ASIGNACION | ASIGNACION_MENOS | ASIGNACION_MAS ;

callFunc 	: PI listaParam PD;
declBucle	: bucleWhile PI condicionWhile parBucle bloqueBucle
declCondicional : condicionalIf condicionalElse;
condicionalIf	: tokenIf PI condicionIf parDerIf bloqueFun;						

condicionalElse	: tokenElse condicionalIf condicionalElse | tokenElse bloqueFun  |  /* vacio */;
tokenElse	: ELSE ;
tokenIf		: IF  ;
condicionIf 	: expr ;
parDerIf	: PD ;
bucleWhile	: WHILE ;
condicionWhile  : expr ;
parBucle	: PD ;

listaAsig 	: asig COMA listaAsig | asig |/* vacio */ ;

listaParam	: expr COMA listaParam  | expr  |  /* vacio */;

bloqueBucle 	: LLI listaInstrucBucle LLD ;
listaInstrucBucle: listaInstrucBucle instruc | /* vacio */ ;
			
expr 		: term op_bin_arit expr 
		  | term op_bin_bool expr 
		  | term 
		  | BOOLTRUE 
		  | BOOLFALSE
		  | incrementos ;
incrementos	: term INCREMENT
		  | term DECREMENT ;
term 		: ID 
		  | NUM_INT 
		  | NUM_FLOAT 
		  | PI expr PD ;
op_bin_arit	: MAS 
		  | MENOS 
		  | MULT
		  | DIV ;
op_bin_bool     : IGUAL 
		  | MAYOR 
		  | MENOR 
		  | NOIGUAL 
		  | OR
		  | AND;

Tipo 		: INT 
		  | T_FLOAT
		  | T_BOOL;

%%