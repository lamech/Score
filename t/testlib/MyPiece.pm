package Durations;
our $notes = 0;
sub new {
    bless sub { return ++$notes }, shift;
}

package Delays;
sub new {
    bless sub { return 0.5 }, shift;
}

package P4Stream;
sub new {
    my ($class, $config) = @_;
    bless sub {
        my $context = shift;
        # a function of time:
        return $context->now + $config->{value_to_add};
    }, $class;
}

package P5Stream;
sub new { bless sub {
        my $context = shift;
        # a function of duration:
        return 1/($context->istmt->duration);
    }, shift;
}

1;
