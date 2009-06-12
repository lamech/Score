use strict;
use warnings;
use Test::More tests => 6;
use Test::Differences;

use lib 't/testlib';
use_ok("MyPiece");

use_ok("Score");

my $score = Score->load(<<"...");
---
header: >
    f1 0 512 10 1
parts:
    - instrument_number: 1
      start_at: 0.5
      end_at: 10
      durations: Durations
      delays: Delays
      p_streams:
        4:
            P4Stream:
                value_to_add: 1
                # etc.
        5: P5Stream
footer: >
    e
...

isa_ok($score, 'Score');
my $part = $score->parts->[0];
isa_ok($part, 'Part');
my $text = $score->render;

eq_or_diff($text, <<"...", "Output is as expected");
f1 0 512 10 1

;p1        p2         p3        p4         p5
i1         0.5        1         1.5        1
i1         2          2         3          0.5
i1         4.5        3         5.5        0.333333333333333
i1         8          4         9          0.25

e
...

is($score->rendered, $text);
