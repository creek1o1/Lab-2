#include <stdio.h>
#include <string.h>

extern unsigned char ram[]; // Ram declared in assembly
extern void hammingcmp(char string1[256], char string2[256]);

int main() {
    char string1[256];
    char string2[256];
    
    printf("Enter first sentence: ");
    fgets(string1, sizeof(string1), stdin);
    printf("Enter second sentence: ");
    fgets(string2, sizeof(string2), stdin);
    hammingcmp(string1, string2);

    printf("Hamming Distance: %u\n", ram[0x50]);

    return 0;
}
