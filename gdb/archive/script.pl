#!/usr/bin/perl

use strict;
use warnings;
use autodie;

open my $old_fh, '<:raw', 'test.o';
open my $new_fh, '>:raw', 'new_test.o';
open my $instr_fh, '<:raw', 'test_instr';

my $counter = 0;
my @instr_bytes = ();

while( 1 )
{
    my $bytes_read = read $instr_fh, my $bytes, 1;
    if( $bytes_read == 1 )
    {
        push @instr_bytes, $bytes;
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

while( 1 )
{
    my $bytes_read = read $old_fh, my $bytes, 1;
    
    if( $bytes_read == 1 )
    {
        if( $counter == 71 ){ print $new_fh $instr_bytes[0] ;}
        elsif( $counter == 72 ){ print $new_fh $instr_bytes[1] ;}
        elsif( $counter == 73 ){ print $new_fh $instr_bytes[2] ;}
        elsif( $counter == 74 ){ print $new_fh $instr_bytes[3] ;}
        else
        {
            print $new_fh $bytes;
        }
    }
    elsif( $bytes_read == 0 )
    {
        last;
    }
    else
    {
        print "problem reading file, trying again!!!\n";
    }
    
    $counter++;
}

print "This works\n\n";

exit 0;

