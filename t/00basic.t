use Test;
BEGIN { plan tests => 15 }

use XML::Merge;

my $mobj; ok(1);

sub diff { # test for difference between mem XPath obj && disk XML file
  my $xpob = shift()->{'_xpob'} || return(2);
  my $file = shift(); return(3) unless(defined($file) && -e $file);
  my($root)= $xpob->findnodes('/');
  my $data; open(FILE, "<$file"); $data = join('', <FILE>); close(FILE);
  my $xdat = qq(<?xml version="1.0" encoding="utf-8"?>\n);
  $xdat .= $_->toString() foreach($root->getChildNodes()); chomp($data);
  if($xdat eq $data) { return(1); } # 1 == files same
  else               { return(0); } # 0 == files diff
}

$mobj = XML::Merge->new('filename' => 'Tst0.xml');
ok(defined($mobj));
ok(diff($mobj, 'Tst0.xml'));
$mobj->merge('filename' => 'Tst1.xml');
ok(defined($mobj));
#$mobj->write('filename' => 'TstA.xml');
ok(diff($mobj, 'TstA.xml')); # test diff with answer instead of write()

$mobj = XML::Merge->new('filename' => 'Tst0.xml');
ok(defined($mobj));
$mobj->merge('filename' => 'Tst2.xml');
ok(defined($mobj));
#$mobj->write('filename' => 'TstB.xml');
ok(diff($mobj, 'TstB.xml')); # test diff with answer instead of write()

$mobj = XML::Merge->new('filename' => 'Tst0.xml');
ok(defined($mobj));
$mobj->merge('filename' => 'Tst3.xml');
ok(defined($mobj));
#$mobj->write('filename' => 'TstC.xml');
ok(diff($mobj, 'TstC.xml')); # test diff with answer instead of write()

$mobj = XML::Merge->new('filename' => 'Tst0.xml');
$mobj->merge('filename' => 'Tst1.xml', '_cres' => 'merg');
ok(defined($mobj));
#$mobj->write('filename' => 'TstD.xml');
ok(diff($mobj, 'TstD.xml')); # test diff with answer instead of write()

$mobj = XML::Merge->new('filename' => 'Tst0.xml');
print "The warning below is part of a normal test for warnings.\n";
$mobj->merge('filename' => 'Tst1.xml', '_cres' => 'warn');
ok(defined($mobj));
#$mobj->write('filename' => 'TstE.xml');
ok(diff($mobj, 'TstE.xml')); # test diff with answer instead of write()
