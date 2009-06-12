package Score;

use strict;
use warnings;

use YAML;
use Part;
use Carp;

use base qw/Class::Accessor/;

Score->mk_accessors(qw/
    parts
    header
    footer
    rendered
/);

=head1 NAME

Score - class representing a Csound score

=head1 SYNOPSIS

Load a Score from YAML, e.g.:

    use Score;

    my $score = Score->load(<<"...");
    ---
    header: >
        f1 0 512 10 1
    parts:
        - instrument_number: 1
          start_at: 0.5
          end_at: 10
          durations: DurationsStreamClass
          delays: DelaysStreamClass
          p_streams:
            4:
                P4StreamClass:
                    some_piece_of_config: 1
                    # etc.
            5: P5StreamClass
    footer: >
        e
    ...

    print $score->render;

=head1 METHODS

=head2 load

Load a score from the supplied YAML string; see example above.

For each of durations, delays and p_streams (all of which are optional, but
without eventually initializing which you won't be able to generate the part in
question), you may supply one of:

* the name of a class to be instantiated; this class's constructor must return
a coderef, which will be invoked with a PartGenerationContext at generation
time (see C<Part>); or,

* a single-entry hashref whose key is a class name (which must construct a
coderef, as above) and whose value is a hashref to be passed to that class's
constructor.

=cut

sub load {
    my ($class, $yaml) = @_;
    my $config = Load($yaml);
    my $score = $class->new({
        header  => $config->{header} ? $config->{header} : '',
        footer  => $config->{footer} ? $config->{footer} : '',
        parts   => []
    });

    if (exists $config->{parts}) {
        foreach my $part_config (@{$config->{parts}}) {
            my ($durations, $delays, $p_streams) =
                delete @$part_config{qw/durations delays p_streams/};

            my $part = new Part($part_config);

            if (defined $durations) {
                $part->durations($class->_initialize_stream($durations));
            }

            if (defined $delays) {
                $part->delays($class->_initialize_stream($delays));
            }

            if (defined $p_streams) {
                while (my ($pfield, $stream_config) = each(%$p_streams)) {
                    $part->p_stream($pfield, $class->_initialize_stream($stream_config));
                }
            }

            push @{$score->parts}, $part;
        }
    }

    return $score;
}

# Class method to initialize a stream. No user-serviceable parts inside!
sub _initialize_stream {
    my ($class, $config) = @_;

    if (ref($config) eq 'HASH') {

        # If $config is a hashref, expect it to be of the form
        # classname:confighash, and pass that confighash to the given class's
        # constructor:

        unless (scalar keys %$config == 1) {
            croak "Invalid config hash supplied; should have a single key and value, but instead we got:\n" . Dumper $config;
        }

        my ($stream_class, $stream_config) = %$config;
        return $stream_class->new($stream_config);
    } elsif (ref($config) eq '') {

        # If $config is a string, assume it's a class, and construct one:
        return $config->new();

    } else {
        # shouldn't happen!
        croak "Something wrong with config; we got:\n" . Dumper $config;
    }
}

=head2 render

Render the score's parts to nicely-formatted text.

=cut

sub render {
    my $self = shift;

    $self->rendered($self->header . "\n");

    foreach (@{$self->parts}) {
        $self->rendered($self->rendered . $_->render);
    }

    $self->rendered($self->rendered . "\n" . $self->footer);

    return $self->rendered;
}

=head1 AUTHOR

Dan Friedman <lamech@soda.orange-carb.org>

=cut

q{

    Jim Tenney always used to stress the importance of not composing by what he
    called the "Hollywood Method": sitting down and hearing the piece in your
    head, note by note, then writing it down, as if you were experiencing it as
    you wrote it.  As far as he was concerned, that method was, first and
    foremost, impractical.  He advocated stepping back and considering the
    piece as a whole, from the point of view of structure. Of course, it always
    comes down to aesthetic decision anyway (you still have to decide which
    structures to use, in excruciating detail); but at least this was a task
    that was *accomplishable*.

};
