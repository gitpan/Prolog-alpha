# Author: Jack Shirazi
# Version: alpha1
package Language::Prolog::Query;
$QUERY_COUNT = 1;

sub newQuery {
    my($self,$variables,@clauses) = @_;
    my $query = "query" . $QUERY_COUNT++;
    my $Qatom = Language::Prolog::Term->newAtom($query);
    my $head = Language::Prolog::Term->newClause($Qatom,values %{$variables});
    my $rule = Language::Prolog::Term->newRule($head,@clauses);
    $rule->_addToStore();
    bless [0,$variables,$head,$rule,Language::Prolog::IndexStack->new()];
}

sub query {
    my($self) = @_;
    my $res;

    if ($self->[0] == 0) {
	# First time query;
	$self->[0] = 1;
	$res = $self->[2]->unifyToStore(0,$self->[4]);
	if ($res) {return 1;} else {$self->[0] = 2; return 0;}
    } elsif ($self->[0] == 1) {
	$self->[2]->undoLastUnification();
	$self->[4]->incrementForBacktrack();
	$res = $self->[2]->unifyToStore($self->[4]->top(),$self->[4]);
	if ($res) {return 1;} else {$self->[0] = 2; return 0;}
    } else {
	0;
    }
}

sub variableResult {
    my($self,$var) = @_;
    $self->[0] == 1 || undef;
    my $vterm = $self->[1]->{$var} || undef;
    $vterm->asString();
}

sub _asString {
    my($self) = @_;
    $self->[2]->asString();
}

1;
