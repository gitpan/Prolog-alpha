# Author: Jack Shirazi
# Version: alpha1
package Language::Prolog::Stack;

sub new {bless [];}
sub asString {join('+',map($_->dataAsString(),@{$_[0]}))}
sub addToStack {
    my($self,$other) = @_;
    push(@{$self},$other);
}
sub popFromStack {
    my($self,$other) = @_;
    pop(@{$self});
}

1;
