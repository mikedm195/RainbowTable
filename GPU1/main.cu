/*
#######################################################
#                                                     #
#	Final Porject, Programación Multinúcleo           #
#	Daniel Monzalvo, Miguel del Moral                 #
#													  #
#   Rainbow table construction in parallel,           #
#   Hash algorythm sequecial                          #
#                                                     #
#######################################################


#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Limits of char values
#define maxChar '~'
#define minChar ' '

// number of bytes to be processed by one thread
#define NUM_B
#define NUM_THREADS


__global__ void hashesBrick(){
	
}

char** makeBrick(char* s, int size){
	
}


int main(int argc, char* argv[]){

	int ll, lh, al;

	if(argc < 3){
		std::cout << "please choose algorythm: (1)MD5 (2)SHA, and length." << std::endl;
		return 0;
	}
	else if(argc > 4){
		std::cout << "too many arguments.\n";
		return 0;
	}
	else if(argc == 4){
		if (argv[2] > argv[3]){
			std::cout << "Lower limit higher than hig limit.\n";
			return 0;
		}
		ll = argv[2];
		lh = argv[3];
	}

	char*

	return 0;
}