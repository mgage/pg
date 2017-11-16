#!/usr/bin/perl -w

use lib "/Volumes/WW_test/opt/webwork/pg_2014/lib";
use lib "/Volumes/WW_test/opt/webwork/pg_2014/macros";
use lib "/Volumes/WW_test/opt/webwork/webwork2/lib";

use Test::More;
use Test::Exception;
use Parser;
use Value;
use Class::Accessor;
use PGcore;

#require "PG.pl";
#require "PGbasicmacros.pl";
#require "PGauxiliaryFunctions.pl";
require "tableau.pl";
require "Value.pl"; #gives us Real() etc. 
#require "Parser.pl"; #gives us Context() but also uses loadMacros();
#require "niceTables.pl";



sub Context {Parser::Context->current(\%context,@_)}
unless (%context && $context{current}) {
  # ^variable our %context
  %context = ();  # Locally defined contexts, including 'current' context
  # ^uses Context
  Context();      # Initialize context (for persistent mod_perl)
}

sub WARN_MESSAGE{
	warn("WARN MESSAGE: ", @_);
}

sub DEBUG_MESSAGE{
	warn("DEBUG MESSAGE: ", @_);
}
Context("Matrix");
 
Context()->flags->set(
 	zeroLevel=>1E-5,
 	zeroLevelTol=>1E-5
 );
 
 $A = Real(.0000005);
 $B = Real(0);
 
 is($A,   $B, "test zeroLevel tolerance");
 ok($A==$B, "test zeroLevel tolerance with ok");
 
$land = 1000; #acres

$preservation_costs = 1; #dollars per acre
$preservation_revenue = 30; # dollars per acre
$preservation_profits = $preservation_revenue - $preservation_costs;
$preservation_hours = 12; # hours of labor per acre

$farming_costs = 50; #dollars per acre
$farming_revenue= 190; #dollars per acre 
$farming_profits = $farming_revenue - $farming_costs; # profits
$farming_hours = 240;  # hours of labor per acre


$development_costs = 85; # dollars per acre in permits
$development_revenue = 290; # dollars per acre
$development_profits = $development_revenue - $development_costs;
$development_hours = 180; # hours of labor per acre

$capital = 40E03;  #dollars in capital available
$workers = 75;
$work_hours = 2E03;  #hours of labor per worker

$total_hours = $workers*$work_hours;

$A = Matrix([[1,1,1],
      [$preservation_costs, $farming_costs, $development_costs],
      [$preservation_hours,$farming_hours, $development_hours]]);
$b = Matrix([$land,$capital,$total_hours]);
$c = Matrix([($preservation_profits),
             ($farming_profits), 
             ($development_profits) 
            ]);
$tableau=Tableau->new(A=>$A, b=>$b->transpose, c=>$c);
$primal_align ='|ccc|ccc|cc|';
$primal_toplevel = [qw(x1 x2 x3 x4 x5 x6 w b)];




#### problem starts here:

$tableau->basis(1,2,5);
diag($tableau->current_tableau);
is_deeply $tableau->current_tableau, '[[228,0,60,240,0,-1,0,90000],[0,228,168,-12,0,1,0,138000],[0,0,10920,360,228,-49,0,2.13E+06],[0,0,-21480,5280,0,111,228,2.193E+07]]', "check initial state";

diag($tableau->find_pivot_column('max'), "next pivot column");
is_deeply [$tableau->find_pivot_column('max')],   [3, -21480,0], "find next pivot column";
diag($tableau->find_pivot_row(3), "next pivot row");
is_deeply [$tableau->find_pivot_row(3)],          [3, 195.055,0], "find pivot row";
diag($tableau->find_next_pivot('max'), "next pivot");
is_deeply [$tableau->find_next_pivot('max')], [3,3,0,0], "find next pivot";
diag($tableau->find_next_basis_from_pivot(3,3), "next basis from pivot");
diag("current basis is ", $tableau->basis);
diag("leaving column is " , $tableau->find_leaving_column(3) );
diag($tableau->find_next_basis('max'), "find next basis");
is_deeply [$tableau->find_next_basis('max')], [1,2,3,undef], "find next basis";


done_testing();