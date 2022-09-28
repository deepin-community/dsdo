#!/usr/bin/perl -w
#
# Add a compound "m" flag to all word roots not explicitly listed in
# an optional "no_compounds_file". Input from STDIN, output to STDOUT.
#
#  cat munched_wordlist | no-compound_marking.pl <no_compounds_file>
#
# Copyright (C) 2014 Agustin Martin <agmartin@debian.org>
#
# This file is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

use strict;

my $no_compounds_file = shift;
my %no_compounds_list = ();
my $COMPOUNDS;
my $debug;

# Create a list
if ( defined $no_compounds_file && -e "$no_compounds_file" ){
  open ($COMPOUNDS, "< $no_compounds_file")
    or die "no-compound-marking: Could not open \"$no_compounds_file\" for read\n";
  while (<$COMPOUNDS>){
    chomp;
    $no_compounds_list{$_}++;
  }
  close $COMPOUNDS;
}

print STDERR "Elements:", scalar %no_compounds_list, "\n",
  join(', ', sort keys %no_compounds_list), "\n"
  if $debug;

# Add compound flag unless in no_compounds_list
while (<>){
  chomp;
  my ( $root, $flags ) = split ('/',$_);

  # Cleanup previous m flags
  if ( $flags ){
    print STDERR "Root: $root, Flags: $flags\n"
      if $debug;
    $flags =~ s/m//;
  }
  $flags = "" unless $flags;

  # Add compound m flag if appropriate
  $flags .= "m" unless ( defined $no_compounds_list{$root} );

  # Print results
  if ( length($flags) != 0  ){
    print STDERR "out: ",join('/',($root,$flags)),"\n"
      if $debug;
    print join('/',($root,$flags)),"\n";
  } else {
    print STDERR "out: ",$root,"\n"
	if $debug;
    print $root,"\n";
  }
}
