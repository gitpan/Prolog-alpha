# Author: Jack Shirazi
# Version: alpha1
########################################
package Language::Prolog;

# A prolog object is a term. There are three main types of terms in prolog:
#  Atoms
#  Variables
#  Lists
# 
# Other types of objects are really specialized types of lists:
#   A Clause is a list of terms with the first item being an atom
#   A Rule is a list of Clauses with the first item being the head
#     and the the rest the tail.
#
# 

use Language::Prolog::Atom ;
use Language::Prolog::Clause ;
use Language::Prolog::IndexStack ;
use Language::Prolog::Interpreter ;
use Language::Prolog::List ;
use Language::Prolog::Query ;
use Language::Prolog::Rule ;
use Language::Prolog::Stack ;
use Language::Prolog::Term ;
use Language::Prolog::VarList ;
use Language::Prolog::Variable ;

1;
