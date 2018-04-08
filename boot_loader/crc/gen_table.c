#include <stdio.h>
#include "crc.h"

crc  crcTable[256];

void
crcInit(void)
{
    crc  remainder;
     
    /*
     * Compute the remainder of each possible dividend.
     */
    for (int dividend = 0; dividend < 256; ++dividend)
    {
        /*
         * Start with the dividend followed by zeros.
         */
        remainder = dividend << (WIDTH - 8);
        
        /*
         * Perform modulo-2 division, a bit at a time.
         */
        for (uint8_t bit = 8; bit > 0; --bit)
        {
            /*
             * Try to divide the current data bit.
             */         
            if (remainder & TOPBIT)
            {
                remainder = (remainder << 1) ^ POLYNOMIAL;
            }
            else
            {
                remainder = (remainder << 1);
            }
        }
        
        /*
         * Store the result into the table.
         */
        crcTable[dividend] = remainder;
    }

}   /* crcInit() */

int main( void )
{
    crcInit();
    
    for( int i = 0; i < 256; i++ )
    {
        printf("%u, ", crcTable[i]);
    }
    
    return 0;
}
