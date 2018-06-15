#define _CRT_SECURE_NO_WARNINGS
#include<stdio.h>

int main() {
	char buf[5120];
	FILE *floppy_desc, *file_desc;
	file_desc = fopen("D:\\workCode\\os\\new\\os.bin", "rb+");
	fread(buf, 1, 5120, file_desc);
	fclose(file_desc);
	floppy_desc = fopen("D:\\workCode\\os\\new\\file.img", "rb+");
	fseek(floppy_desc, 512, SEEK_SET);
	fwrite(buf, 1, 5120, floppy_desc);
	fclose(floppy_desc);
	printf("success");
	getchar();
}