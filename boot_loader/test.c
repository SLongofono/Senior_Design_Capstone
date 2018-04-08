#include "crc/fast_crc.h"

#define M_TIME *((volatile unsigned long *)(0x200bff8))

#define BOARD_LEDS *((volatile unsigned short *)(0x98000000))

#define RAM_KERNEL_START (void *)(0x80000000)
#define ROM_KERNEL_START (void *)(0x90002000)

#define ROM_KERNEL_END   (void *)(0x90602000)

#define KERNEL_LENGTH (int)( (unsigned long)ROM_KERNEL_END - (unsigned long)ROM_KERNEL_START )

static const crc pre_kernel_crc = 22608;

void start( void )
{
    // initial value incase we never get past here
    unsigned short next_leds = 0x0001;
    BOARD_LEDS = next_leds;
    
    // the source and destination for the kernel
    //  copy it from ROM to RAM
    unsigned long * src = ROM_KERNEL_START;
    unsigned long * dst = RAM_KERNEL_START;
    
    while( src < (unsigned long *)ROM_KERNEL_END )
    {
        // move the 8 bytes
        *(dst++) = *(src++);
        
        // update LEDs every 64K
        if( ( ((unsigned long)dst) % 0x10000 ) == 0 )
        {
            next_leds = next_leds << 1;
            
            // handle roll over
            if( next_leds == 0 )
                next_leds = 0x0001;
            
            // update the LEDs
            BOARD_LEDS = next_leds;
        }
    }
    
    // compute the crc
    BOARD_LEDS = 0x00AA;
    crc kern_crc = crcFast( (unsigned char *)(RAM_KERNEL_START), KERNEL_LENGTH );
    if( kern_crc == pre_kernel_crc )
    {
        // CRC matched, set LEDs to good, and for now wait
        BOARD_LEDS = 0xAA00;
        while(1);
    }
    else
    {
        // the CRC did not match, set LEDs to bad and stop
        BOARD_LEDS = 0xFFFF;
        while(1);
    }
}
