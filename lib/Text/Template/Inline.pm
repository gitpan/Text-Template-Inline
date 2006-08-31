package Text::Template::Inline;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/ render /;

use Carp qw/ croak /;
use Scalar::Util qw/ blessed reftype /;

our $VERSION = '0.12';

# used to specify the separator for key paths (default is period)
our $KEY_PATH_SEP = qr/\./;

sub render ($$) {
    my ($data, $template) = @_;
    return $template unless $template;
    $template =~ s/(\{(\w[$KEY_PATH_SEP\w]*)\})/_traverse_ref_with_path($data,$2,$1)/ge;
    return $template;
}

#
# _traverse_ref_with_path ( $theref, $path, $default )
#
# This function dissects a period-delimited path of keys and follows them,
# traversing $theref. If the appropriate field exists at each level the final
# value is returned. If any field is not found, $default is returned.
#
sub _traverse_ref_with_path {
    my ($theref, $path, $default) = @_;
    my @keys = split $KEY_PATH_SEP, $path;
    my $ref = $theref;
    for my $key (@keys) {
        no warnings 'uninitialized'; # for comparisons involving a non-ref $ref
        if (blessed $ref) {
            return $default unless $ref->can($key);
            $ref = $ref->$key();
        }
        elsif (reftype $ref eq 'HASH') {
            return $default unless exists $ref->{$key};
            $ref = $ref->{$key};
        }
        elsif (reftype $ref eq 'ARRAY') {
            return $default unless $key =~ /^\d+$/ and exists $ref->[$key];
            $ref = $ref->[$key];
        }
        else {
            local $Carp::CarpLevel = 2;
            croak "unable to use scalar '$theref' as template data";
        }
    }
    return $ref;
}

1;
__END__

=head1 NAME

Text::Template::Inline - Quick and easy formatting of data

=head1 SYNOPSIS

 use Text::Template::Inline;

 # yields "\nReplace things and stuff.\n"
 render {
    foo => 'things',
    bar => 'stuff',
 }, <<'END';
 Replace {foo} and {bar}.
 END

 # yields "Three Two One Zero"
 render [qw/ Zero One Two Three /], '{3} {2} {1} {0}';

 # for a blessed $obj that has id and name accessors:
 render $obj, '{id} {name}';

 # a "fat comma" can be used as syntactic sugar:
 render $obj => '{id} {name}';

 # it's also possible to traverse heirarchies of data,
 # even of different types.
 # the following yields "one two three"
 render {
    a => { d => 'one' },
    b => { e => 'two' },
    c => { f => [qw/ zero one two three /], },
 } => '{a.d} {b.e} {c.f.3}';

 # you can use a different key path separator as well,
 # the following also yields "one two three"
 local $Text::Template::Inline::KEY_PATH_SEP = qr/::/;
 render {
    a => { d => 'one' },
    b => { e => 'two' },
    c => { f => { g => 'three' }, },
 } => '{a::d} {b::e} {c::f::g}';

=head1 DESCRIPTION

This module exports a fuction C<render> that substitutes identifiers
of the form C<{key}> with corresponding values from a hashref, listref
or blessed object.

The implementation is very small and simple. The small amount of code
is easy to review, and the resource cost of using this module is minimal.

=head2 EXPORTED FUNCTION

There is only one function defined by this module. It is exported
automatically.

=over

=item render ( $data, $template )

Each occurrence in C<$template> of the form C<{key}> will be substituted
with the corresponding value from C<$data>. If there is no such value,
the substitution will not be performed. The resulting string is returned.

If C<$data> is a blessed object, the keys in C<$template> correspond to
accessor methods. These methods should return a scalar when called without
any arguments (other than the reciever).

if C<$data> is a hash reference, the keys in C<$template> correspond to the keys
of that hash. Keys that contain non-word characters are not replaced.

if C<$data> is a list reference, the keys in C<$template> correspond to the
indices of that list. Keys that contain non-digit characters are not replaced.

=back

=head1 BUGS

If you find a bug in Text::Template::Inline please report it to the author.

=head1 AUTHOR

 Zack Hobson <zhobson@gmail.com>

=cut

# vi:ts=4 sts=4 et bs=2:
