#!./perl
$| = 1;
print "1..4\n";
require Audio::Play;
print "ok 1\n";
my $dev = new Audio::Play;
print "not " unless ($dev);
print "ok 2\n";
my $r = $dev->rate;
print "not " unless ($r > 0);
print "ok 3\n";
my $au = Audio::Data->new(rate => $r);
$au->tone(440,0.2);
$au->silence(0.2);
$au->noise(0.2);
$dev->play($au);
print "ok 4\n";

