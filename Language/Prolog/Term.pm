# Author: Jack Shirazi
# Version: alpha1
package Language::Prolog::Term;
$STACK_DEBUG = 0;
$UNIFY_DEBUG = 0;

# An abstract superclass, holding only methods common to subclasses
# (and methods required to be implemented in subclasses).

sub newVariable {
    my($self,$string) = @_;
    $self->newType('Variable',$string);
}

sub newAtom {
    my($self,$string) = @_;
    $self->newType('Atom',$string);
}

sub newList {
    my($self,@terms) = @_;
    $self->newType('List',@terms);
}

sub newVarList {
    my($self,@terms) = @_;
    $self->newType('VarList',@terms);
}

sub newClause {
    my($self,@terms) = @_;
    $self->newType('Clause',@terms);
}

sub newRule {
    my($self,@terms) = @_;
    $self->newType('Rule',@terms);
}

sub newType {
    my($self,$type,@args) = @_;

    ($type =~ m/::|'/) || ($type = "Language::Prolog::$type"); #'

    $type->new(@args);
}

sub new {
    my($self,@args) = @_;

    # Prolog terms consist of an array of
    # 1. data
    # 2. stack
    # 3. proxy - pointer to another object that can represent the
    #    term after a unification

    bless [$self->newDataObject(@args), $self->newStack(),undef], $self;
}

sub termCopy {
    my($self,$hash) = @_;
    defined($hash) || ($hash = {});
    my $inst = bless [undef, $self->newStack(),undef], ref($self);
    $inst->copyDataObjectFrom($self,$hash);
    $inst;
}

sub newDataObject {
    my($self,@args) = @_;
    die "newDataObject: method called in abstract superclass Language::"
	. "Prolog::Term which should only be called in a subclass";
}

sub copyDataObjectFrom {
    my($self,$obj) = @_;
    die "copyDataObjectFrom: method called in abstract superclass Language::"
	. "Prolog::Term which should only be called in a subclass";
}

sub newStack {Language::Prolog::Stack->new()}

sub _proxy {$_[0]->[2];}
sub _proxyBeforeLast {
    my($self) = @_;
    my $before = $self;
    my $this = $self->_proxy() || return undef;
    for (;;) {
    	$next = $this->_proxy();
    	if (!$next) {return $before}
	$before = $this;
	$this = $next;
    }
}

sub proxy {$_[0]->_lastProxy()}
sub _lastProxy {$_[0]->_proxy() ? $_[0]->_proxy()->_lastProxy() : $_[0];}
sub setProxy {
    my($self,$other) = @_;
    $other->proxy()->stack()->addToStack($self->proxy());
    $self->proxy()->[2] = $other->proxy();
}
sub undoLastUnification {
    my($self) = @_;
#warn $self->asString();
    # pop the last item on the stack and tell it to unset its proxy
    my $other = $self->proxy()->stack()->popFromStack();
    my $proxy = $other->_proxyBeforeLast();
    $proxy && ($proxy->[2] = undef);
    $other->listUndoLastUnification();
}
sub listUndoLastUnification {}

sub stack {$_[0]->[1];}
sub data {$_[0]->[0];}

sub asString {
    $STACK_DEBUG ?
        $_[0]->dataAsString() . '{' . $_[0]->stack()->asString() . '}' .
	    ($_[0]->_proxy() ?
		'->' . $_[0]->_proxy()->asString()
	    :
		'')
    :
        $_[0]->proxy()->dataAsString();
}

sub isTerm {$_[0]->proxy()->_isTerm();}
sub instantiated {$_[0]->proxy()->_instantiated();}
sub isAtom {$_[0]->proxy()->_isAtom();}
sub isList {$_[0]->proxy()->_isList();}
sub isClause {$_[0]->proxy()->_isClause();}

sub dataAsString {'aTerm';}
sub _isTerm {1;}
sub _instantiated {1;}
sub _isAtom {0;}
sub _isList {0;}
sub _isClause {0;}

sub _generality {100;}

sub unify {
    my($self,$other,$stack) = @_;

    my($unify);

    if($UNIFY_DEBUG){
	print STDOUT " " x $UNIFY_DEBUG, $UNIFY_DEBUG," UNIFYING: ",
	    '(',(split(/::/,ref($self)))[2],') ',$self->asString()," = ",
	    '(',(split(/::/,ref($other)))[2],') ',$other->asString(),"\n";
	$UNIFY_DEBUG++;
    }

    if ($self->proxy() == $other->proxy()) {
        $unify = 1;
	$self->setProxy($other);
    } elsif ($self->proxy()->_generality() >= $other->proxy()->_generality()) {
    	$unify = $self->proxy()->_unify($other->proxy(),$stack);
	if ($unify == -1) {$self->setProxy($other)}
    	elsif ($unify == 1) {$other->setProxy($self)}
    } else {
    	$unify = $other->proxy()->_unify($self->proxy(),$stack);
	if ($unify == 1) {$self->setProxy($other)}
    	elsif ($unify == -1) {$other->setProxy($self)}
    }

    if($UNIFY_DEBUG){
	$UNIFY_DEBUG--;
	print STDOUT " " x $UNIFY_DEBUG, $UNIFY_DEBUG,
	    ($unify ? " SUCCEEDED: " : " FAILED: "),
	    '(',(split(/::/,ref($self)))[2],') ',$self->asString()," = ",
	    '(',(split(/::/,ref($other)))[2],') ',$other->asString(),"\n";

    }

    $unify;
}

sub _unify {
    my($self,$other) = @_;
    die "_unify: method called in abstract superclass Language::"
	. "Prolog::Term which should only be called in a subclass";
}


sub includesVariable {
    my($self,$var) = @_;
    die "includesVariable: method called in abstract superclass Language::"
	. "Prolog::Term which should only be called in a subclass";
}

1;
