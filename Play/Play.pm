package Audio::Play;

use AutoLoader;
require Audio::Data;

# DynaLoader is for derived classes to simplify auto-generated sub-class.pm

require DynaLoader;
@ISA = qw(AutoLoader DynaLoader);

require "Audio/Play/$^O.pm";

sub new
{
 my $class = shift;
 return "Audio::Play::$^O"->new(@_);
}

sub rate 
{ 
 my $self = shift;
 croak("Cannot set rate") if @_;
 return 8000; 
}

sub DESTROY 
{ 
}

sub speaker
{
 my $self = shift;
 carp("Cannot set speaker") if @_;
 return 1;
}

sub headphone
{
 my $self = shift;
 carp("Cannot set headphone") if @_;
 return 0;
}

sub volume 
{
 my $self = shift;
 carp("Cannot set volume") if @_;
 return 1.0;
}

sub flush
{

}

1;
__END__


