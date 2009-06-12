use strict;
use warnings;
use Test::More tests => 8;
use Test::Differences;

use_ok('Part');

our $notes = 0;

sub durations {
    return ++$notes; # a function of note choices
}

sub delays {
    return 0.5; # always the same
}

my $part = new Part({
    instrument_number   => 1,
    start_at            => 0.5, # 0 by default
    end_at              => 10,
    delays      => \&delays,
    durations   => \&durations,
    p_streams         => {

        # a function of time:
        4 => sub { my $context = shift; return $context->now+1 },

        # a function of duration:
        5 => sub { my $context = shift; return 1/($context->istmt->duration) }

    }
});

my $text = $part->render;   # builds i-statements by repeatedly calling
                            # duration, delay and p streams until end_at is
                            # reached, then renders i-statements


isa_ok($part, 'Part');
is($part->instrument_number, 1);
is($part->start_at, 0.5);
is($part->durations, \&durations);
is($part->delays, \&delays);

eq_or_diff($text, <<"...", "Output is as expected");
;p1        p2         p3        p4         p5
i1         0.5        1         1.5        1
i1         2          2         3          0.5
i1         4.5        3         5.5        0.333333333333333
i1         8          4         9          0.25
...

is($part->rendered, $text);
