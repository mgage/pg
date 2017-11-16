#!/usr/bin/perl -w


=pod

Test primal-dual pairing subroutines




=cut
use lib "/Volumes/WW_test/opt/webwork/pg_2014/lib";
use lib "/Volumes/WW_test/opt/webwork/pg_2014/macros";
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
 
 
$a11 = 1; $a12 = 0; 
$a21 = 0; $a22 = 2; 
$a31 = 3; $a32 =1;
$b1= 4; $b2=12; $b3=18;
$c1 = -3; $c2=-5;

$A = Matrix([[$a11, $a12],
             [ $a21, $a22],
             [ $a31, $a32]]);
$b = Vector([$b1, $b2, $b3]); # need vertical vector
$c = ColumnVector([$c1, $c2]);



$tableau = Tableau->new(A=>$A, b=>$b,  c=>$c);
# slack variables are automatically added


#$toprow = [qw(y1 y2 y3 y4 s1 s2 P b) ];
#$align  = "cccc|cc|c|c";

diag($tableau->current_tableau);
diag("m (constraints) is ", $tableau->m); 
diag("n (variables) is ", $tableau->n);
is_deeply( [$tableau->primal2dual(1,2,3,4,5 )], [4,5,1,2,3], "primal to dual pairing, m=3, n=2");
is_deeply( [$tableau->dual2primal(1,2,3,4,5 )], [3,4,5,1,2], "dual to primal pairing, m=3, n=2");
is_deeply([$tableau->dual2primal($tableau->primal2dual(1,2,3,4,5))],[1,2,3,4,5], "primal to dual to primal");
is_deeply([$tableau->primal2dual(4,5)],[2,3], "test primary dual basis switch");
diag($tableau->primal2dual(4,5));
done_testing();
