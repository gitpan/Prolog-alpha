# Author: Jack Shirazi
# Version: alpha1
package Language::Prolog::Rule;
@ISA = qw(Language::Prolog::Clause);

sub newDataObject {
    my($self,@elements) = @_;
    my $data = $self->Language::Prolog::List::newDataObject(@elements);
    foreach $e (@elements) {
	$e->isClause() || die "Every element of a Rule must be a clause";
    }
    $data;
}

sub dataAsString {
    my($self) = @_;
    $self->data()->[0]->dataAsString();
}

sub _isClause {0;}

sub _functor {$_[0]->data()->[0]->_functor()}
sub _functorArity {$_[0]->data()->[0]->_functorArity()}

sub _generality {2000;}

sub _unify {
    my($self,$other,$stack) = @_;

    # Rules can only unify to a clause
    $other->isClause() || return 0;

    # The Rule unifies if the head unifies to the clause
    # and all the elements in the tail unify to the clausal store

    # !!!NOTE!!! THIS _unify ASSUMES THAT THE Rule IS ALWAYS
    # A THROWAWAY Rule - i.e. it was termCopy'ed before
    # being called - probably from the store.

    my $copy = $other->termCopy();

    $self->data()->[0]->unify($copy) || return 0;
    my $i = 1;
    my $dataArray = $self->data();
    my $unifyIndex = $stack->popArray($#{$dataArray});

    for (;;) {
	$unifyIndex->[$i] = $dataArray->[$i]->unifyToStore($unifyIndex->[$i],$stack);
	if ($unifyIndex->[$i]) {
	    $i++;
	    if($i > $#{$dataArray}) {
		$other->unify($copy->termCopy());
		$stack->addArray($unifyIndex);
		return 1;
	    }
	} else {
	    $i--;
	    if($i < 1) {$stack->addArray($unifyIndex);return 0;}
	    $dataArray->[$i]->undoLastUnification();
	}
    }
}

1;
