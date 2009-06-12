=head1 NAME

Part - class representing a single part in a Csound score

=head1 SYNOPSIS

    use Part;

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


The preceding would produce the following in $text:

    ;p1        p2         p3        p4        p5
    i1         0.5        1         1.5       1
    i1         2          2         3         0.5
    i1         4.5        3         5.5       0.333333333333333
    i1         8          4         9         0.25

=head1 GENERATION OF I-STATEMENTS

Csound i-statements are generated in sequence for the Part. The generation
process has the following steps:

1. first, a duration is selcted by invocation of the duration coderef;

2. then, an IStatement object is created;

3. then, any coderefs in the Part's p_streams array are invoked;

4. finally, the delay coderef is invoked to select the delay before the next i-statement.

Every coderef invocation is supplied a PartGenerationContext as its only parameter.

=cut

use strict;
use warnings;

package Part;

use base qw/Class::Accessor/;

use Carp;
use Text::Table;

use IStatement;

Part->mk_accessors(qw/
    instrument_number
    start_at
    end_at
    durations
    delays
    p_streams
    i_statements
    rendered
    generation_context
/);

=head1 ATTRIBUTES

Part objects have the following attributes; Class::Accessor is used to define
them, so the usual conventions apply: $mypart->foo() gets the attribute value,
whereas $mypart->foo($newvalue) sets it to $newvalue.

=head2 instrument_number

i-number in the csound score.

=head2 start_at

Time (in seconds) at which to start generation of i-statements.

=head2 end_at

Time at which to end generation of i-statements. Will probably not be precisely
adhered to; once a duration is selected that makes the 'current' time equal to
I<or greater than> the 'end' time, generation will terminate.

=head2 rendered

Convenience attribute where a string representation of the part is stored
after render() is called.

=head2 i_statements

Arrayref of generated IStatement objects after generation.

=head2 generation_context

PartGenerationContext object for storing contextual state during part generation.

=head2 durations

A coderef that, when repeatedly evaluated with the generation context passed
in, will return a stream of durations (in seconds).

=head2 delays

A coderef that, when repeatedly evaluated with the generation context passed
in, will return a stream of delay times (in seconds).

=head2 p_streams

A hashref of coderefs that, when repeatedly evaluated with the generation
context passed in, will return a stream of values for the other p-fields. Use
the p-field numbers as the keys, e.g.:

    $part->p_streams({
        4 => \&my_p4_func,
        5 => \&my_p5_func,
        # ...etc...
    });

B<NB:> using p-field values less than 4 will I<not> work here. I'm lazy, and/or
it wouldn't make sense; for the duration stream, use $part->durations, etc.

=head2 p_stream($number[, \&code])

A special accessor that takes a number as an argument; will get the p-stream
stored for the given field number, or set it if a coderef argument is also supplied.

=cut

sub p_stream {
    my ($self, $key, $code) = @_;

    if (@_ == 2) {
        return $self->p_streams->{$key};
    } elsif (@_ > 2) {
        if ($key =~ /\D/) {
            carp "Attempt to store a p-stream for a non-integer p-field value: '$key' -- ignoring.";
            return;
        }
        if ($key < 4) {
            carp "Attempt to store a p-stream for a p-field value less than 4: '$key' -- ignoring.";
            return;
        }
        $self->p_streams->{$key} = $code;
    }
}

=head1 METHODS

=head2 new

The standard Class::Accessor constructor; takes an optional hashref that can
specify any of the Part object's attributes.

=cut

sub new {
    my ($class, $params) = @_;
    my $self = $class->SUPER::new($params);

    $self->start_at(0) unless defined $self->{start_at};
    $self->i_statements([]) unless defined $self->{i_statements};
    $self->p_streams({}) unless defined $self->{p_streams};
    $self->generation_context(new PartGenerationContext()) unless defined $self->{generation_context};

    return $self;
}

# Method to do the actual part generation -- no user-serviceable parts inside!
sub _generate {
    my $self = shift;
    croak "Can't generate() with no end_at defined!" unless defined $self->end_at;
    croak "Can't generate() with end_at less than start_at!"
        unless $self->end_at >= $self->start_at;
    croak "Can't generate() with no durations!"
        unless defined $self->durations;
    croak "Can't generate() with no delays!"
        unless defined $self->delays;
    croak "Can't generate() with no instrument_number!!"
        unless defined $self->instrument_number;

    my $now = $self->start_at;
    $self->i_statements([]);
    my $context = $self->generation_context;

    while ($now < $self->end_at) {
        $context->now($now);
        $context->part($self);

        my $istmt = new IStatement({
            instrument_number => $self->instrument_number,
            onset => $now,
            duration => $self->durations->($context)
        });

        $context->istmt($istmt);

        while (my ($pfield, $stream) = each %{$self->p_streams}) {
            $istmt->p($pfield, $stream->($context));
        }

        push @{$self->i_statements}, $istmt;
        my $delay = $self->delays->($context);
        $context->delay($delay);
        $now += $istmt->duration + $delay;
    }
}

=head2 render

Invoke the generation process to produce IStatement objects, then render them
in nicely-formatted text. See SYNOPSIS, above, for an example.

=cut

sub render {
    my $self = shift;
    my $text = '';

    $self->_generate;
    my @statement_data = map { $_->pfields_for_rendering } @{$self->i_statements};
    my $i=0;

    # Prepend ';' (comment marker) to only the first pfield name:
    # (NB: assuming all statement data arrays are of the same length!)
    my @title = map {($i ? '' : ';') . 'p' . ++$i, \(' ' x 8)} @{$statement_data[0]};

    my $tb = Text::Table->new(@title);
    $tb->load(@statement_data);

    # I love you Text::Table... but I hate your trailing whitespace:
    my @lines = map { chomp; s/\s+$//; $_ } $tb->table();

    $self->rendered(join("\n", @lines) . "\n");
    return $self->rendered;
}

=head1 PartGenerationContext

Object passed to the various stream invocations as a part is generated. Here
are its attributes:

=head2 now

The "current" time (as of the end of the last delay).

=head2 part

The Part object being generated.

=head2 istmt

The most-recently generated IStatement (during duration selection, this is the
I<previous> IStatement object, since the next one hasn't been constructed yet).
p-fields may be accessed via this object as they are generated.

=head2 delay

The most-recently generated delay, in seconds.

=cut

package PartGenerationContext;

use base qw/Class::Accessor/;

PartGenerationContext->mk_accessors(qw/
    now
    part
    istmt
    delay
/);


1;

q{
    "Let the sounds alone, Karlheinz--don't push them."
    "Not even a little bit?"
        --Morton Feldman
};

