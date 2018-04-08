#!/usr/bin/perl

use strict;
use warnings;
use autodie;

my @instr_bytes = ();

my $state = \&first_byte;

foreach my $byte ( @ARGV )
{
    $byte = confirm_byte($byte);
    
    $state->($byte);
}

sub last_byte
{
    my $byte = shift;
    
    #print "byte is $byte\n";
    
    push @instr_bytes, $byte;
    
    add_instruction_to_file();
    print_instruction();
    
    $state = \&first_byte;
}

sub byte_3
{
    my $byte = shift;
    
    #print "byte 3 is $byte\n";
    
    push @instr_bytes, $byte;
    
    $state = \&last_byte;
}

sub byte_2
{
    my $byte = shift;
    
    #print "byte 2 is $byte\n";
    
    push @instr_bytes, $byte;
    
    $state = \&byte_3;
}

sub first_byte
{
    my $byte = shift;
    
    #print "byte is $byte\n";
    
    @instr_bytes = ();
    push @instr_bytes, $byte;
    
    if( ( $byte & 0b11111 ) == 0b11111 )
    {
        die "byte 0 was |$byte|, which is invalid!!!\n\n";
    }
    elsif( ( $byte & 0b11 ) == 0b11 )
    {
        $state = \&byte_2;
    }
    else
    {
        $state = \&last_byte;
    }
}

sub confirm_byte
{
    my $byte = shift;
    
    unless (  ( $byte >= -128 ) && ( $byte <= 127 )  )
    {
        die "byte invalid |$byte|!!!\n\n";
    }
    
    return $byte;
}

sub print_instruction
{
    my @disasm = `/home/babypaw/riscv/riscv/bin/riscv64-unknown-linux-gnu-objdump -d /home/babypaw/riscv/riscv/new_test.o`;
    foreach my $line ( @disasm )
    {
        if( $line =~ /\A\s+7:\s+[0-9a-fA-F]+\s+(.*)/ )
        {
            my $instruction = $1;
            print "$instruction\n";
            last;
        }
    }
}

sub add_instruction_to_file
{
    my $counter = 0;
    
    open my $old_fh, '<:raw', '/home/babypaw/riscv/riscv/test.o';
    open my $new_fh, '>:raw', '/home/babypaw/riscv/riscv/new_test.o';
    
    while( 1 )
    {
        my $bytes_read = read $old_fh, my $old_byte, 1;
        
        if( $bytes_read == 1 )
        {
            if( ( $counter >= 71 ) && ( $counter <= 74 ) && ( scalar @instr_bytes ) )
            {
                my $new_byte = shift @instr_bytes;
                print $new_fh pack( 'c', $new_byte );
            }
            else
            {
                print $new_fh $old_byte;
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
}

#print "This works\n\n";

exit 0;

