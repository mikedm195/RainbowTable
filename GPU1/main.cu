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
#include <fstream>

// Limits of char values
#define maxChar '~'
#define minChar ' '

#define SIZE_MD5 17
#define SIZE_SHA 33

// number of bytes to be processed by GPU
#define NUM_B 10000
#define NUM_B_B 1000
#define NUM_T_B 1024

void nextChar(char* &str, int h){
	int len = strlen(str);

	for (int i = len-1; i >= 0; --i){
		if(str[i] < maxChar-1){
			str[i] += 1;
			return;
		}
		else{
			str[i] = minChar;
		}
	}


	if(len == h){
		str = (char*) realloc (str, len+2);
		//std::cout << "Big\n";
		len++;
	}

	char temp = str[0];
	char temp2;
	for (int i = 1; i < len+2; ++i){
		temp2 = str[i];
		str[i] = temp;
		temp = temp2;
	}
	
	str[0] = minChar;
	//std::cout << "changed to: -" << str[1] << "-\n";
}


__global__ void hashBrick(char* a, char* r, int p1, int p2, int H, int algoritmo){
	int id = threadIdx.x + (blockIdx.x * blockDim.x);
	char* word = (char*)((char*)a + (id*p1));
	char* hash = (char*)((char*)r + (id*p2));

	if(word[0] != '\0'){
		/******* AQUI VA LA LLAMADA A FUNCION DE HASHEO  *******/

		if(algoritmo == 1){
			/**** MD5 *****/
			//hash[0] = 48 + algoritmo;
			//hash[1] = '\0';

			hash[SIZE_MD5-1] = '\0';
		}
		else{
			/***** SHA *****/

			//hash[0] = 48 + algoritmo;
			//hash[1] = '\0';
			hash[SIZE_SHA-1] = '\0';
		}
	}
	else{
		hash[0] = '0';
		hash[1] = '\0';
	}

}


int main(int argc, const char* argv[]){

	int ll, al, blocks, threads, algo;

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
		algo = atoi(argv[1]);
	}
	else{
		ll = atoi(argv[2]);
		algo = atoi(argv[1]);
	}

	const int lh = (argc == 4)? atoi(argv[3]) : atoi(argv[2]);

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

	char* first = (char*) malloc (lh+1);
	for (int i = 0; i < ll; ++i){
		first[i] = minChar;
	}
	first[ll] = '\0';

	//std::cout << first << " first\n";

	// Declare arrays
	const int width = NUM_B/lh;
	const int height = lh+1;
	const int height2 = (algo==1)? SIZE_MD5 : SIZE_SHA;
	size_t host_pitch1 = height*sizeof(char);
	size_t host_pitch2 = height2*sizeof(char);

	// CPU word aray
	char arr[width][height];

	//CPU hash array
	char hash[width][height2];

	//GPU word array
	char* arr_dev;
	size_t pitch1;
	cudaMallocPitch((void**)&arr_dev, &pitch1, height, width);
	// GPU hash array
	char* hash_dev;
	size_t pitch2;
	cudaMallocPitch((void**)&hash_dev, &pitch2, height2, width);

	std::ofstream f;
	f.open("Table.txt");
	
	for (int i = 0; i < loops; ++i){

		for(int j = 0; j < width; ++j){
			if(strlen(first) <= height-1){
				for(int k = 0; k < height; ++k){
					arr[j][k] = first[k];
				}
				nextChar(first, lh);
			}
			else{
				//std::cout << "nop: " << strlen(first) << " > "  << height-1 << std::endl;
				arr[j][0] = '\0';
			}
		}

		cudaMemcpy2D(arr_dev, pitch1, arr, host_pitch1, height*sizeof(char), width, cudaMemcpyHostToDevice);

		hashBrick<<<blocks,threads>>>(arr_dev, hash_dev, pitch1, pitch2, height, algo);
		cudaThreadSynchronize();

		cudaMemcpy2D(hash, host_pitch2, hash_dev, pitch2, height2*sizeof(char), width, cudaMemcpyDeviceToHost);

		for(int j = 0; j < width; ++j){
			if(strlen(arr[j])>0)
				f << arr[j] << '\t' << hash[j] << '\n';
		}
	}

	f.close();

	cudaEventRecord(fin, 0);
	cudaEventSynchronize(fin);
	cudaEventElapsedTime(&tiempo1, inicio, fin);

	std::cout << "Time: " << tiempo1 << std::endl;
	
	//free(arr);

	return 0;
}