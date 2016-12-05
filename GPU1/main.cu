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
//#include "md5.h"
//#include "sha.h"
// Limits of char values
#define maxChar '~'
#define minChar ' '

#define SIZE_MD5 33
#define SIZE_SHA 33

// number of bytes to be processed by GPU
#define NUM_B 10000
#define NUM_B_B 1000
#define NUM_T_B 1024


// *************************** MD5 ************************//

__device__ unsigned func0( unsigned abcd[] ){
    return ( abcd[1] & abcd[2]) | (~abcd[1] & abcd[3]);}

__device__ unsigned func1( unsigned abcd[] ){
    return ( abcd[3] & abcd[1]) | (~abcd[3] & abcd[2]);}

__device__ unsigned func2( unsigned abcd[] ){
    return  abcd[1] ^ abcd[2] ^ abcd[3];}

__device__ unsigned func3( unsigned abcd[] ){
    return abcd[2] ^ (abcd[1] |~ abcd[3]);}

typedef unsigned (*DgstFctn)(unsigned a[]);

typedef union uwb {
    unsigned w;
    unsigned char b[4];
} MD5union;

typedef unsigned DigestArray[4];

__device__ unsigned rol( unsigned r, short N )
{
    unsigned  mask1 = (1<<N) -1;
    return ((r>>(32-N)) & mask1) | ((r<<N) & ~mask1);
}

__device__ unsigned *calctable( unsigned *k)
{
    double s, pwr = 2;
    int i;
    for (int j = 1; i < 32; ++i){
    	pwr *= 2;
    }
    //pwr = pow( 2, 32);
    for (i=0; i<64; i++) {
        s = fabs(sin((double)(1+i)));
        k[i] = (unsigned)( s * pwr );
    }
    return k;
}

__device__ unsigned *getMd5( const char *msg, int mlen){
	DigestArray h0 = { 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476 };
    DgstFctn ff[] = { &func0, &func1, &func2, &func3 };
    short M[] = { 1, 5, 3, 7 };
    short O[] = { 0, 1, 5, 0 };
    short rot0[] = { 7,12,17,22};
    short rot1[] = { 5, 9,14,20};
    short rot2[] = { 4,11,16,23};
    short rot3[] = { 6,10,15,21};
    short *rots[] = {rot0, rot1, rot2, rot3 };
    unsigned kspace[64];
    unsigned *k;

    DigestArray h;
    DigestArray abcd;
    DgstFctn fctn;
    short m, o, g;
    unsigned f;
    short *rotn;
    union {
        unsigned w[16];
        char     b[64];
    }mm;
    int os = 0;
    int grp, grps, q, p;
    unsigned char *msg2;

    if (k==NULL) k= calctable(kspace);

    for (q=0; q<4; q++) h[q] = h0[q];   // initialize

    {
        grps  = 1 + (mlen+8)/64;
        msg2 = (unsigned char*)malloc( 64*grps);
        memcpy( msg2, msg, mlen);
        msg2[mlen] = (unsigned char)0x80;
        q = mlen + 1;
        while (q < 64*grps){ msg2[q] = 0; q++ ; }
        {
            MD5union u;
            u.w = 8*mlen;
            q -= 8;
            memcpy(msg2+q, &u.w, 4 );
        }
    }

    for (grp=0; grp<grps; grp++)
    {
        memcpy( mm.b, msg2+os, 64);
        for(q=0;q<4;q++) abcd[q] = h[q];
        for (p = 0; p<4; p++) {
            fctn = ff[p];
            rotn = rots[p];
            m = M[p]; o= O[p];
            for (q=0; q<16; q++) {
                g = (m*q + o) % 16;
                f = abcd[1] + rol( abcd[0]+ fctn(abcd) + k[q+16*p] + mm.w[g], rotn[q%4]);

                abcd[0] = abcd[3];
                abcd[3] = abcd[2];
                abcd[2] = abcd[1];
                abcd[1] = f;
            }
        }
        for (p=0; p<4; p++)
            h[p] += abcd[p];
        os += 64;
    }
    return h;
}


