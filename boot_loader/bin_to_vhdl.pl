#!/usr/bin/perl

use warnings;
use strict;
use autodie;

unless ( scalar @ARGV == 4 )
{
    die "Use: ./bin_to_vhdl.pl bin_file_name vhdl_file_name rom_address init_offset\n\n";
}

my_main( $ARGV[0], $ARGV[1], $ARGV[2], $ARGV[3] );

exit 0;

sub my_main
{
    my $bin_file_name  = shift;
    my $vhdl_file_name = shift;
    my $rom_address = shift;
    my $init_offset = shift;
    
    my $bytes = slurp_bin_file( $bin_file_name );
    
    write_vhdl_file( $vhdl_file_name, $bytes, $rom_address, $init_offset );
}

sub write_vhdl_file
{
    my $vhdl_file_name = shift;
    my $bytes = shift;
    my $rom_address = shift;
    my $init_offset = shift;
    
    open my $vhd_fh, '>', $vhdl_file_name
        or die "Could not open vhdl file |$vhdl_file_name| says |$!|\n\n";
    
    foreach my $byte ( @{ $bytes })
    {
        my $string = sprintf "(%d + %d) => x\"%02x\", ", $rom_address, $init_offset++, ord( $byte );
        print $vhd_fh $string;
    }
}

sub slurp_bin_file
{
    my $bin_file_name  = shift;
    my @bytes = ();
    
    open my $bin_fh, '<:raw', $bin_file_name 
        or die "Could not open binary file |$bin_file_name| says |$!|\n\n";
    
    while( 1 )
    {
        my $bytes_read = read $bin_fh, my $new_byte, 1;
        
        if( $bytes_read == 1 )
        {
            push @bytes, $new_byte;
        }
        elsif( $bytes_read == 0 )
        {
            last;
        }
        else
        {
            print "problem reading file, trying again!!!\n";
        }
    }
    
    return \@bytes;
}
