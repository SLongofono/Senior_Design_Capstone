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


static void print_char_console( const char my_char )
{
    // wait for last character to be sent out
    while( UART_TX_READY == UART_NOT_READY );
    
    // put the character
    UART_TX_DATA = my_char;
    
    // tell UART to send the character
    UART_TX_SEND = UART_RESET_VALUE;
}

static void print_string_console( const char * my_string )
{
    while( *my_string != '\0' )
    {
        print_char_console( *my_string );
        my_string++;
    }
}

static void print_int_console( int my_int )
{
    int digits[30];
    int index = 0;

    if( my_int < 0 )
    {
        print_char_console('-');
        my_int *= -1;
    }

    if( my_int < 0 )
    {
        return;
    }

    if( my_int == 0 )
    {
        print_char_console( '0' );
        return;
    }

    while( (my_int > 0) && (index < 30) )
    {
        digits[index++] = my_int % 10;
        my_int /= 10;
    }

    while( --index >= 0 )
    {
        print_char_console( ((unsigned char)digits[index]) + '0' );
    }
}

static unsigned char read_char_console( )
{
    unsigned char buffer;
    
    // wait for a character to come in
    while( UART_RX_READY == UART_NOT_READY );
    
    // grab the character
    buffer = UART_RX_DATA;
    
    // tell UART we got the character
    UART_RX_RESET = UART_RESET_VALUE;
    
    return buffer;
}

static int read_input()
{
    unsigned char buffer;
    int num_digits = 0;
    int is_digit = 0;
    int total = 0;
    int read_number;
    
    while( 1 )
    {
        buffer = read_char_console( );
        is_digit = ( buffer >= '0' && buffer <= '9' ) ? 1 : 0;
        
        if( num_digits == 0 )
        {
            if( is_digit )
            {
                num_digits++;
                read_number = (int)(buffer - '0');
                total += read_number;
            }
            else if( buffer == '\n' )
            {
                print_string_console( "Never got 2 digits followed by a newline, try again!!\n\n" );
                return -1;
            }
            else
            {
                print_string_console( "Invalid Character |" );
                print_char_console( buffer );
                print_string_console( "| skipping!!!\n" );
            }
        }
        else if( num_digits == 1 )
        {
            if( is_digit )
            {
                num_digits++;
                read_number = (int)(buffer - '0');
                total *= 10;
                total += read_number;
            }
            else if( buffer == '\n' )
            {
                return total;
            }
            else
            {
                num_digits = 0;
                total = 0;
                print_string_console( "Invalid Character |" );
                print_char_console( buffer );
                print_string_console( "| ignoring previous values!!!\n" );
            }
        }
        else if( num_digits == 2 )
        {
            if( buffer == '\n' )
            {
                return total;
            }
            else
            {
                num_digits = 0;
                total = 0;
                print_string_console( "Invalid Character |" );
                print_char_console( buffer );
                print_string_console( "| ignoring previous values!!!\n" );
            }
        }
    }
}

static int fib( int input )
{
    if( input == 0 )
    {
        return 0;
    }
    else if( input == 1 )
    {
        return 1;
    }
    
    return fib( input - 1 ) + fib( input - 2 );
}

void start( void )
{
    int my_input;
    int my_output;
    
    // initial value incase we never get past here
    unsigned short test_bytes = 0x5A5A;
    BOARD_LEDS = test_bytes;
    
    // print the welcome message
    print_string_console( "!!!FIBONACCI SERVER!!!\n\n" );
    
    while( 1 )
    {
        // prompt user for number
        print_string_console( "Input Value:\n> " );
        
        // get a valid input
        my_input = read_input();
        if( my_input == -1 )
        {
            continue;
        }
        
        // we have a valid input 0 <= n <= 99
        my_output = fib( my_input );
        
        print_string_console( "\nfibonacci sequence at |" );
        print_int_console( my_input );
        print_string_console( "| is |" );
        print_int_console( my_output );
        print_string_console( "|\n\n" );
        
        print_string_console( "Input Another????\n" );
    }
}
