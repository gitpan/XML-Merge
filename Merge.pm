#!/usr/bin/perl -w
# 4AIDCLW - XML::Merge.pm created by Pip Stuart <Pip@CPAN.Org>
#   to intelligently merge && tidy XML documents as parsed
#   XML::XPath objects.
# Note: I didn't use '#!/usr/bin/perl -w' above because I need to redefine
#   node_test() && toString() XPath functions below in order to preserve
#   processing-instructions in merged or tidied documents.  Normally -w
#   warnings are very good. =)
# Note: heh now -w is back because I'm commenting the overrides below. =)
#
# Plan:
#   if    same-named root nodes,
#     merge straight
#   elsif root of 2nd exists in 1st,
#     merge at first match
#   else
#     append 2nd root as new last child of 1st root
#
#     XML::Merge new(filename => 'fnam'[, <other options> ]) (inherit XPath?)
#       just creates XPath obj but has merge() member which creates another
#       XPobj && blends result back into main obj.
#     optn:
#       merge below specified context
#       id attributes: 'id', 'name', && 'handle' (default)
#       join comments of same context (default)
#       source-file-stamp merged comments
#              time-stamp merged comments
#                pt-stamp merged comments
#     conflict rules:
#       main    wins (default)
#       last-in wins (aka. clobber)
#       newer modification date wins
#       warn
#     members:
#       merge() (can accept tmp override optz)
#       write()
#       prune()
#       unmerge()
#
#   option to rename some XPath to something else so like simple example
#     is taking merge-file's root node element && pretending it is
#     named the same as the main-file's root node element so that the
#     two can merge in place even though their root node elements had
#     different names.  This would clobber the name of the merge-file
#     element with the main-file one but it would be a useful option.
#

=head1 NAME

XML::Merge - flexibly merge (&& tidy) XML documents

=head1 VERSION

This documentation refers to version 1.0.4C2Nf0R of 
XML::Merge, which was released on Thu Dec  2 23:41:00:27 2004.

=head1 SYNOPSIS

  use XML::Merge;

  # create new       XML::Merge object from         MainFile.xml
  my $main_xml_doc = XML::Merge->new('filename' => 'MainFile.xml');
  # Merge File2Add.xml                 into         MainFile.xml
     $main_xml_doc->merge(           'filename' => 'File2Add.xml');
  # Tidy up the indenting on the merged data
     $main_xml_doc->tidy();
  # Write out changes back to MainFile.xml
     $main_xml_doc->write();

=head1 DESCRIPTION

This module utilizes underlying parsed L<XML::XPath> objects to merge
separate XML documents according to certain rules && configurable
options.  If both documents have root nodes which are elements of
the same name, the documents are merged directly.  Otherwise, one
is merged as a child of the other.  An optional XPath location can
be specified as the place to perform the merge.  If no location is
specified, the merge is attempted at the first matching element or is
appended as the new last child of the other root if no match is found.

This module also contains some utilities for stripping or tidying up
indenting levels of contained text nodes.  This comes in handy because
merging documents usually results in the ruination of indentation.

=head1 2DO

=over 2

=item - mk namespaces && attz stay in order after tidy() or merge()

=item - fix reload() from messing up unicode escaped &XYZ; components like
          Copyright &#xA9; -> © && Registered &#xAE; -> ®

=item - mk _idea take XPath locations instead of elem name keys

=item - mk good accessors for _idea

=item - mk txt apnd optn

=item - handle comment joins && stamping && options

=item - support modification-time _cres

=item - fix 03keep.t to pass && pkg

=item - add _ignr ignore list of merg xplc's to not merge (pre-prune())

=item - support _idea options where several attz together are single id

=item -     What else does Merge need?

=back

=head1 USAGE

=head2 new()

This is the standard Merge object constructor.  It can take
parameters like an L<XML::XPath> object constructor to initialize
the primary XML document object (the object which subsequent
XML documents will be merged into).  These options can be any one of:

  'filename' => 'SomeFile.xml'
  'xml'      => $variable_which_holds_a_bunch_of_XML_data
  'ioref'    => $file_InputOutput_reference
  'context'  => $existing_node_at_specified_context_to_become_new_obj

Merge's new() can also accept merge-option parameters to
override the default merge behavior.  These include:

  'conflict_resolution_method' => 'main' # main  file wins
  'conflict_resolution_method' => 'merg' # merge file wins
  'conflict_resolution_method' => 'warn' # print warnings
                   # 'last-in_wins' is an alias for 'merg'
  # other options should be added later according to utility

=head2 merge()

The merge() member function can accept the same L<XML::XPath>
constructor options as new() but this time they are for the
temporary file which will be merged into the main object.
Merge-options from new() can also be specified && they will only
impact one particular invokation of merge().  The specified document
will be merged into the primary XML document object according to
the following default merge rules:

  0. If both documents share the same root element name, they are
       merged directly.
  1. If they don't share root elements but the temporary merge file's
       root element is found anywhere within the main file, the merge
       occurs at the match.
  2. If no root element match is found, the merge document becomes the
       new last child of the main file's root element.
  3. Whenever a deeper level is found with an element of the same name
       in both documents && either it does not contain any
       distinguishing attributes or it has attributes which are
       recognized as 'identifier' (id) attributes (by default, for any
       element, these are attributes named: 'id', 'name', && 'handle'),
       a corresponding element is searched for to match && merge with.
  4. Any remaining (non-id) nodes are merged in document order.
  5. When a conflict arises as non-id attributes or other nodes merge,
       the specified conflict_resolution_method merge-option is
       applied (which by default has the main file data persist at the
       expense of the merging file data).

Some of the above rules can be overridden first by the object's
merge-options && second by the particular method call's merge-options.
Thus, if the default merge-option for conflict resolution is to
have the main object win && you use the following constructor:

  my $main_xml_doc = XML::Merge->new(
    'filename'                   => 'MainFile.xml',
    'conflict_resolution_method' => 'last-in_wins');

... then any $main_xml_doc->merge() call would override the
default merge behavior by letting the document being merged have
priority over the main object's document.  However, you could
supply additional merge-options in the parameter list of your
specific merge() call like:

  $main_xml_doc->merge(
    'filename'                   => 'File2Add.xml',
    'conflict_resolution_method' => 'warn');

... then the latest option would override the already overridden.

merge() can also accept another XML::Merge object as a parameter
for what to be merged with the main object like:

  $main_xml_doc->merge(
    'merge_object'               => $another_merge_obj);

or just:

  $main_xml_doc->merge($another_merge_obj);

=head2 strip()

The strip() member function searches the Merge object's child
XPath object for all mixed-content (ie. non-data) text nodes &&
empties them out.  This will basically unformat (clear out) any
markup indenting.  strip() is probably barely useful by itself
but it is needed by tidy() && it is exposed as a method in case
it comes in handy for other uses.

=head2 tidy()

The tidy() member function can take two optional parameters:

  'indent_type'   => 'spaces', # or 'tabs'
  'indent_repeat' => 2         # number of times to repeat per indent

The default behavior is to use two (2) spaces for each indent level.
The Merge object's XPath object gets all mixed-content (ie. non-
data) text nodes reformatted to appropriate indent levels according
to tree nesting depth.

=head2 write()

The write() member function can take an optional filename parameter
to write out any changes which have resulted from any number of calls
to merge() or tidy().  If no parameters are given, write() overwrites
the original primary XML document file.

write() can also accept an XPath location to treat as the root node
(element) to be written out to a disk file.  If the XPath statement
matches many elements, only the first encountered will be written out
as the new root element.  The object will remain unchanged (ie. even
though the disk file may now have a new root node, the object would
remain as it was with a potentially different root node that is an
ancestor of the written one).  If no elements are found at a
specified XPath location, no file is written.

=head2 prune()

The prune() member function takes an XPath location to remove (along
with all of its attributes && child nodes) from the Merge
object.

=head2 unmerge()

The unmerge() member function is a shorthand for calling both write()
&& prune() on a certain XPath location which should be written out
to a disk file before being removed from the Merge object.  This
process could be the opposite of merge if no original elements or
attributes overlapped && combined but if combining did happen, this
would remove original sections of your primary XML document's data
from your Merge object so please use this carefully.  It is meant
to help separate a giant object (probably the result of myriad merge()
calls) back into separate useful well-formed XML documents on disk.

unmerge() should be provided key => value pairs for both 'filename' &&
'xpath_location'.

=head1 Accessors

=head2 _filename()

Returns the underlying filename (if any) associated with this object.
An optional new filename can be provided as a parameter to override
(or initialize) the object's filename.

=head2 _xpath_object()

Returns the underlying L<XML::XPath> object.  An optional L<XML::XPath>
object can be provided as a parameter to assign the underlying
object (which will clobber any existing object along with all data
therein so please use caution).

=head2 _mo_conflict_resolution_method()

Returns the underlying merge-option conflict_resolution_method.
An optional new value can be provided as a parameter to be assigned
as the XML::Merge object's merge-option.

=head2 _mo_comment_join_method()

Returns the underlying merge-option comment_join_method.
An optional new value can be provided as a parameter to be assigned
as the XML::Merge object's merge-option.

=head1 CHANGES

Revision history for Perl extension XML::Merge:

=over 4

=item - 1.0.4C2Nf0R  Thu Dec  2 23:41:00:27 2004

* updated license && prep'd for release

=item - 1.0.4C2BcI2  Thu Dec  2 11:38:18:02 2004

* updated reload(), strip(), && tidy() to verify _xpob exists

=item - 1.0.4C1JHOl  Wed Dec  1 19:17:24:47 2004

* commented out override stuff since it's probably bad form && dumps crap
    warnings all over tests && causes them to fail... so I guess just
    uncomment that stuff if you care to preserve PI's && escapes

=item - 1.0.4C1J7gt  Wed Dec  1 19:07:42:55 2004

* made merge() accept merge_source_xpath && merge_destination_xpath params

* made merge() accept other Merge objects

* made reload() not clobber basic escapes (by overloading Text toString())

* made tidy() not kill processing-instructions (by overloading node_test())

* made tidy() not kill comments

=item - 1.0.4BOHGjm  Wed Nov 24 17:16:45:48 2004

* fixed merge() same elems with diff ids bug

=item - 1.0.4BNBCZL  Tue Nov 23 11:12:35:21 2004

* rewrote both merge() && _recmerge() _cres stuff since it was
    buggy before... so hopefully consistently good now

=item - 1.0.4BMJCPm  Mon Nov 22 19:12:25:48 2004

* fixed merge() for empty elem matching && _cres on text kids

=item - 1.0.4BMGTLF  Mon Nov 22 16:29:21:15 2004

* separated reload() from strip() so that prune() can call it too

=item - 1.0.4BM0B3x  Mon Nov 22 00:11:03:59 2004

* fixed tidy() empty elem bug && implemented prune() && unmerge()

=item - 1.0.4BJAZpM  Fri Nov 19 10:35:51:22 2004

* fixing e() ABSTRACT gen bug

=item - 1.0.4BJAMR6  Fri Nov 19 10:22:27:06 2004

* fleshed out pod && members

=item - 1.0.4AIDqmR  Mon Oct 18 13:52:48:27 2004

* original version

=back

=head1 INSTALL

