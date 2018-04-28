#define BOARD_LEDS *((volatile unsigned short *)(0x98000000))

#define UART_BASE 0x98010000
#define UART_RX_DATA  *((volatile unsigned char *)(UART_BASE + 0))
#define UART_RX_READY *((volatile unsigned char *)(UART_BASE + 1))
#define UART_RX_RESET *((volatile unsigned char *)(UART_BASE + 2))
#define UART_TX_DATA  *((volatile unsigned char *)(UART_BASE + 3))
#define UART_TX_READY *((volatile unsigned char *)(UART_BASE + 4))
#define UART_TX_SEND  *((volatile unsigned char *)(UART_BASE + 5))

#define UART_NOT_READY   ((unsigned char) 0)
#define UART_RESET_VALUE ((unsigned char) 1)

static void print_to_console( const char * my_string )
{
    while( *my_string != '\0' )
    {
        // wait for last character to be sent out
        while( UART_TX_READY == UART_NOT_READY );

        // put the character
        UART_TX_DATA = *my_string;

        // tell UART to send the character
        UART_TX_SEND = UART_RESET_VALUE;
        
        my_string++;
    }
}

void start( void )
{
    unsigned char buffer;
    
    // initial value incase we never get past here
    unsigned short total_bytes = 0x0001;
    BOARD_LEDS = total_bytes;
    
    // print the welcome message
    print_to_console( "!!!ECHO SERVER!!!\n" );
    
    while( 1 )
    {
        // wait for a character to come in
        while( UART_RX_READY == UART_NOT_READY );
        
        // grab the character
        buffer = UART_RX_DATA;
        
        // tell UART we got the character
        UART_RX_RESET = UART_RESET_VALUE;
        
        // update LEDs
        total_bytes++;
        BOARD_LEDS = total_bytes;
        
        // wait for last character to be sent out
        while( UART_TX_READY == UART_NOT_READY );

        // put the character
        UART_TX_DATA = buffer;

        // tell UART to send the character
        UART_TX_SEND = UART_RESET_VALUE;
    }
}
