package Audio::Data;

# PerlIO calls used in .xs code
require 5.00302;

require DynaLoader;
@ISA = qw(DynaLoader);
$VERSION = "1.000";

use overload
    'fallback' => 1,
    '""'   => 'asString',
    'bool' => 'samples',
    '0+'   => 'samples',
     '+'   => 'add',
     '~'   => 'conjugate',
     '-'   => 'sub',
     '*'   => 'mpy',
     '/'   => 'div',
     '.'   => 'concat',
     '@{}' => 'getarray';

sub PI () { 3.14159265358979323846 }

bootstrap Audio::Data $VERSION;

sub new
{
 my $class = shift;
 my $obj   = bless $class->create,$class;
 while (@_)
  {
   my $method = shift;
   my $val    = shift;
   $obj->$method($val);
  }
 return $obj;
}

sub getarray
{
 my ($self) = @_;
 my @a;
 tie @a,ref $self,$self;
 return \@a;
}

sub TIEARRAY
{
 my ($class,$audio) = @_;
 return $audio;
}

sub asString
{
 my ($self) = shift;
 my $comment = $self->comment;
 my $val = ref($self).sprintf(" %.3gs \@ %dHz",$self->duration,$self->rate);
 $val .= ":$comment" if defined $comment;
 return $val;
}

sub fft
{
 my ($au,$N,$radix) = @_;
 $radix = 2 if @_ < 3;
 # XS modifies in place to mess with a copy and return that
 $au = $au->clone if defined wantarray;
 $au->length($N);
 my $method = "r${radix}_fft";
 $au->$method();
 return $au;
}

sub ifft
{
 my ($au,$N,$radix) = @_;
 $radix = 2 if @_ < 3;
 $au = $au->clone if defined wantarray;
 $au->length($N);
 my $method = "r${radix}_ifft";
 $au->$method();
 return $au;
}


1;

__END__

=head1 NAME 

Audio::Data - module for representing audio data to perl

=head1 SYNOPSIS

  use Audio::Data;
  my $audio = Audio::Data->new(rate => , ...);
  
  $audio->method(...)
  
  $audio OP ...

=head1 DESCRIPTION 

B<Audio::Data> represents audio data to perl in a fairly compact and efficient 
manner using C via XS to hold data as a C array of C<float> values.
The use of C<float> avoids many issues with dynamic range, and typical C<float>
has 24-bit mantissa so quantization noise should be acceptable. Many machines
have floating point hardware these days, and in such cases operations on C<float>
should be as fast or faster than some kind of "scaled integer". 

Nominally data is expected to be between +1.0 and -1.0 - although only
code which interacts with outside world (reading/writing files or devices)
really cares.

It can also represent elements (samples) which are "complex numbers" which 
simplifies many Digital Signal Processing methods.

=head2 Methods

The interface is object-oriented, and provides the methods below.

=over 4

=item $audio = Audio::Data->new([method => value ...])

The "constructor" - takes a list of method/value pairs and calls 
$audio->I<method>(I<value>) on the object in order. Typically first "method"
will be B<rate> to set sampling rate of the object.

=item $rate = $audio->rate

Get sampling rate of object.

=item $audio->rate($newrate)

Set sampling rate of the object. If object contains existing data it is 
re-sampled to the new rate. (Code to do this was derived from a now dated
version of C<sox>.)

=item $audio->comment($string)

Sets simple string comment associated with data.

=item $string = $audio->comment

Get the comment 

=item $time = $audio->duration

Return duration of object (in seconds).

=item $time = $audio->samples

Return number of samples in the object.

=item @data = $audio->data

Return data as list of values - not recommended for large data.

=item $audio->data(@data)

Sets elements from @data.

=item $audio->length($N)

Set number of samples to I<$N> - tuncating or padding with zeros (silence).

=item ($max,$min) = $audio->bounds([$start_time[,$end_time]])

Returns a list of two values representing the limits of the values 
between the two times if $end_time isn't specified it defaults to 
the duration of the object, and if start time isn't specified it defaults 
to zero.

=item $copy = $audio->clone

Creates copy of data carrying over sample rate and complex-ness of data.

=item $slice = $audio->timerange($start_time,$end_time);

Returns a time-slice between specified times.

=item $audio->Load($fh)

Reads Sun/NeXT .au data from the perl file handle (which should 
have C<binmode()> applied to it.)

This will eventually change - to allow it to load other formats
and perhaps to return list of Audio::Data objects to represnt 
multiple channels (e.g. stereo).

