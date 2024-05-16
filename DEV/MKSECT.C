/**
 * MKSECT.C: Splits a file between multiple FAT sectors.
 */

#include <errno.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SEC_SIZE 0x80 /* 0x200 in later versions */
#define PATH_MAX 13

void error_os(const char *fmt, ...)
{
	va_list va;
	char *error;

	error = strerror(errno);

	va_start(va, fmt);

	fputs("error: ", stdout);
	vprintf(fmt, va);

	if (error != NULL) {
		fputs(": ", stdout);
		fputs(error, stdout);
	}

	fputc('\n', stdout);

	va_end(va);
}

int mksect(char *infile)
{
	FILE *input;
	FILE *output;

	char *dot;

	size_t read_len;
	size_t write_len;

	unsigned char sec;
	char *buf;

	input = fopen(infile, "rb");

	if (input == NULL) {
		error_os("could not open file %s", infile);
		return 1;
	}

	sec = 0;
	buf = (char *)malloc(SEC_SIZE);

	if (buf == NULL) {
		error_os("failed to allocate %d bytes", SEC_SIZE);
		return 1;
	}

	do {
		/* 8.3 + NUL */
		char outfile[PATH_MAX];

		read_len = fread(buf, 1, SEC_SIZE, input);

		if (read_len < SEC_SIZE) {
			if (ferror(input)) {
				error_os("failed to read file %s", infile);
				return 1;
			}

			memset(buf + read_len, 0, SEC_SIZE - read_len);
		}

		memcpy(outfile, infile, PATH_MAX);
		dot = strchr(outfile, '.');

		if (dot == NULL) {
			dot = strchr(outfile, '\0');
			*dot = '.';
		}

		/* hopefully this optimizes into a single DIV */
		dot[1] = 'S';
		dot[2] = sec / 10 + 0x30;
		dot[3] = sec % 10 + 0x30;

		output = fopen(outfile, "wb");

		if (output == NULL) {
			error_os("could not open file %s", outfile);
			return 1;
		}

		write_len = fwrite(buf, 1, SEC_SIZE, output);

		if (write_len < SEC_SIZE) {
			error_os("could not write to file %s", outfile);
			return 1;
		}

		fclose(output);

		sec++;
	} while (read_len >= SEC_SIZE);

	fclose(input);
	return 0;
}

int usage(char *program_name)
{
	fprintf(stderr, "usage: %s FILE\n", program_name);
	return 1;
}

int main(int argc, char *argv[])
{
	if (argc != 2)
		return usage(argv[0]);

	return mksect(argv[1]);
}
