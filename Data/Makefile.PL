use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'     => 'Audio::Data',
    'clean'    => {FILES => "*% *.bak"},
    'OBJECT'   => '$(O_FILES)',
    'dist'     => { COMPRESS => 'gzip -f', SUFFIX => 'gz' },
    'VERSION_FROM'  => 'Data.pm'
);

sub MY::postamble
{
'
Audio.t : Audio.h  mkVFunc

config :: Audio.t 
	@$(NOOP)
';
}

sub MY::xs_c
{
 my $self = shift;
 return $self->MM::xs_c .
'
.SUFFIXES: .t .h 
.h.t :
	$(PERL) mkVFunc $< 
' 
}
