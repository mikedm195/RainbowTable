ALL: RainbowTable
.PHONY= clean

RainbowTable: main.cpp
	g++ -std=c++11 main.cpp sha256.cpp md5.cpp -o RainbowTable

clean:
	\rm -f RainbowTable
