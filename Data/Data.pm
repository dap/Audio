package Audio::Data;

# PerlIO calls used in .xs code
require 5.00302;  

require DynaLoader;
@ISA = qw(DynaLoader);
$VERSION = "0.005";

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

1;