__device__ char * md5(char* msg, int H){
    int j,k;
    char * res = "";
    int sizef = 0;
    for(int i = 0; i < H; ++i){
    	if(msg[i] == '\0')
    		break;
    	sizef++;
    }
    unsigned *d = getMd5(msg, sizef);
    MD5union u;
    char temp[33];
    char mask = 240;
    char mask2 = 15;
    temp[32] = '\0';
    char* temp2;
    int cont = 0;
    for (j=0;j<4; j++){
        u.w = d[j];
        for (k=0;k<4;k++){
            int sum = 0;
            int mult = 8;
            for (int i = 7 ; i >=4 ; i--) {
                if((u.b[k] & (1 << i)) != 0 )
                    sum+=mult;
                // printf("%d",(u.b[k] & (1 << i)) != 0 );
                mult/=2;
            }
            // printf("\n%d\n",sum );
            if(sum<=9)
                temp[cont++] = (char)sum+48;
            else
                temp[cont++] = (char)sum+87;
            sum=0;
            mult = 8;
            for (int i = 3 ; i >=0 ; i--) {
                if((u.b[k] & (1 << i)) != 0 )
                    sum+=mult;
                //  printf("%d",(u.b[k] & (1 << i)) != 0 );
                mult/=2;
            }
            if(sum<=9)
                temp[cont++] = (char)sum+48;
            else
                temp[cont++] = (char)sum+87;
            // printf("%02x", u.b[k] );
        }
    }
    // printf("\n");
    // printf("%s\n",temp );
    return temp;
}


//***************************************  MD5 - FIN *************************************//

//*************************************** crear nueva cadena ******************************//
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

/******************************** KERNEL ***********************************************/
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

			char* res = md5(word, H);

			for (int i = 0; i < SIZE_MD5-1; ++i){
				hash[i] = res[i];
			}

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


/******************* Main ***********************************/

int main(int argc, const char* argv[]){
	//md5("hola");
	//sha("hola");
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

	clock_t t;
	t = clock();

	cudaEventCreate(&inicio);
	cudaEventCreate(&fin);
	cudaEventRecord(inicio, 0);


	al = 0;
	int it = ll;
	while(it <= lh){
		al += pow(94,it);
		it++;
	}

	// Calculo de bloques y threads
	blocks = NUM_B/NUM_B_B;
	if(blocks < NUM_B*NUM_B_B)
		blocks++;

	threads = (NUM_B/lh)/blocks;

	std::cout << "Words = " << (NUM_B/lh) << "\n";
	std::cout << "Total = " << al << "\n";

	// Calculo de bricks a procesar

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

	// Archivo
	std::ofstream f;
	f.open("Table.txt");

	// Recorrer todos los bricks
	for (int i = 0; i < loops; ++i){

		// Crear Bricks
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

		// Copiar a Tarjeta
		cudaMemcpy2D(arr_dev, pitch1, arr, host_pitch1, height*sizeof(char), width, cudaMemcpyHostToDevice);

		// Procesar el Kernel
		hashBrick<<<blocks,threads>>>(arr_dev, hash_dev, pitch1, pitch2, height, algo);
		cudaThreadSynchronize();

		// Copiar a RAM
		cudaMemcpy2D(hash, host_pitch2, hash_dev, pitch2, height2*sizeof(char), width, cudaMemcpyDeviceToHost);

		// Copiar a DISCO
		for(int j = 0; j < width; ++j){
			if(strlen(arr[j])>0)
				f << arr[j] << '\t' << hash[j] << '\n';
		}
	}

	f.close();

	cudaEventRecord(fin, 0);
	cudaEventSynchronize(fin);
	cudaEventElapsedTime(&tiempo1, inicio, fin);

	t = clock()-t; 

	std::cout << "Time: " << (((float)t) / CLOCKS_PER_SEC) << std::endl;

	//free(arr);

	return 0;
}
