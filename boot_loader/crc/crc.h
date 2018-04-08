typedef unsigned char uint8_t;

#define POLYNOMIAL 0xD8  /* 11011 followed by 0's */

/* 16 bit CRC */
typedef unsigned short crc;

#define WIDTH  (8 * sizeof(crc))

#define TOPBIT (1 << (WIDTH - 1))
