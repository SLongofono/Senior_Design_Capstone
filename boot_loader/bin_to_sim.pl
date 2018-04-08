#!/usr/bin/perl

use warnings;
use strict;
use autodie;

unless ( scalar @ARGV == 2 )
{
    die "Use: ./bin_to_sim.pl bin_file_name gdb_file_name\n\n";
}

my_main( $ARGV[0], $ARGV[1]  );

exit 0;

sub my_main
{
    my $bin_file_name  = shift;
    my $gdb_file_name = shift;
    
    my $bytes = slurp_bin_file( $bin_file_name );
    
    write_gdb_file( $gdb_file_name, $bytes );
}

sub write_gdb_file
{
    my $gdb_file_name = shift;
    my $bytes = shift;
    my $offset = 0;
    
    open my $gdb_fh, '>', $gdb_file_name
        or die "Could not open gdb file |$gdb_file_name| says |$!|\n\n";
    
    foreach my $byte ( @{ $bytes })
    {
        my $string = sprintf "set (p->mmu->sim->mems[0].second).data[%d] = %d\n", $offset++, ord( $byte );
        print $gdb_fh $string;
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
