#include "sha.h"
#include "md5.h"
int main(int argc, char const *argv[]) {
	// printf("%s\n", sha("abc"));
	md5("abc");
	// printf("%s\n", md5("abc"));
	return 0;
}
