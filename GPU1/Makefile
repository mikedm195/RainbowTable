ALL: rainbow
.PHONY=clean

clean:
	\rm -rf rainbow Table.txt

rainbow: main.cu
	nvcc -o rainbow main.cu
