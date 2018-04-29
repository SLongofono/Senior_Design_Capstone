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
    my $cur_pos = 0;
    my $total_string = "";
    
    open my $vhd_fh, '>', $vhdl_file_name
        or die "Could not open vhdl file |$vhdl_file_name| says |$!|\n\n";
    
    foreach my $byte ( @{ $bytes })
    {
        if( $cur_pos == 0 )
        {
            $cur_pos = 1;
            $total_string = sprintf "%02x", ord( $byte );
        }
        elsif( $cur_pos == 1 )
        {
            $cur_pos = 2;
            $total_string = sprintf "%02x%s", ord( $byte ), $total_string;
        }
        elsif( $cur_pos == 2 )
        {
            $cur_pos = 3;
            $total_string = sprintf "%02x%s", ord( $byte ), $total_string;
        }
        else
        {
            $cur_pos = 0;
            $total_string = sprintf "%02x%s", ord( $byte ), $total_string;
            my $string = sprintf "(%d + %d) => x\"%s\", ", $rom_address, $init_offset++, $total_string;
            print $vhd_fh $string;
        }
    }
    
    if( $cur_pos != 0 )
    {
        if( $cur_pos == 1 )
        {
            $total_string = sprintf "000000%s", $total_string;
        }
        elsif( $cur_pos == 2 )
        {
            $total_string = sprintf "0000%s", $total_string;
        }
        else
        {
            $total_string = sprintf "00%s", $total_string;
        }
        
        my $string = sprintf "(%d + %d) => x\"%s\", ", $rom_address, $init_offset++, $total_string;
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
