# Author: Jack Shirazi
# Version: alpha1
package Language::Prolog::Interpreter;
# A simple interpreter which doesn't allow infix operators (except
# for ':-' and ',', both of which are built in).


$VARIABLE_REGEX = '[A-Z_]\w*';
$SIMPLE_ATOM_REGEX = '[a-z]\w*';


sub readStatement {
    my($self,$string_ref) = @_;

    # There are three possible statements:
    # 1. A single clause ending in a statement terminator (.)
    #    This gets added to the store.
    # 2. A single rule ending in a statement terminator (.)
    #    This gets added to the store.
    # 3. The characters '?-' followed by a comma separated list
    #    of clauses, ending in a statement terminator (.). This
    #    creates and returns a query.

    #   Whitespace is ignored everywhere except in single quoted atoms

    $$string_ref =~ s/^\s*//;

    my $statement;

    if ($$string_ref =~ s/^\?\-//) {
	return $self->readQuery($string_ref);
    } else {
	$statement = $self->readClauseOrRule($string_ref);
	$$string_ref =~ s/^\s*//;
	if ($$string_ref =~ s/^\.//) {
	    $statement->_addToStore();
	    return undef;
	} else {
	    die "Error - statement terminator is missing";
	}
    }
}

sub readQuery {
    my($self,$string_ref) = @_;
    my(@clauses,$variables);
    $variables = {};

    for(;;) {
	push(@clauses,$self->readClause($string_ref,$variables));
	if ($$string_ref =~ s/\s*\,//) {
	    next;
	} elsif ($$string_ref =~ s/\s*\.//) {
	    return Language::Prolog::Query->newQuery($variables,@clauses);
	} else {
	    die "Error - statement terminator is missing";
	}
    }
}


sub readTerm {

    # Terms are:-
    #   Lists1: Comma separated lists of terms enclosed in square brackets
    #       e.g [Term1,Term2] 
    #   Lists2: As List1, but final term is a variable separated by a '|'
    #       e.g [Term1,Term2|Variable] 
    #   Atoms1: sequence of characters/digits/underscore (i.e \w character
    #       class) starting with a lower case character.
    #       e.g. this_Is_An_Atom
    #   Atoms1: any sequence of characters enclosed in single quotes (')
    #       e.g. 'This is another atom!'
    #   Variables: sequence of characters/digits/underscore (i.e \w character
    #       class) starting with an upper case character or underscore
    #       e.g. This_is_a_var, _and_this, _90
    #   Clauses: an Atom1 immediately followed by a left bracket, '(',
    #       followed by a comma separated list of terms, terminating
    #       in a right bracket.
    #       e.g clause(one), clause2(a,hello,'More !',[a,b,c])
    #   Rules: A Clause, followed by optional whitespace, followed by 
    #       ':-', followed by optional whitespace, followed by a list
    #       of clauses separated by commas.
    # 
    #   Whitespace is ignored everywhere except in single quoted atoms

    my($self,$string_ref,$variables) = @_;
    if(!defined($variables)) {$variables = {};}
    my($term);

    # Delete whitespace
    $$string_ref =~ s/\s*//;

    if ($$string_ref =~ m/^\[/) {
	$term = $self->readList($string_ref,$variables);
    } elsif ($$string_ref =~ s/^('[^']+')//) {           #'
        $term = Language::Prolog::Term->newAtom($1);
    } elsif ($$string_ref =~ m/^$SIMPLE_ATOM_REGEX\(/o) {
	$term = $self->readClauseOrRule($string_ref,$variables);
    } elsif ($$string_ref =~ s/^($SIMPLE_ATOM_REGEX)//o) {
	$term = Language::Prolog::Term->newAtom($1);
    } elsif ($$string_ref =~ s/^($VARIABLE_REGEX)//o) {
	$term = $self->variable($variables,$1);
    } else {
	die "Term not recognized";
    }

#    $$string_ref =~ s/^\s*\.// || 
#        die "Statement terminator (.) expected but not found";
    $term;
}

sub variable {
    my($self,$variables,$string) = @_;
    if(!defined($variables)) {$variables = {};}
    my $new;
    if (!$variables->{$string}) {
	$new = Language::Prolog::Term->newVariable($string);
	$variables->{$string} = $new;
    } else {
	$new = Language::Prolog::Term->newVariable($string);
	$new->unify($variables->{$string}) ||
	   die "Error - cannot specify variables to match recursively";
    }
    $new;
}    


sub readList {
    my($self,$string_ref,$variables) = @_;
    my(@terms);

    ($$string_ref =~ s/^\s*\[//) || die "Not a list";

    if ($$string_ref =~ s/^\s*\]//) {
	return Language::Prolog::Term->newList();
    }

    for (;;) {
	$$string_ref =~ s/^\s*//;

	push(@terms,$self->readTerm($string_ref,$variables));

	if ($$string_ref =~ s/^\s*,//) {
	    next;
	} elsif ($$string_ref =~ s/^\s*\]//) {
	    return Language::Prolog::Term->newList(@terms);
	} elsif ($$string_ref =~ s/^\s*\|\s*($VARIABLE_REGEX)\s*\]//o) {
	    return Language::Prolog::Term->newVarList(@terms,
			$self->variable($variables,$1));
	} else {
	    die "Term not recognized";
	}
    }
}

sub readClauseOrRule {
    my($self,$string_ref,$variables) = @_;

    if(!defined($variables)) {$variables = {};}

    my $head = $self->readClause($string_ref,$variables);
    if ($$string_ref =~ s/^\s*:-//) {
	my(@tail);
	for (;;) {
	    $$string_ref =~ s/^\s*//;

	    push(@tail,$self->readClause($string_ref,$variables));

	    if ($$string_ref =~ s/^,//) {
		next;
	    } else {
		return Language::Prolog::Term->newRule($head,@tail);
	    }
	}
    } else {
	return $head;
    }
}

sub readClause {
    my($self,$string_ref,$variables) = @_;
    my(@terms);

    $$string_ref =~ s/^\s*//;

    if ($$string_ref =~ s/^($SIMPLE_ATOM_REGEX)\(//o) {
	push(@terms,Language::Prolog::Term->newAtom($1));
	for (;;) {
	    $$string_ref =~ s/^\s*//;

	    push(@terms,$self->readTerm($string_ref,$variables));

	    if ($$string_ref =~ s/^\s*,//) {
		next;
	    } elsif ($$string_ref =~ s/^\s*\)//) {
		return Language::Prolog::Term->newClause(@terms);
	    } else {
		die "Term not recognized";
	    }
	}
    } elsif ($$string_ref =~ s/^($SIMPLE_ATOM_REGEX)\b//o) {
	return Language::Prolog::Term->newClause(
			   Language::Prolog::Term->newAtom($1));
    } else {
	die "Not a clause";
    }
}


1;
