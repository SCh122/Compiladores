//programa con while anidado donde
//el numero "a" se imprime "b" veces
//en cada iteracion y este
//al terminar el while anidado
//se incrementa en uno
// hasta que "a" se mayor o igual a "n"

int main(){
	int a=0;
	int n=3;
	while (a < n){
		int b=2;
		while(b>0){
			print a;
			b-=1;
		}
		a+=1;
	}
	return 0;
}
