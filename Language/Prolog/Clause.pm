# Author: Jack Shirazi
# Version: alpha1
package Language::Prolog::Clause;
@ISA = qw(Language::Prolog::List);

sub newDataObject {
    my($self,@elements) = @_;
    my $data = $self->Language::Prolog::List::newDataObject(@elements);
    $elements[0]->isAtom() ||
	die "Clauses must have an atom as the functor";
    $data;
}

sub dataAsString {
    my($self) = @_;
    $self->data()->[0]->asString() .
	(($self->dataSize() == 1) ? '' : '(' . join(',',map(
	     $_->asString(),@{$self->data()}[1 .. $#{$self->data()}])) . ')');
}

sub _isList {0;}
sub _isClause {1;}

sub _unify {
    my($self,$other,$stack) = @_;
    # Two lists unify if every element unifies.

    $other->isClause() || return 0;

    $self->_unifyList($other,$stack);
}

sub _functorArity {$#{$_[0]->data()}}
sub _functor {$_[0]->data()->[0]->_atomString()}

sub _storeKey {
    my($self) = @_;
    $self->_functorArity() . '/' . $self->_functor();
}

sub _addToStore {
    my($self) = @_;

    # Only a very simple store at the moment - just arrays keyed
    # on the "arity/functor". May try to get it complicated with indexing
    # if I or someone else can ever be bothered.
    # If so, which args are the index should be optional - defaulting
    # to the first.

    my $key = $self->_storeKey();

    my $arr_ref = $STORE{$key};
    if (!$arr_ref) {$STORE{$key} = $arr_ref = []};

    push(@{$arr_ref}, $self->termCopy());
}

sub getStoreArray {
    my($self) = @_;
    $STORE{$self->_storeKey()} || [];
}

sub unifyToStore {
    my($self,$i,$stack) = @_;

    $self->isClause() || die "Only Clauses can be unified to the clause store";

    $stack->popElement($self,$res); #Should really be $i = popEl...

    my $copy = $self->termCopy();

    my $res = $copy->_unifyToStore($i,$stack);

    if ($res) {$self->unify($copy->termCopy());}

    $stack->addElement($self,$res);

    $res;
}

sub _unifyToStore {
    my($self,$i,$stack) = @_;
    my $key = $self->_storeKey();

    # Failure by absence of terms.
    my $arr_ref = $STORE{$key} || return 0;

    $i = $i ? $i : 0;
    for ( ; $i <= $#{$arr_ref}; $i++) {
	if ($self->unify($arr_ref->[$i]->termCopy(),$stack)) {
	    return $i + 1;
	}
    }
    0;
}

1;
