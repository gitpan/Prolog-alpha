# Author: Jack Shirazi
# Version: alpha1
package Language::Prolog::List;
@ISA = qw(Language::Prolog::Term);

# I have avoided a recursive definition of lists in the interests
# of efficiency. Have a look at the commented out
# Language::Prolog::RecursiveList class to see how they would have been
# defined instead of this class and Language::Prolog::VarList

# These lists are known-size list terms - as opposed to lists of unknown size
# e.g. [a,b,c] as opposed to [a,b|VAR] (which could be [a,b] or [a,b,c], ...).

sub newDataObject {
    my($self,@elements) = @_;
    my($i);

    for ($i = 0; $i <= $#elements; $i++) {
	$elements[$i]->isTerm() ||
	    die "All arguments must be valid prolog objects";
    }

    # First element defines whether it is a list or head-tail list.
    [@elements];
}

sub dataAsString {
    my($self) = @_;
    '[' . join(',',map($_->asString(),@{$self->data()})) . ']';
}

sub copyDataObjectFrom {
    my($self,$obj,$hash) = @_;
    $self->[0] = [];
    foreach $e (@{$obj->data()}) {
	push(@{$self->[0]},$e->proxy()->termCopy($hash));
    }
}

sub dataSize {$#{$_[0]->data()} + 1}
sub includesVariable {
    my($self,$var) = @_;
    my $i;
    my $dataArray = $self->data();

    for ($i = 0; $i <= $#{$dataArray}; $i++) {
    	$dataArray->[$i]->proxy()->includesVariable($var) && return 1;
    }
    0;
}

sub _isList {1;}

sub listUndoLastUnification {
    my($self) = @_;
    foreach $e (reverse @{$self->data()}) {$e->proxy()->undoLastUnification()}
}

sub _unify {
    my($self,$other,$stack) = @_;
    # Two lists unify if every element unifies.

    $other->isList() || return 0;

    $self->_unifyList($other,$stack);
}

sub _unifyList {
    my($self,$other,$stack) = @_;
    # Two lists unify if every element unifies.

    ($self->dataSize() == $other->dataSize()) || return 0;

    my($i);
    my $dataArray = $self->data();
    my $otherDataArray = $other->data();

    for ($i = 0; $i <= $#{$dataArray}; $i++) {
    	$dataArray->[$i]->unify($otherDataArray->[$i],$stack) || 
	    return $self->undoLastUnificationElementsFrom($i-1,$dataArray);
    }
    1;
}

sub undoLastUnificationElementsFrom {
    my($self,$index,$arr1,$arr2) = @_;
    my($i,$j);
    $index >= 0 || return 0;

    if (defined($arr2)){
    	for ($i = $index; $i >= 0; $i--) {
	    $arr1->[$i]->undoLastUnification();
	    $arr2->[$i]->undoLastUnification();
	}
    } else {
    	for ($i = $index; $i >= 0; $i--) {
	    $arr1->[$i]->undoLastUnification();
	}
    }
    0;
}

sub _fixedSize {1;}

sub sublistFrom {
    my($self,$index) = @_;
    # return a list object containing a list which is the list of elements
    # from $index including $index.
    if ($index <= $#{$self->data()}) {
	return ref($self)->new(@{$self->data()}[$index..$#{$self->data()}]);
    } elsif($index == ($#{$self->data()} + 1)) {
	return Language::Prolog::List->new();
    } else {
	die "sublistFrom called with index greater than size of list";
    }
}

1;
