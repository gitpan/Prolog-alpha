# Author: Jack Shirazi
# Version: alpha1
package Language::Prolog::IndexStack;
sub new {bless [[],[]];}
sub addElement {
    my($self,$term,$index) = @_;
    push(@{$self->[1]},$index - 1);
}
sub addArray {
    my($self,$indexArray) = @_;
    push(@{$self->[1]},[$indexArray->[0],map($_ - 1,@{$indexArray}[1 .. $#{$indexArray}])]);
}
sub popArray {
    my($self) = @_;
    my $arr = pop(@{$self->[1]});
    $arr || ['Rule'];
}
sub popElement {
    my($self) = @_;
    my $e = pop(@{$self->[1]});
    $e
}
sub asString {
    my($self) = @_;
    join(':',map(ref($_) ? '['.join(':',@{$_}).']' : $_,@{$self->[1]}));
}
sub incrementForBacktrack {
    my($self) = @_;
    my $e = $self->[1]->[1];
    if (ref($e)) {
	$e->[$#{$e}] = $e->[$#{$e}] + 1;
    } else {
	$self->[1]->[1] = $e + 1;
    }
}
sub top {
    my($self) = @_;
    $self->[1]->[$#{$self->[1]}];
}

1;
