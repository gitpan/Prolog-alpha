# Author: Jack Shirazi
# Version: alpha1
package Language::Prolog::VarList;
@ISA = qw(Language::Prolog::List);

sub newDataObject {
    my($self,@elements) = @_;

    my $data = $self->Language::Prolog::List::newDataObject(@elements);

    $#elements > 0 || 
	die "Must have at least one term and the variable at the end";

    $elements[$#elements]->instantiated() && 
	die "The last term must a variable";

    $data;
}

sub dataAsString {
    my($self) = @_;
    '[' . join(',',
	  map($_->asString(),@{$self->data()}[0 .. ($#{$self->data()} - 1)])
        ) . '|' . $self->data()->[$#{$self->data()}]->asString() . ']' ;
}

sub _generality {300;}

sub _fixedSize {0;}

sub _unify {
    my($self,$other,$stack) = @_;
    my($s,$i);
    # Two lists unify if every element unifies.

    $other->isList() || return 0;

    my $dataArray = $self->data();
    my $otherDataArray = $other->data();

    if ($other->_fixedSize()) {
	# Just unify all elements up to the variable, then all other
	# elements of $other form a list which the Var unifies to.
	# First check that the other is big enough.
	$s = $#{$dataArray} - 1;
	($s <= $#{$otherDataArray}) || return 0;

	# Now check all the elements up to the Var
	for ($i = 0; $i <= $s; $i++) {
	    $dataArray->[$i]->unify($otherDataArray->[$i],$stack) ||
		return $self->undoLastUnificationElementsFrom($i-1,$dataArray);
	}

	# Now unify the var to a list containing all the remaining elements
	
	$dataArray->[$s+1]->unify($other->sublistFrom($s+1),$stack) ||
	    return $self->undoLastUnificationElementsFrom($i,$dataArray);

	# And finally return the other guy, since both lists are
	# now fixed size ones
	return -1;
    } else {
        # Both with variable tails. Just get the bigger, and unify the
	# smaller's tail variable to the biggers sublist from the variable

	$s = ($#{$dataArray} > $#{$otherDataArray}) ?
		$#{$otherDataArray} : $#{$dataArray};

	# First check all the elements up to the smaller list's Var
	$s--;
	for ($i = 0; $i <= $s; $i++) {
	    $dataArray->[$i]->unify($otherDataArray->[$i],$stack) || 
		return $self->undoLastUnificationElementsFrom($i-1,$dataArray);
	}

	# Now unify the var to a list containing all the remaining elements
	if ($#{$dataArray} > $#{$otherDataArray}) {
	    $otherDataArray->[$#{$otherDataArray}]->unify(
		$self->sublistFrom($#{$otherDataArray}),$stack);
	    return 1;
	} else {
	    $dataArray->[$#{$dataArray}]->unify(
		$other->sublistFrom($#{$dataArray}),$stack);
	    return -1;
	}
    }
}

1;
