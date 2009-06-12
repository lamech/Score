use strict;
use warnings;
use Test::More tests => 9;
use Test::Differences;

use_ok('IStatement');

my $istmt = new IStatement({
    instrument_number   => 1,
    onset               => 0.5,
    duration            => 4.32
});
$istmt->p(4, 'foo');
my $text = $istmt->render; # i1 0.5 4.32 foo

isa_ok($istmt, 'IStatement');
is($istmt->instrument_number, 1);
is($istmt->onset, 0.5);
is($istmt->duration, 4.32);
is($istmt->p(3), 4.32);
is($istmt->p(4), 'foo');
is($istmt->render, 'i1 0.5 4.32 foo');
is_deeply($istmt->pfields_for_rendering, [qw/i1 0.5 4.32 foo/]);