If you're using ActiveState, you probably need to:
  `md C:\Perl\site\lib\XML\' if the dir doesn't exist
  && copy this file into that directory.

If you don't understand how to do this, please ask for assistance.

Otherwise, please run:

    `perl -MCPAN -e "install XML::Merge"`

or uncompress the package && run the standard:

    `perl Makefile.PL; make; make test; make install`

=head1 FILES

XML::Merge requires:

L<Carp>                to allow errors to croak() from calling sub

L<XML::XPath>          to use XPath statements to query && update XML

L<XML::XPath::XMLParser> to parse XML documents into XPath objects

=head1 LICENSE

Most source code should be Free!
  Code I have lawful authority over is && shall be!
Copyright: (c) 2004, Pip Stuart.
Copyleft : This software is licensed under the GNU General Public
  License (version 2), && as such comes with NO WARRANTY.  Please
  consult the Free Software Foundation (http://FSF.Org) for
  important information about your freedom.

=head1 AUTHOR

Pip Stuart <Pip@CPAN.Org>

=cut

# Please see CHANGES section to know why the following is commented.
## Need to fix node_test() test_nt_pi return in XML::XPath::Step.pm first...
#package XML::XPath::Step;
#use XML::XPath::Parser;
#use XML::XPath::Node;
#
#sub node_test {
#  my $self = shift; my $node = shift;
#  my $test = $self->{test}; # if node passes test, return true
#  return 1 if $test == test_nt_node;
#  if($test == test_any) {
#    return 1 if $node->isElementNode && defined $node->getName;
#  }
#  local $^W;
#  if($test == test_ncwild) {
#    return unless $node->isElementNode;
#    my $match_ns = $self->{pp}->get_namespace($self->{literal}, $node);
#    if(my $node_nsnode = $node->getNamespace()) {
#      return 1 if $match_ns eq $node_nsnode->getValue;
#    }
#  } elsif($test == test_qname) {
#    return unless $node->isElementNode;
#    if($self->{literal} =~ /:/) {
#      my($prefix, $name) = split(':', $self->{literal}, 2);
#      my $match_ns = $self->{pp}->get_namespace($prefix, $node);
#      if(my $node_nsnode = $node->getNamespace()) {
#        return 1 if($match_ns eq $node_nsnode->getValue && $name eq $node->getLocalName);
#      }
#    } else {
#      return 1 if $node->getName eq $self->{literal};
#    }
#  } elsif ($test == test_nt_text) {
#    return 1 if $node->isTextNode;
#  } elsif($test == test_nt_comment) {
#    return 1 if $node->isCommentNode;
#  } elsif($test == test_nt_pi) {
#    return unless $node->isPINode;
#    # EROR was here!  $self->{literal} is undefined so can't ->value!
#    #if(my $val = $self->{literal}->value) {
#    #  return 1 if $node->getTarget eq $val;
#    #} else {
#      return 1;
#    #}
#  }
#  return; # fallthrough returns false
#}
## ... also update Text nodes' toString() to escape both < && >! ...
#package XML::XPath::Node::TextImpl;
#sub toString {
#  my $self = shift; XML::XPath::Node::XMLescape($self->[node_text], '<&>');
#}

# Now ready to handle XML::Merge package...
package XML::Merge;
use warnings;
use strict;
use Carp;
use XML::XPath;
use XML::XPath::XMLParser;
our $VERSION     = '1.0.4C2Nf0R'; # major . minor . PipTimeStamp
our $PTVR        = $VERSION; $PTVR =~ s/^\d+\.\d+\.//; # strip major and minor
# See `perldoc Time::PT` for an explanation of $PTVR

my $DBUG = 0;

sub new {
  my $clas = shift(); my $okey; # Option hash KEY
  my $acky; my $acvl; # Alternate Constructor KeY => VaLue
  my $self = bless({}, $clas);
  $self->{'_cres'} = 'main'; # Conflict RESolution method valid values:
                             #   'main' = Main (primary) file wins
                             #   'merg' = Merge file resolves (Last-In wins)
                             #   'warn' = Warn about conflict && halt merge
  $self->{'_cmtj'} = 'none'; # CoMmenT Join method        valid values:
                             #   'none', 'separate'
                             #   'join', 'combine'
                             #   'jpts', 'join_with_piptime_stamp'
                             #   'jlts', 'join_with_localtime_stamp'
  $self->{'_idea'} = { # unique ID Element => [ Attribute ] names
          '_ANY_'  => ['id', 'name', 'handle'], # id atts to match anywhere
  };
  $self->{'_flnm'} = undef;  # main FiLe NaMe
  $self->{'_xpob'} = undef;  # XPath main OBject
  $self->{'_mgob'} = undef;  # xpath MerG OBject
  $self->{'_optn'} = {};     # parameter OPTioNs for each method
  my $mtch = join('|', keys(%{$self}));
  while($okey = shift()) {
    if   ($okey =~ /^($mtch)$/i) { $self->{lc($okey)} = shift(); }
    elsif($okey eq 'filename'  ) { $self->{'_flnm'  } = shift(); }
    elsif($okey =~ /^(xml|ioref|context)$/) { $acky = $okey; $acvl = shift(); }
    elsif($okey eq 'conflict_resolution_method') { $self->{'_cres'}= shift(); }
    else                         { $self->{'_flnm'  } = $okey;   }
  }
  if     (defined($acky)) {
    $self->{'_xpob'} = XML::XPath->new($acky      => $acvl);
  } elsif(defined($self->{'_flnm'}) && -e $self->{'_flnm'}) {
    $self->{'_xpob'} = XML::XPath->new('filename' => $self->{'_flnm'});
  } else {
    print "!*EROR*!  XML::XPath object could not be created!\n  Please supply an XML filename as a parameter to new().\n";
  }
  return($self);
}

sub merge {
  my $self = shift(); my $okey; $self->{'_optn'} = {};
  my $mtch = join('|', keys(%{$self}));
  while($okey = shift()) {
    if     ($okey =~ /^($mtch)$/i) {
      $self->{'_optn'}->{lc($okey)} = shift();
    } elsif($okey eq 'filename'  ) {
      $self->{'_optn'}->{'_flnm'  } = shift();
    } elsif($okey =~ /^(xml|ioref|context)$/) {
      $self->{'_optn'}->{'_acky'  } = $okey;
      $self->{'_optn'}->{'_acvl'  } = shift();
    } elsif($okey eq 'merge_destination_xpath') {
      $self->{'_optn'}->{'_mdxp'  } = shift();
    } elsif($okey eq 'merge_source_xpath') {
      $self->{'_optn'}->{'_msxp'  } = shift();
    } elsif($okey eq 'conflict_resolution_method') {
      $self->{'_optn'}->{'_cres'  } = shift();
    } elsif($okey eq 'merge_object') {
      $self->{'_optn'}->{'_mgob'  } = shift();
    } elsif($okey eq 'xpath_object') {
      $self->{'_mgob'}              = shift();
    } else {
      if     (ref($okey) eq 'XML::Merge') {
        print "REF:" . ref($okey) . "\n" if($DBUG);
        $self->{'_optn'}->{'_mgob'} = $okey;
        $self->{'_optn'}->{'_flnm'} = $self->{'_optn'}->{'_mgob'}->{'_flnm'};
      } elsif(ref($okey) eq 'XML::XPath') {
        print "REF:" . ref($okey) . "\n" if($DBUG);
        $self->{'_mgob'}            = $okey;
      } else {
        $self->{'_optn'}->{'_flnm'} = $okey;
      }
    }
  }
  # setup local option for Conflict RESolution method
  unless(exists ($self->{'_optn'}->{'_cres'}) &&
         defined($self->{'_optn'}->{'_cres'}) &&
         length ($self->{'_optn'}->{'_cres'})) {
    $self->{'_optn'}->{'_cres'} = $self->{'_cres'};
  }
  if($self->{'_optn'}->{'_cres'} =~ /last/) {
    $self->{'_optn'}->{'_cres'} = 'merg';
  }
  if     (exists ($self->{'_optn'}->{'_mgob'}) &&
          defined($self->{'_optn'}->{'_mgob'})) {
    $self->{'_mgob'} = $self->{'_optn'}->{'_mgob'}->{'_xpob'};
  } elsif(exists ($self->{'_optn'}->{'_flnm'}) &&
          defined($self->{'_optn'}->{'_flnm'}) &&
          length ($self->{'_optn'}->{'_flnm'}) &&
          -e      $self->{'_optn'}->{'_flnm'} ) {
    $self->{'_mgob'} = XML::XPath->new('filename' => $self->{'_optn'}->{'_flnm'});
  } elsif(exists ($self->{'_optn'}->{'_acky'}) &&
          defined($self->{'_optn'}->{'_acky'}) &&
          length ($self->{'_optn'}->{'_acky'})) {
    $self->{'_mgob'} = XML::XPath->new(
      $self->{'_optn'}->{'_acky'} => $self->{'_optn'}->{'_acvl'});
  }
  if(exists ($self->{'_mgob'}) &&
     defined($self->{'_mgob'})) {
    my $mnrn; my $mgrn;
    # traverse _xpob && merge new mgob according to options
    # 0a. ck if root node elems have same LocalName
    #  but short-circuit root element loading if merge_source or merge_dest
    if(exists ($self->{'_optn'}->{'_mdxp'}) &&
       defined($self->{'_optn'}->{'_mdxp'}) &&
       length ($self->{'_optn'}->{'_mdxp'})) {
      ($mnrn)= $self->{'_xpob'}->findnodes($self->{'_optn'}->{'_mdxp'});
    } else {
      ($mnrn)= $self->{'_xpob'}->findnodes('/*');
    }
    if(exists ($self->{'_optn'}->{'_msxp'}) &&
       defined($self->{'_optn'}->{'_msxp'}) &&
       length ($self->{'_optn'}->{'_msxp'})) {
      ($mgrn)= $self->{'_mgob'}->findnodes($self->{'_optn'}->{'_msxp'});
    } else {
      ($mgrn)= $self->{'_mgob'}->findnodes('/*');
    }
    if($mnrn->getLocalName() eq $mgrn->getLocalName()) {
      print "Root Node Element names match so merging in place!\n" if($DBUG);
      # 1a. ck if each merge root elem has attributes which main doesn't
      foreach($mgrn->findnodes('@*')) {
        print "  Found attr:" . $_->getLocalName() . "\n" if($DBUG);
        my($mnat)= $mnrn->findnodes('@' . $_->getLocalName());
        # if both root elems have same attribute name with different values...
        if(defined($mnat)) {
          print "  Found matching attr:" . $_->getLocalName() . "\n" if($DBUG);
          # must use Conflict RESolution method to know who's value wins
          if($mnat->getNodeValue() ne $_->getNodeValue()) {
            if     ($self->{'_optn'}->{'_cres'} eq 'merg') {
              print "    CRES:merg so setting main attr:" . $_->getLocalName() .  " to merg valu:" . $_->getNodeValue() . "\n" if($DBUG);
              $mnat->setNodeValue($_->getNodeValue());
            } elsif($self->{'_optn'}->{'_cres'} eq 'warn') {
              print "!*WARN*! Found conflicting attribute:" . $_->getLocalName() .
                "\n  main value:" .  $mnat->getNodeValue() .
                "\n  merg value:" .  $_   ->getNodeValue() .
                "\n    Skipping... please resolve manually.\n";
            }
          }
        } else {
          print "  Found new      attr:" . $_->getLocalName() . "\n" if($DBUG);
          $mnrn->appendAttribute($_);
        }
      }
      # 1b. loop through all merge child elems
      if($mgrn->findnodes('*')) {
        foreach($mgrn->findnodes('*')) {
          print "  Found elem:" . $_->getLocalName() . "\n" if($DBUG);
          my $mtch = 0; # flag to know if already matched
          # first test _ANY_ catch-all ID Attributes
          foreach my $idat (@{$self->{'_idea'}->{'_ANY_'}}) {
            # if a child merge elem has a matching _idea, search main for same
            my($mgmt)= $_->findnodes('@' . $idat); # MerG MaTch
            if(defined($mgmt)) {
              my($mnmt)= $mnrn->findnodes($_->getLocalName() . '[@' . $idat . '="' . $mgmt->getNodeValue() . '"]');
              if(defined($mnmt)) { # idea matched both main && merg...
                print "    Matched elem:" . $_->getLocalName() . '[@' . $idat . '="' . $mgmt->getNodeValue() . '"] with elem:' . $mnmt->getLocalName() . "\n" if($DBUG);
                $mtch = 1;
                $self->_recmerge($mnmt, $_); # so recursively merge deeper...
              }
            }
          }
          # next see if current elem exists in ID Elem hash
          if(exists($self->{'_idea'}->{$_->getLocalName()})) {
            foreach my $idat (@{$self->{'_idea'}->{$_->getLocalName()}}) {
              # if a child merge elem has a matching _idea, search main for same
              my($mgmt)= $_->findnodes('@' . $idat); # MerG MaTch
              if(defined($mgmt)) {
                my($mnmt)= $mnrn->findnodes($_->getLocalName() . '[@' . $idat . '="' . $mgmt->getNodeValue() . '"]');
                if(defined($mnmt)) { # idea matched both main && merg...
                  $mtch = 1;
                  $self->_recmerge($mnmt, $_); # so recursively merge deeper..
                }
              }
            }
          }
          if(!$mtch && $mnrn->findnodes($_->getLocalName())) {
            my($mnmt)= $mnrn->findnodes($_->getLocalName());
            if(defined($mnmt)) { # plain elem matched both main && merg...
              my $fail = 0;
              foreach my $idat (@{$self->{'_idea'}->{'_ANY_'}}) {
                my($mnat)= $mnmt->findnodes('@' . $idat); # MaiN ATtribute
                my($mgat)= $_   ->findnodes('@' . $idat); # MerG ATtribute
                $fail = 1 if(defined($mnat) || defined($mgat));
              }
              if(exists($self->{'_idea'}->{$_->getLocalName()})) {
                foreach my $idat (@{$self->{'_idea'}->{$_->getLocalName()}}) {
                  my($mnat)= $mnmt->findnodes('@' . $idat); # MaiN ATtribute
                  my($mgat)= $_   ->findnodes('@' . $idat); # MerG ATtribute
                  $fail = 1 if(defined($mnat) || defined($mgat));
                }
              }
              unless($fail) { # fail tests if any unique id attz are in elems
                $mtch = 1;
                $self->_recmerge($mnmt, $_); # so recursively merge deeper..
              }
            }
          }
          # if none above matched, append diff child to main root node
          $mnrn->appendChild($_) unless($mtch);
        }
      } elsif($mgrn->getChildNodes()) { # no kid elems but kid text data node
        my($mntx)= $mnrn->getChildNodes();
        my($mgtx)= $mgrn->getChildNodes();
        if(defined($mgtx) && $mgtx->getNodeType() == XML::XPath::Node::TEXT_NODE) {
          print "  Found text:" . $mgrn->getLocalName() . " valu:" . $mgtx->getNodeValue() . "\n" if($DBUG);
          if     (!defined($mntx)) {
            $mnrn->appendChild($mgtx);
          } elsif($self->{'_optn'}->{'_cres'} eq 'merg') {
#          $mnrn->setNodeValue($mgrn->getNodeValue());
            $mntx->setNodeValue($mgtx->getNodeValue());
          } elsif($self->{'_optn'}->{'_cres'} eq 'warn') {
            print "!*WARN*! Found conflicting     Root text node:" . $mnrn->getLocalName().
              "\n  main value:" .  $mntx->getNodeValue() .
              "\n  merg value:" .  $mgtx->getNodeValue() .
              "\n    Skipping... please resolve manually.\n";
          }
        }
      }
    # 0b. ck if merge root node elem exists in somewhere in main
    } elsif($self->{'_xpob'}->findnodes('//' . $mgrn->getLocalName())) {
      print "Root Node Element names differ && mgrn is in mnrn so merging at match!\n" if($DBUG);
      my($mnmt)= $self->{'_xpob'}->findnodes('//' . $mgrn->getLocalName());
      $self->_recmerge($mnmt, $mgrn); # recurse merge main child w/ merg root
    # 0c. just append whole merge doc as last child of main root
    } else {
      print "Root Node Element names differ so appending mgrn as last child of mnrn!\n" if($DBUG);
      $mnrn->appendChild($mgrn);
      my $text = XML::XPath::Node::Text->new("\n");
      $mnrn->appendChild($text);
    }
    print "  mnrn:" . $mnrn->getLocalName() . "\n" if($DBUG);
    print "  mgrn:" . $mgrn->getLocalName() . "\n" if($DBUG);
  }
}

sub _recmerge {
  my $self = shift(); # merge() already setup all needed _optn values
  my $mnnd = shift(); # MaiN NoDe
  my $mgnd = shift(); # MerG NoDe
  if($mnnd->getLocalName() eq $mgnd->getLocalName()) {
    print "Non-Root Node Element names match so merging in place!\n" if($DBUG);
    foreach($mgnd->findnodes('@*')) {
      print "NR  Found attr:" . $_->getLocalName() . "\n" if($DBUG);
      my($mnat)= $mnnd->findnodes('@' . $_->getLocalName());
      if(defined($mnat)) {
        print "NR  Found matching attr:" . $_->getLocalName() . "\n" if($DBUG);
        if($mnat->getNodeValue() ne $_->getNodeValue()) {
          if     ($self->{'_optn'}->{'_cres'} eq 'merg') {
            print "NR    CRES:merg so setting main attr:" . $_->getLocalName() .  " to merg valu:" . $_->getNodeValue() . "\n" if($DBUG);
            $mnat->setNodeValue($_->getNodeValue());
          } elsif($self->{'_optn'}->{'_cres'} eq 'warn') {
            print "!*WARN*! Found conflicting Non-Root attribute:" . $_->getLocalName().
              "\n  main value:" .  $mnat->getNodeValue() .
              "\n  merg value:" .  $_   ->getNodeValue() .
              "\n    Skipping... please resolve manually.\n";
          }
        }
      } else {
        print "NR  Found new      attr:" . $_->getLocalName() . "\n" if($DBUG);
        $mnnd->appendAttribute($_);
      }
    }
    if($mgnd->findnodes('*')) {
      foreach($mgnd->findnodes('*')) {
        print "NR  Found elem:" . $_->getLocalName() . "\n" if($DBUG);
        my $mtch = 0; # flag to know if already matched
        foreach my $idat (@{$self->{'_idea'}->{'_ANY_'}}) {
          my($mgmt)= $_->findnodes('@' . $idat); # MerG MaTch
          if(defined($mgmt)) {
            my($mnmt)= $mnnd->findnodes($_->getLocalName() . '[@' . $idat . '="' . $mgmt->getNodeValue() . '"]');
            if(defined($mnmt)) { # idea matched both main && merg...
              $mtch = 1;
              $self->_recmerge($mnmt, $_); # so recursively merge deeper...
            }
          }
        }
        # next see if current elem exists in ID Elem hash
        if(!$mtch && exists($self->{'_idea'}->{$_->getLocalName()})) {
          foreach my $idat (@{$self->{'_idea'}->{$_->getLocalName()}}) {
            # if a child merge elem has a matching _idea, search main for same
            my($mgmt)= $_->findnodes('@' . $idat); # MerG MaTch
            if(defined($mgmt)) {
              my($mnmt)= $mnnd->findnodes($_->getLocalName() . '[@' . $idat . '="' . $mgmt->getNodeValue() . '"]');
              if(defined($mnmt)) { # idea matched both main && merg...
                $mtch = 1;
                $self->_recmerge($mnmt, $_); # so recursively merge deeper..
              }
            }
          }
        }
        if(!$mtch && $mnnd->findnodes($_->getLocalName())) {
          my($mnmt)= $mnnd->findnodes($_->getLocalName());
          if(defined($mnmt)) { # plain elem matched both main && merg...
            my $fail = 0;
            foreach my $idat (@{$self->{'_idea'}->{'_ANY_'}}) {
              my($mnat)= $mnmt->findnodes('@' . $idat); # MaiN ATtribute
              my($mgat)= $_   ->findnodes('@' . $idat); # MerG ATtribute
              $fail = 1 if(defined($mnat) || defined($mgat));
            }
            if(exists($self->{'_idea'}->{$_->getLocalName()})) {
              foreach my $idat (@{$self->{'_idea'}->{$_->getLocalName()}}) {
                my($mnat)= $mnmt->findnodes('@' . $idat); # MaiN ATtribute
                my($mgat)= $_   ->findnodes('@' . $idat); # MerG ATtribute
                $fail = 1 if(defined($mnat) || defined($mgat));
              }
            }
            unless($fail) { # fail tests if any unique id attz are in elems
              $mtch = 1;
              $self->_recmerge($mnmt, $_); # so recursively merge deeper..
            }
          }
        }
        # if none above matched, append diff child to main
        $mnnd->appendChild($_) unless($mtch);
      }
    } elsif($mgnd->getChildNodes()) { # no child elems but child text data node
      my($mntx)= $mnnd->getChildNodes();
      my($mgtx)= $mgnd->getChildNodes();
      if(defined($mgtx) && $mgtx->getNodeType() == XML::XPath::Node::TEXT_NODE) {
        print "NR  Found text:" . $mgnd->getLocalName() . " valu:" . $mgtx->getNodeValue() . "\n" if($DBUG);
        if     (!defined($mntx)) {
          $mnnd->appendChild($mgtx);
        } elsif($self->{'_optn'}->{'_cres'} eq 'merg') {
          $mntx->setNodeValue($mgtx->getNodeValue());
        } elsif($self->{'_optn'}->{'_cres'} eq 'warn') {
          print "!*WARN*! Found conflicting Non-Root text node:" . $mnnd->getLocalName().
            "\n  main value:" .  $mntx->getNodeValue() .
            "\n  merg value:" .  $mgtx->getNodeValue() .
            "\n    Skipping... please resolve manually.\n";
        }
      }
    }
  } else { # just append whole merge elem as last child of main elem
    print "Non-Root Node Element names differ so appending mgrn as last child of mnrn!\n" if($DBUG);
    $mnnd->appendChild($mgnd);
    my $text = XML::XPath::Node::Text->new("\n");
    $mnnd->appendChild($text);
  }
  print "NR  mnnd:" . $mnnd->getLocalName() . "\n" if($DBUG);
  print "NR  mgnd:" . $mgnd->getLocalName() . "\n" if($DBUG);
}

sub prune { # remove a section of the tree at 'xpath_location'
  my $self = shift(); my $okey; $self->{'_optn'} = {};
  my $mtch = join('|', keys(%{$self}));
  while($okey = shift()) {
    if     ($okey =~ /^($mtch)$/i) {
      $self->{'_optn'}->{lc($okey)} = shift();
    } elsif($okey =~ /xpath_loc/i) {
      $self->{'_optn'}->{'_xplc'  } = shift();
    } else {
      $self->{'_optn'}->{'_xplc'  } = $okey;
    }
  }
  $self->reload(); # make sure all nodes && internal XPath indexing is up2date
  if(exists( $self->{'_xpob'}           ) &&
     defined($self->{'_xpob'}           ) &&
     exists( $self->{'_optn'}->{'_xplc'}) &&
     defined($self->{'_optn'}->{'_xplc'}) &&
     length( $self->{'_optn'}->{'_xplc'}) &&
             $self->{'_optn'}->{'_xplc'} ne '/') { # can't prune root node
    foreach($self->{'_xpob'}->findnodes($self->{'_optn'}->{'_xplc'})) {
      print 'Pruning:' . $self->{'_optn'}->{'_xplc'} . "\n" if($DBUG);
      my $prnt = $_->getParentNode();
      $prnt->removeChild($_) if(defined($prnt));
    }
  }
}

sub unmerge { # short-hand for writing a certain xpath_loc out then pruning it
  my $self = shift(); my $okey; $self->{'_optn'} = {};
  my $mtch = join('|', keys(%{$self}));
  while($okey = shift()) {
    if     ($okey =~ /^($mtch)$/i) {
      $self->{'_optn'}->{lc($okey)} = shift();
    } elsif($okey eq 'filename'  ) {
      $self->{'_optn'}->{'_flnm'  } = shift();
    } elsif($okey =~ /xpath_loc/i) {
      $self->{'_optn'}->{'_xplc'  } = shift();
    } else {
      $self->{'_optn'}->{'_xplc'  } = $okey;
    }
  }
  if(exists ($self->{'_optn'}->{'_flnm'}) &&
     defined($self->{'_optn'}->{'_flnm'}) &&
     length ($self->{'_optn'}->{'_flnm'}) &&
     exists ($self->{'_optn'}->{'_xplc'}) &&
     defined($self->{'_optn'}->{'_xplc'}) &&
     length ($self->{'_optn'}->{'_xplc'})) {
    $self->write('filename'  => $self->{'_optn'}->{'_flnm'},
                 'xpath_loc' => $self->{'_optn'}->{'_xplc'});
    $self->prune('xpath_loc' => $self->{'_optn'}->{'_xplc'});
  }
}

# Accessors
sub _filename {
  my $self = shift(); my $newv = shift();
  $self->{'_flnm'} = $newv if(defined($newv));
  return($self->{'_flnm'});
}

sub _xpath_object {
  my $self = shift(); my $newv = shift();
  $self->{'_xpob'} = $newv if(defined($newv));
  return($self->{'_xpob'});
}

sub _id_element_attributes {
  my $self = shift(); my $newv = shift();
  $self->{'_idea'} = $newv if(defined($newv));
  return($self->{'_idea'});
}

sub _mo_conflict_resolution_method {
  my $self = shift(); my $newv = shift();
  $self->{'_cres'} = $newv if(defined($newv));
  return($self->{'_cres'});
}

sub _mo_comment_join_method {
  my $self = shift(); my $newv = shift();
  $self->{'_cmtj'} = $newv if(defined($newv));
  return($self->{'_cmtj'});
}

sub reload { # dump XML text && reload object to re-index all nodes cleanly
  my $self = shift();
  if(exists ($self->{'_xpob'}) &&
     defined($self->{'_xpob'})) {
    my($root)= $self->{'_xpob'}->findnodes('/');
    my $data = qq(<?xml version="1.0" encoding="utf-8"?>\n);
    $data .= $_->toString() foreach($root->getChildNodes());
    $self->{'_xpob'} = XML::XPath->new('xml' => $data);
  }
}

# strips out all text nodes from any mixed content (ie. anywhere a text node
#   is a sibling of an element or comment)
sub strip {
  my $self = shift();
  if(exists ($self->{'_xpob'}) &&
     defined($self->{'_xpob'})) {
    my @nodz = $self->{'_xpob'}->findnodes('//*');
    foreach(@nodz) {
      if($_->getNodeType() eq XML::XPath::Node::ELEMENT_NODE) {
        my @kidz = $_->getChildNodes();
        foreach my $kidd (@kidz) {
          if($kidd->getNodeType() eq XML::XPath::Node::TEXT_NODE && @kidz > 1) {
            if($kidd->getValue() =~ /^\s*$/) {
              $kidd->setValue(''); # empty them all out
            }
          }
        }
      }
    }
    $self->reload(); # reload all XML as text to re-index nodes
  }
}

# tidy XML indenting where indent_type is either 'spaces' or 'tabs' &&
#   indent_repeat is how many indent_type characters should be used per indent
sub tidy {
  my $self = shift(); my $okey; $self->{'_optn'} = {};
  my $mtch = join('|', keys(%{$self}));
  while($okey = shift()) {
    if   ($okey =~ /^($mtch)$/i) {
      $self->{'_optn'}->{lc($okey)} = shift();
    } elsif($okey =~ /indent_type/i) {
      $self->{'_optn'}->{'_ityp'  } = shift();
    } elsif($okey =~ /indent_rep/i ) {
      $self->{'_optn'}->{'_irep'  } = shift();
    } else {
      $self->{'_optn'}->{'_ityp'  } = $okey;
    }
  }
  unless(exists ($self->{'_optn'}->{'_ityp'}) &&
         defined($self->{'_optn'}->{'_ityp'})) {
    $self->{'_optn'}->{'_ityp'} = ' ';
  }
  if(exists ($self->{'_optn'}->{'_ityp'}) &&
     defined($self->{'_optn'}->{'_ityp'})) {
    if     ($self->{'_optn'}->{'_ityp'} =~ /^(spac| )/i) {
      $self->{'_optn'}->{'_ityp'} = ' ';
    } elsif($self->{'_optn'}->{'_ityp'} =~ /^(tab|\t)/i) {
      $self->{'_optn'}->{'_ityp'} = "\t";
    }
  }
  unless(exists ($self->{'_optn'}->{'_irep'}) &&
         defined($self->{'_optn'}->{'_irep'})) {
    if($self->{'_optn'}->{'_ityp'} eq ' ') {
      $self->{'_optn'}->{'_irep'} = 2;
    } else {
      $self->{'_optn'}->{'_irep'} = 1;
    }
  }
  $self->strip(); # strips all non mixed-content text nodes from object
  # now insert new nodes with newlines && indenting by tree nesting depth
  my $dpth = 0; # keep track of element nest depth
  my $tnod = undef; # temporary node which will get nodes surrounding children
  my $docu = XML::XPath::Node::Element->new(); # temporary document root node
  if(exists ($self->{'_xpob'}) &&
     defined($self->{'_xpob'})) {
    foreach($self->{'_xpob'}->findnodes('processing-instruction()'),
            $self->{'_xpob'}->findnodes('comment()')) {
      print "NodeType:" . $_->getNodeType() . " = " . $_->toString() .
             "\n  pos:" . $_->get_pos() .
           " Glob_pos:" . $_->get_global_pos() . "\n" if($DBUG);
      $docu->appendChild($_); # consider insertBefore($posi)
    }
    my($root)= $self->{'_xpob'}->findnodes('/*');
    print "RT  Found new      elem:" . $root->getName() . "\n" if($DBUG);
    if($root->getChildNodes()) {
      $tnod = $self->_rectidy($root, ($dpth + 1)); # recursively tidy children
    }
    $docu->appendChild($tnod);
    $self->{'_xpob'} = $docu;
  }
}

sub _rectidy { # recursively tidy up indent formatting of elements
  my $self = shift(); my $node = shift(); my $dpth = shift();
  my $tnod = undef; # temporary node which will get nodes surrounding children
  $tnod = XML::XPath::Node::Element->new($node->getName());
  foreach($node->findnodes('@*')) { # copy all attributes
    print "RT  Found new      attr:" . $_->getName() . "\n" if($DBUG);
    $tnod->appendAttribute($_);
  }
  foreach($node->getNamespaces()) { # copy all namespaces
    print "RT  Found new namespace:" . $_->toString() .
                          "\n  pos:" . $_->get_pos() .
                        " Glob_pos:" . $_->get_global_pos() . "\n" if($DBUG);
    $tnod->appendNamespace($_);
  }
  my @kidz = $node->getChildNodes(); my $lkid;
  foreach my $kidd (@kidz) {
    if($kidd->getNodeType() ne XML::XPath::Node::TEXT_NODE && (!$lkid ||
       $lkid->getNodeType() ne XML::XPath::Node::TEXT_NODE)) {
      $tnod->appendChild(XML::XPath::Node::Text->new("\n" . ($self->{'_optn'}->{'_ityp'} x ($self->{'_optn'}->{'_irep'} *  $dpth     ))));
    }
    if($kidd->getNodeType() eq XML::XPath::Node::ELEMENT_NODE) {
      my @gkdz = $kidd->getChildNodes();
      if(@gkdz    && ($gkdz[0]->getNodeType() ne XML::XPath::Node::TEXT_NODE ||
        (@gkdz > 1 && $gkdz[1]->getNodeType() ne XML::XPath::Node::TEXT_NODE))) {
        $kidd = $self->_rectidy($kidd, ($dpth + 1)); # recursively tidy
      }
    }
    $tnod->appendChild($kidd);
    $lkid = $kidd;
  }
  $tnod->appendChild(XML::XPath::Node::Text->new("\n" . ($self->{'_optn'}->{'_ityp'} x ($self->{'_optn'}->{'_irep'} * ($dpth - 1)))));
  return($tnod);
}

sub write {
  my $self = shift(); my $okey; $self->{'_optn'} = {};
  my $mtch = join('|', keys(%{$self})); my $root;
  while($okey = shift()) {
    if   ($okey =~ /^($mtch)$/i) {
      $self->{'_optn'}->{lc($okey)} = shift();
    } elsif($okey eq 'filename'  ) {
      $self->{'_optn'}->{'_flnm'  } = shift();
    } elsif($okey =~ /xpath_loc/i) {
      $self->{'_optn'}->{'_xplc'  } = shift();
    } else {
      $self->{'_optn'}->{'_flnm'  } = $okey;
    }
  }
  unless(exists ($self->{'_optn'}->{'_flnm'}) &&
         defined($self->{'_optn'}->{'_flnm'})) {
    $self->{'_optn'}->{'_flnm'} = $self->{'_flnm'};
  }
  if(exists($self->{'_optn'}->{'_xplc'})) {
       $root = XML::XPath::Node::Element->new();
    my($rtnd)= $self->{'_xpob'}->findnodes($self->{'_optn'}->{'_xplc'});
       $root->appendChild($rtnd);
  } else {
    ($root)= $self->{'_xpob'}->findnodes('/');
  }
  my @kids = $root->getChildNodes();
  open( FILE, '>' . $self->{'_optn'}->{'_flnm'});
  print FILE qq(<?xml version="1.0" encoding="utf-8"?>\n);
  print FILE $_->toString() , "\n" foreach(@kids);
  close(FILE);
}

127;