=item $audio->Save($fh[,$comment])

Write a Sun/NeXT .au file to perl file handle. I<$comment> if specified 
is used as the comment.

=item $audio->tone($freq,$dur,$amp);

Append a sinusoidal tone of specified freqency (in Hz) and duration (in seconds),
and peak amplitude $amp.

=item $audio->silence($dur);

Append a period of 0 value of specified duration.

=item $audio->noise($dur,$amp);

Append burst of (white) noise of specified duration and peak amplitude.

=item $window = $audio->hamming($SIZE,$start_sample[,$k])

Returns a "raised cosine window" sample of I<$SIZE> samples starting at specified 
sample. If I<$k> is specified it overrides the default value of 0.46 
(e.g. a value of 0.5 would give a Hanning window as opposed to a Hamming window.)

  windowed = ((1.0-k)+k*cos(x*PI))

=item $freq = $audio->fft($SIZE)

=item $time = $freq->ifft($SIZE);

Perform a Fast Fourier Transform (or its inverse). 
(Note that in general result of these methods have complex numbers 
as the elements. I<$SIZE> should be a power-of-two (if it isn't next larger 
power of two is used). Data is padded with zeros as necessary to get to 
I<$SIZE> samples.

=item @values = $audio->amplitude([$N[,$count]])

Return values of amplitude for sample $N..$N+$count inclusive.
if I<$N> is not specified it defaults to zero.
If I<$count> is not specified it defaults to 1 for scalar context
and rest-of-data in array context.

=item @values = $audio->dB([$N[,$count]])

Return amplitude - in deci-Bells.
(0dB is 1/2**15 i.e. least detectable value to 16-bit device.)
Defaults as for amplitude.

=item @values = $audio->phase([$N [,$count]])

Return Phase - (if data are real returns 0).
Defaults as for amplitude.

=item $diff = $audio->difference

Returns the first difference between successive elements of the data - 
so result is one sample shorter. This is a simple high-pass filter and 
is much used to remove DC offsets.


=item $Avalues = $audio->lpc($NUM_POLES,[$auto [,$refl]])

Perform Linear Predictive Coding analysis of $audio and return coefficents
of resulting All-Pole filter. 0'th Element is I<not> a filter coefficent
(there is no A[0] in such a filter) - but is a measure of the "error"
in the matching process. I<$auto> is an output argument and returns 
computed autocorrelation. I<$refl> is also output and are so-called
reflection coefficents used in "lattice" realization of the filter.
(Code for this lifted from "Festival" speech system's speech_tools.)

=item $auto = $audio->autocorrelation($LENGTH)

Returns an (unscaled) autocorrelation function - can be used to cause
peaks when data is periodic - and is used as a precursor to LPC analysis.


=back 4


=head2 Operators

B<Audio::Data> also provides overloaded operators where the B<Audio::Data> object 
is treated as a vector in a mathematical sense. The other operand of an 
operator can either be another B<Audio::Data> or a scalar which can be 
converted to a real number. 

=over 4 

=item $audio * $scalar 

Multiply each element by the scalar - e.g. adjust "volume".

=item $audio * $another

Is ear-marked to perform convolution but does not work yet. 

=item $audio / $scalar

Divide each element by the scalar - e.g. adjust "volume".

=item $scalar / $audio 

Return a new object with each element being result of dividing scalar
by the corresponding element in original I<$audio>.

=item $audio + $scalar

Add $scalar to each element - i.e. apply a DC offset.

=item $audio + $another

Adds element-by-element - i.e. mixes them.

=item $audio - $scalar

Subtract $scalar from each element.

=item $audio - $another

Subtracts element-by-element 

=item $audio . $scalar

Append a new element. (Perhaps if scalar is a string it should
append to comment instead - but what is a string ... )

=item $audio . $another

Appends the two objects to get a longer one.

=item $audio . [ @things ]

Appends contents of array to the object, the contents can 
be scalars, Audio::Data objects or (as it recurses) refrences to arrays.

=item $audio->[$N] 

access a sample.

=item ~$audio 

Takes complex conjugate 


=back 4 

=head1 SEE ALSO 

See code for C<tkscope> to see most of the above in use.

=head1 BUGS AND MISFEATURES

Currently only a single channel can be represented - which is fine for 
speech applications I am using it for, but precludes using it for music.

Still lack Windows .wav file support.

=head1 AUTHOR

Nick Ing-Simmons E<lt>Nick@Ing-Simmons.netE<gt>

=cut 

