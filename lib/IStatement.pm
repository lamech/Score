package IStatement;

=head1 NAME

IStatement - class representing a single i-statement in a Csound score

=head1 SYNOPSIS

    use IStatement;

    my $istmt = new IStatement({
        instrument_number   => 1,
        onset               => 0.5,
        duration            => 4.32
    });
    $istmt->p(4, 'foo');
    my $text = $istmt->render; # i1 0.5 4.32 foo

=head2 AUTHOR

Dan Friedman <lamech@soda.orange-carb.org>

=cut

use strict;
use warnings;

use base qw/Class::Accessor/;

IStatement->mk_accessors(qw/pfields/);

sub new {
    my ($class, $params) = @_;
    my $self = $class->SUPER::new();

    $self->pfields([]);

    # Need to do this explicitly, because we don't
    # just store incoming values in the $self hash:
    while (my ($k, $v) = each(%$params)) {
        $self->$k($v);
    }

    return $self;
}

sub p {
    my ($self, $index, $value) = @_;

    if (@_ > 2) {
        $self->pfields->[$index-1] = $value;
    } else {
        return $self->pfields->[$index-1];
    }
}

sub render {
    my $self = shift;
    my $string = 'i' . join(' ', @{$self->pfields});

    return $string;
}

sub instrument_number {
    shift->p(1, @_);
}

sub onset {
    shift->p(2, @_);
}

sub duration {
    shift->p(3, @_);
}

sub pfields_for_rendering {
    my $self = shift;
    my $i=0;
    # prepend 'i' to only the first pfield:
    my @fields = map { ($i++ ? '' : 'i') . $_ } @{$self->pfields};
    return \@fields;
}

q{
    I'd like to buy a vowel.
};


