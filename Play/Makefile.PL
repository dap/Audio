use ExtUtils::MakeMaker;
use Config;

$VERSION = '0.002';

%define = ();
@libs   = ();
@clean  = qw(*% *.bak);
@deps   = "subdirs :: config\n";

sub MMutil::check_headers
{
 my $inc = $Config{'usrinc'};
 while (@_)
  {
   my $hdr = shift;
   my $var = "HAVE_\U$hdr";
   $var =~ s,[/.],_,g;
   if (-f "$inc/$hdr")
    {
     $define{$var} = 1;
    }
  }
}

sub translate_osname
{
 my ($src,$dst) = @_;
 open(SRC,"<$src") || die "Cannot open $src:$!";
 open(DST,">$dst") || die "Cannot open $dst:$!";
 while (<SRC>)
  {
   s/#OSNAME#/$^O/g;
   print DST;
  }
 close(DST);
 close(SRC);
 push(@clean,$dst);
 push(@deps,"$dst : $src\n\t\$(PERL) -pe 's/#OSNAME#/$^O/g' $src > $dst\n");
 push(@deps,"config :: $dst\n");
}

my $driver = 'dummy';

foreach ($^O)
 {
  if (/^(linux|freebsd)$/i)
   {
    $driver = 'linux';
   }
  elsif (/^(sunos|solaris)$/i)
   {
    $driver = 'sun';
   }
  elsif (/^hpux$/i)
   {
    $driver = 'hpux';
   }
  elsif (/^sgi$/i)
   {
    $driver = 'sgi';
   }
  elsif (/^next$/i)
   {
    $driver = 'next';
   }
 }

mkdir($^O,0777) unless (-d $^O);
translate_osname("config/${driver}.xs","$^O/$^O.xs");
my $pm = (-f "config/${driver}.pm") ? "config/${driver}.pm" : "config/generic.pm";
translate_osname($pm,"$^O/$^O.pm");

 
if (-f "config/${driver}.cfg")
 {
  eval { require "config/${driver}.cfg" };
  die "config/${driver}.cfg $@" if $@;
 }

my $define = join(' ',map("-D$_",keys %define));
my $libs   = join(' ',@libs);

open(PL,">$^O/Makefile.PL") || die "Cannot open $^O/Makefile.PL:$!";
push(@clean,"$^O/Makefile.PL");
print PL "use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'     => 'Audio::Play::$^O',
    'DEFINE'   => '$define',
    'LIBS'     => [ $libs ],
    'clean'    => {FILES => '*% *.bak'},
    'OBJECT'   => '\$(O_FILES)',
    'VERSION_FROM' => '../../Data/Data.pm',
    'TYPEMAPS' => [q[../../Data/typemap]]
);
";
close(PL);


WriteMakefile(
    'NAME'     => 'Audio::Play',
    'clean'    => {FILES => join(' ',@clean)},
    'dist'     => { COMPRESS => 'gzip -f', SUFFIX => 'gz' },
    OBJECT     => '',
    'VERSION_FROM' => '../Data/Data.pm',
    'linkext'  => { LINKTYPE => ''}
);

sub MY::postamble
{
 return join('',@deps);
}

