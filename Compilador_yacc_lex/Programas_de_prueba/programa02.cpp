//Programa con declaraciones de funciones con diferentes tipos de valores de retorno
float suma(float a , float b){
	float resultado = a+b;
	return resultado;
}

int resta(int a, int b){
	int resultado = a-b;
	return resultado;
}

int multiplicacion(int a, int b){
	int resultado = a*b;
	return resultado;
}

float division(float a,float b){
	float resultado = a/b;
	return resultado;
}

int main(){
	float a = 14.9, b = 7.1;
	int  c = 12, d = 8;
	int resultado1,resultado2;
	float resultado3, resultado4;
	resultado1 = multiplicacion(c,d);
	resultado2 = resta(c,d);
	resultado3 = suma(a,b);
	resultado4 = division(a,b);
	print resultado1;
	print resultado2;
	print resultado3;
	print resultado4;
	return 0;
}
