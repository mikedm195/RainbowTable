#include <iostream>
#include <fstream>
#include <stdio.h>
#include "sha256.h"
#include "md5.h"

#define maxChar '~'
#define minChar ' '

void combinaciones(int len, int algoritmo, std::ofstream& a){
    char letras[len];
    //inicializar letras de arreglo a 'a'
    for(int i = 0; i < len; i++)
        letras[i] = minChar;


    while(letras[0] <= maxChar){
        if(algoritmo == 0)
            a << letras << "\t " << md5(letras) << "\n";
        else
            a << letras << "\t " << sha256(letras) << "\n";
        for(int i = len-1; i >= 0; i--){
            if(letras[i] >= maxChar && i != 0){
                letras[i] = minChar;
            }else{
                letras[i]++;
                break;
            }

        }
    }
}

int main(int argc, char *argv[]){

    if(argc != 2 ){
        std::cout << "./RainbowTable 0|1 (MD5|SHA)" << std::endl;
        return -1;
    }

    std::ofstream a;

    int algoritmo = atoi(argv[1]);
    if(algoritmo == 0)
        a.open("MD5.txt");
    else if(algoritmo == 1)
        a.open("SHA.txt");

    for(int i = 1; i < 4; i++)
        combinaciones(i, algoritmo, a);

    a.close();
    return 0;
}
