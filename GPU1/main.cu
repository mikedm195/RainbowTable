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
*/

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Limits of char values
#define maxChar '~'
#define minChar ' '

#define SIZE_MD5 16

// number of bytes to be processed by GPU
#define NUM_B 1000
#define NUM_B_B 1000
#define NUM_T_B 1024

char* nextChar(char* str){
	int len = strlen(str);
	char* s2 = (char*) malloc (len);

	for(int i = len-1; i>=0; --i){
		s2[i] = str[i];
	}

	for (int i = len-1; i >= 0; --i){
		//s2[i] = str[i];
		if(s2[i] < maxChar-1){
			s2[i] =  s2[i] + 1;
			//std::cout << " to: " <<s2[i] << "\n";
			return s2;
		}
		else{
			s2[i] = minChar;
		}
	}
	//std::cout << "cambio\n";
	s2 = (char*) realloc (s2, len+1);
	//s2[0] = 0;
	char temp = s2[0];
	char temp2;
	for (int i = 1; i < len+1; ++i){
		temp2 = s2[i];
		s2[i] = temp;
		temp = temp2;
	}
	//std::cout << "changed\n";
	s2[0] = minChar;
	return s2;
}


char** makeBrick(char** array, char* s, int lh){
	//std::cout << s << " ini\n";
	int cont = 0;
	
	while (cont < (NUM_B/lh) && strlen(s) <= lh){
		array[cont] = s;
		//std::cout << cont << ": -" << array[cont] << "-\n";
		++cont;
		s = nextChar(s);
	}
	while (cont < (NUM_B/lh)){
		array[cont] = "";
		++cont;
	}
	return array;
}

void print(char** arr, int lh){
	for(int i = 0; i < NUM_B/lh; ++i){
		//if(arr[i] == "")
			//break;
		std::cout << i << ": -" << arr[i] << "-\n";
	}
}

__global__ void hashBrick(char** words, char** hashes){
	int id = threadIdx.x + blockIdx.x * blockDim.x;
	hashes[id] = "a";
}


int main(int argc, char* argv[]){

	int ll, lh, al, blocks, threads;

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
		if (argv[2] <= 0){
			std::cout << "Lower limit too low.\n";
			return 0;
		}
		ll = atoi(argv[2]);
		lh = atoi(argv[3]);
	}
	else{
		ll = atoi(argv[2]);
		lh = ll;
	}

	float tiempo1;
	cudaEvent_t inicio, fin;

	cudaEventCreate(&inicio);
	cudaEventCreate(&fin);
	cudaEventRecord( inicio, 0);
	

	al = 0;
	int it = ll;
	while(it <= lh){
		al += pow(94,it);
		it++;
	}

	blocks = NUM_B/NUM_B_B;
	if(blocks < NUM_B*NUM_B_B)
		blocks++;

	threads = (NUM_B/lh)/blocks;

	std::cout << "Words = " << (NUM_B/lh) << "\n";
	std::cout << "Total = " << al << "\n";

	int loops = al / (NUM_B/lh);
	if(loops * (NUM_B/lh) < al)
		loops++;
	std::cout << "Loops = " << loops << "\n";

	char* first = (char*) malloc (lh);
	for (int i = lh-1; i >= ll; --i){
		first[i] = minChar;
	}

	//std::cout << first << " first\n";

	// Declare arrays

	// CPU word aray
	char** arr = (char**) malloc (sizeof(char*)*(NUM_B/lh));
	for(int i = 0; i < (NUM_B/lh); ++i){
		arr[i] = (char*)malloc(lh);
		//std::cout << "Alloc with 0 = " << (int)arr[i][0] << "\n";
	}
	//CPU hash array
	char** hash = (char**) malloc (sizeof(char*)*(NUM_B/lh));
	//GPU word array
	char** arr_dev;
	char** h_temp = (char**) malloc (sizeof(char*)*(NUM_B/lh));
	for (int i  =0; i < (NUM_B/lh) ; ++i){
		cudaMalloc((void**)&(h_temp[i]), lh);
	}
	cudaMalloc( (void**)&arr_dev, sizeof(char*)*(NUM_B/lh));
	cudaMemcpy(arr_dev, h_temp, sizeof(char*)*(NUM_B/lh), cudaMemcpyHostToDevice);
	// GPU hash array
	char** hash_dev;
	char** h_temp2 = (char**) malloc (sizeof(char*)*(NUM_B/lh));
	for (int i  =0; i < (NUM_B/lh) ; ++i){
		cudaMalloc((void**)&h_temp2[i], lh);
	}
	cudaMalloc( (void**)&hash_dev, sizeof(char*)*(NUM_B/lh));
	cudaMemcpy(hash_dev, h_temp2, sizeof(char*)*(NUM_B/lh), cudaMemcpyHostToDevice);
	
	for (int i = 0; i < loops; ++i){
		std::cout << "entro\n";
		arr = makeBrick(arr, first, lh);

		for (int j  =0; j < (NUM_B/lh); ++j){
			cudaMemcpy(h_temp[j], arr[j], lh, cudaMemcpyHostToDevice);
		}

		hashBrick<<<blocks,threads>>>(arr_dev, hash_dev);
		cudaThreadSynchronize();
		first = nextChar(arr[(NUM_B/lh)-1]);
		char** res = (char**)malloc((NUM_B/lh)*sizeof(char*));
		cudaMemcpy(res, hash_dev, (NUM_B/lh)*sizeof(char*), cudaMemcpyDeviceToHost);
		for (int j = 0; j < (NUM_B/lh);++j){
			cudaMemcpy(hash[j], res[j], lh, cudaMemcpyDeviceToHost);
		}
		
		print(hash, lh);
	}

	cudaEventRecord(fin, 0);
	cudaEventSynchronize(fin);
	cudaEventElapsedTime(&tiempo1, inicio, fin);

	std::cout << "Time: " << tiempo1 << std::endl;
	
	//free(arr);

	return 0;
}