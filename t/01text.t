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

$mobj = XML::Merge->new('Tst4.xml');
ok(defined($mobj));
$mobj->merge('Tst5.xml');
ok(defined($mobj));
#$mobj->write('TstG.xml');
ok(diff($mobj, 'TstG.xml')); # test diff with answer instead of write()

$mobj = XML::Merge->new('Tst4.xml');
ok(defined($mobj));
$mobj->merge('_cres' => 'merg', 'Tst5.xml');
ok(defined($mobj));
#$mobj->write('TstH.xml');
ok(diff($mobj, 'TstH.xml')); # test diff with answer instead of write()

   $mobj = XML::Merge->new('Tst0.xml');
ok(defined($mobj));
my $mob2 = XML::Merge->new('Tst1.xml');
ok(defined($mob2));
$mobj->merge($mob2);
ok(defined($mobj));
ok(diff($mobj, 'TstA.xml')); # test diff with answer instead of write()

   $mobj = XML::Merge->new('Tst0.xml');
$mobj->merge('merge_object' => $mob2);
ok(defined($mobj));
ok(diff($mobj, 'TstA.xml')); # test diff with answer instead of write()

   $mobj = XML::Merge->new('Tst0.xml');
$mobj->merge('xpath_object' => $mob2->{'_xpob'});
ok(defined($mobj));
ok(diff($mobj, 'TstA.xml')); # test diff with answer instead of write()
