use Test;
BEGIN { plan tests => 15 }

use XML::Merge;

my $mobj; ok(1);

sub diff { # test for difference between memory Merge objects
  my $mgob = shift() || return(0);
  my $tstd = shift();   return(0) unless(defined($tstd) && $tstd);
  my($root)= $mgob->findnodes('/');
  my $xdat = qq(<?xml version="1.0" encoding="utf-8"?>\n);
  $xdat .= $_->toString() foreach($root->getChildNodes());
  if($xdat eq $tstd) { return(1); } # 1 == files same
  else               { return(0); } # 0 == files diff
}

my $tst0 = qq|<?xml version="1.0" encoding="utf-8"?>
<root att0="kaka">
  <kid0 />
  <kid1 />
</root>|;
my $tst6 = qq|<?xml version="1.0" encoding="utf-8"?>
<t>
  <u>
    <v>
      <w />
    </v>
  </u>
  <u>
    <v name="deux" />
  </u>
  <u>
    <w>
      <v />
    </w>
  </u>
</t>|;
my $tstF = qq|<?xml version="1.0" encoding="utf-8"?>
<root att0="kaka">
  <kid0 />
  
</root>|;
my $tstI = qq|<?xml version="1.0" encoding="utf-8"?>
<t>
  <u />
  <u />
  <u>
    <w>
      <v />
    </w>
  </u>
</t>|;
my $tstJ = qq|<?xml version="1.0" encoding="utf-8"?>
<t>
  <u>
    <v>
      <w />
    </v>
  </u>
  <u>
    <w>
      <v />
    </w>
  </u>
</t>|;
my $tstK = qq|<?xml version="1.0" encoding="utf-8"?>
<t>
  <u>
    <v>
      <w />
    </v>
  </u>
  <u>
    <v name="deux" />
  </u>
  <u>
    <w>
      <v />
    </w>
  </u>
</t>|;

$mobj = XML::Merge->new($tst0);
ok(defined($mobj));
$mobj->prune('/root/kid1');
ok(defined($mobj));
ok(diff($mobj, $tstF));

$mobj = XML::Merge->new($tst6);
ok(defined($mobj));
$mobj->prune('/t/u/v'); # someday this shouldn't mess doc order
ok(defined($mobj));
$mobj->tidy();
ok(defined($mobj));
ok(diff($mobj, $tstI));

$mobj = XML::Merge->new($tst6);
ok(defined($mobj));
$mobj->prune('/t/u[2]');
ok(defined($mobj));
$mobj->tidy();
ok(defined($mobj));
ok(diff($mobj, $tstJ));

$mobj = XML::Merge->new($tst6);
$mobj->prune('/v[@name="deux"]');
ok(defined($mobj));
$mobj->tidy();
ok(defined($mobj));
ok(diff($mobj, $tstK));
