use Config;

use ExtUtils::MakeMaker;

sub try_compile
{
 my $file  = shift;
 # print "$Config{'cc'} $Config{'ccflags'} $file\n";
 my $msgs  = `$Config{'cc'} $Config{'ccflags'} $file 2>&1`;
 my $ok = ($? == 0);
 unlink('a.out') if (-f 'a.out');
 return $ok;
}

warn "Testing for Network Audio Server (NAS)\n";

if (try_compile("-c ../config/Net.c"))
 {
  WriteMakefile(
      'NAME'     => 'Audio::Play::Net',
      'LIBS'     => [q[-L/usr/local/lib -laudio -lX11 -lsocket -lnsl -lm]],
      'clean'    => {FILES => "*% *.bak"},
      'OBJECT'   => '$(O_FILES)',
      'TYPEMAPS' => [q[../../Data/typemap]],
      'dist'     => { COMPRESS => 'gzip -f', SUFFIX => 'gz' },
      'VERSION_FROM'  => 'Net.pm'
  );
 }
else
 {
  warn "Cannot build Audio::Play::Net - NAS not present\n";
  open(M,">Makefile") || die "Cannot open Makefile:$!";
  print M "# Dummy Makefile\nall :\n\nclean :\n\trm -f Makefile\n";
  close(M);
 }



