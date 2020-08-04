int main(){
	int rpta=0;
	int a=6;
	int b=3;
	int op=3;
	bool flag = true;
	while ( flag == true ) {
    		if ( a == 0 and b == 0 ) {
    			    flag = false;
    		}
    		if ( op == 0 ) {
    		    	rpta = a+b;
    		}
    		else if ( op == 1 ) {
    		    	rpta = a-b;
    		}
    		else if ( op == 2 ) {
    		    	rpta = a*b;
    		}
    		else if ( op == 3 ) {
    		    	rpta = a/b;
    		}
    		flag = false;
    		print rpta ;
	}
}
