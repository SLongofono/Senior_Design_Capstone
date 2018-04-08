#!/usr/bin/perl

use strict;
use warnings;

require 'Image.pm';

print "this works!!\n\n";

foreach my $byte ( @Image::bytes )
{
    print "$byte\n";
}

exit 0;
