#include <stdio.h>
#include <stdlib.h>
#include "fast_crc.h"

int main( int argc, char ** argv )
{
    if( argc != 2 )
    {
        printf( "Need a file on the command line!!\n\n" );
        return 1;
    }
    
    FILE *fileptr;
    unsigned char *buffer;
    int  filelen;
    
    fileptr = fopen( argv[1], "rb" );     // Open the file in binary mode
    fseek(fileptr, 0, SEEK_END);          // Jump to the end of the file
    filelen = ftell(fileptr);             // Get the current byte offset in the file
    rewind(fileptr);                      // Jump back to the beginning of the file
    
    buffer = (unsigned char *)malloc((filelen+1)*sizeof(char)); // Enough memory for file + \0
    fread(buffer, filelen, 1, fileptr); // Read in the entire file
    fclose(fileptr); // Close the file
    
    printf( "file length: %d\n", filelen );
    
    printf( "CRC: %u\n\n", crcFast( buffer, filelen ) );
    
    free( buffer );
}
