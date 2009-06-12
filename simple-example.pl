use strict;
use warnings;

package Durations;

sub new {
    bless sub { my $context = shift; return 1; }, shift;
}

package Delays;

sub new {
    bless sub { my $context = shift; return 1; }, shift;
}

package main;

use lib '../perl/lib';
use Score;

print Score->load(<<"...")->render;
---
parts:
    - instrument_number: 1
      end_at: 10
      durations: Durations
      delays: Delays
...
