# Author: Jack Shirazi
# Version: alpha1
package Language::Prolog::Variable;
@ISA = qw(Language::Prolog::Term);
$VAR_COUNT = 1;			#Used for printing the variable
%VAR_NAMES;

sub newDataObject {
    my($self,$varname) = @_;
    my $var_count = $VAR_COUNT++;
    $VAR_NAMES{$var_count} = $varname;

    $var_count;
}

sub dataAsString {
    my($self) = @_;
    $VAR_NAMES{$self->data()} ? $VAR_NAMES{$self->data()} : '_' . $self->data();
}

sub copyDataObjectFrom {
    my($self,$obj,$hash) = @_;
    my $var = $obj->proxy()->data();
    $self->[0] = $var;
    if ($hash->{$var}) {
	$self->unify($hash->{$var})
    } else {
	$hash->{$var} = $self;
    }
}

sub _instantiated {0;}

sub _generality {50000;}

sub _unify {
    my($self,$other) = @_;
    # Variables almost always succeed unification. 
    # On success they just set their proxy to the other object.
    # There is just one situation that a variable fails unification -
    # when the other object is not a variable and contains the
    # variable. This would lead to an infinitely recursive state
    # e.g. 'A = [a|A]' must fail.

    ($other->instantiated() && $other->includesVariable($self)) ?
	0 :
	-1 ;
}

sub includesVariable {
    my($self,$var) = @_;
    $self->proxy()->data() == $var->proxy()->data();
}

1;
