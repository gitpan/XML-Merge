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
$mobj->prune('xpath_loc' => '/root/kid1');
ok(defined($mobj));
#$mobj->write('filename' => 'TstF.xml');
ok(diff($mobj, 'TstF.xml')); # test diff with answer instead of write()

$mobj = XML::Merge->new('filename' => 'Tst6.xml');
ok(defined($mobj));
$mobj->prune('xpath_loc' => '/t/u/v'); # someday this shouldn't mess doc order
ok(defined($mobj));
$mobj->tidy();
ok(defined($mobj));
#$mobj->write('filename' => 'TstI.xml');
ok(diff($mobj, 'TstI.xml')); # test diff with answer instead of write()

$mobj = XML::Merge->new('filename' => 'Tst6.xml');
ok(defined($mobj));
$mobj->prune('xpath_loc' => '/t/u[2]');
ok(defined($mobj));
$mobj->tidy();
ok(defined($mobj));
#$mobj->write('filename' => 'TstJ.xml');
ok(diff($mobj, 'TstJ.xml')); # test diff with answer instead of write()

$mobj = XML::Merge->new('filename' => 'Tst6.xml');
$mobj->prune('xpath_loc' => '/v[@name="deux"]');
ok(defined($mobj));
$mobj->tidy();
ok(defined($mobj));
#$mobj->write('filename' => 'TstK.xml');
ok(diff($mobj, 'TstK.xml')); # test diff with answer instead of write()
