# Author: Jack Shirazi
# Version: alpha1
package Language::Prolog::Atom;
@ISA = qw(Language::Prolog::Term);
%ATOM_TABLE;
@ATOM_ARRAY;

sub newDataObject {
    my($self,$string) = @_;
    my($val);

    # Keep an atom table and use a counter to assign the value for the atom.
    # A hash value would do just as well. Provides quicker unification,
    # and one instance of the actual string (well, I use two because I
    # hold an array to map back from number to string for printing,
    # but in principle ...).

    $val = $ATOM_TABLE{$string};
    if (!defined($val)) {
	push(@ATOM_ARRAY,$string);  #Used for printing - but doubles storage!
	$val = $#ATOM_ARRAY;
	$ATOM_TABLE{$string} = $val;
    }

    $val;
}

sub copyDataObjectFrom {
    my($self,$obj,$hash) = @_;
    $self->[0] = $obj->proxy()->data();
}


sub dataAsString {$ATOM_ARRAY[$_[0]->[0]]}
sub _atomString {$_[0]->[0]}
sub _isAtom {1;}

sub _unify {
    my($self,$other) = @_;
    # Atoms succeed unification if they are both the same atom
    # Set a proxy?
    $other->isAtom() && ($self->data() == $other->data());
}
sub includesVariable {0;}

1;
