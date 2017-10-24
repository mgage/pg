#!/usr/bin/perl -w

use lib "/Volumes/WW_test/opt/webwork/pg_2014/lib";
use lib "/Volumes/WW_test/opt/webwork/pg_2014/macros";
use lib "/Volumes/WW_test/opt/webwork/webwork2/lib";

use Test::More;
use Test::Exception;
use Parser;
use Value;
use Class::Accessor;
#use PGcore;

require "tableau.pl";
require "Value.pl"; #gives us Real() etc. 
#require "Parser.pl"; #gives us Context() but also uses loadMacros();
require "niceTables.pl";

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

Context("Matrix");
 
Context()->flags->set(
 	zeroLevel=>1E-5,
 	zeroLevelTol=>1E-5
 );
 
 $A = Real(.0000005);
 $B = Real(0);
 
 is($A,   $B, "test zeroLevel tolerance");
 ok($A==$B, "test zeroLevel tolerance with ok");
 
$money_total = 6000;
$time_total  = 600;

# Bill
$bill_money_commitment = 5000; #dollars
$bill_time_commitment  = 400;  # hours
$bill_profit = 4700;
# Steve
$steve_money_commitment = 3000;
$steve_time_commitment  = 500;
$steve_profit = 4500;



#### problem starts here:
               
# need error checking to make sure that tableau->new checks
# that inputs are matrices
$ra_matrix = [[-$bill_money_commitment,-$bill_time_commitment, -1, 0, 	   1,0,0,-$bill_profit], 
                 [-$steve_money_commitment,-$steve_time_commitment, 0, -1, 0,1,0,-$steve_profit],
                 [-$money_total,-$time_total,0,0, 0,0, 1,0]];
$A = Value::Matrix->new([[-$bill_money_commitment,-$bill_time_commitment, -1, 0],
             [ -$steve_money_commitment,-$steve_time_commitment, 0, -1 ]]);
$b = Value::Vector->new([-$bill_profit,-$steve_profit]); # need vertical vector
$c = Value::Vector->new([$money_total,$time_total,0,0]);

$tableau1 = Tableau->new(A=>$A, b=>$b,  c=>$c); 
###############################################################
# Check mutators
#
#
###############################################################

ok (1==1, "trivial first test");
ok (defined($tableau1), 'tableau has been defined and loaded');
is (ref($tableau1), "Tableau", 'has type Tableau' );
is ($tableau1->{m}, 2,  'number of constraints is 2');
is ($tableau1->{n}, 4,  'number of variables is 4');
is_deeply ( [$tableau1->{m},$tableau1->{n}], [$tableau1->{A}->dimensions], '{m},{n} match dimensions of A');
is_deeply ($tableau1->{A}, $A,  'constraint matrix');
is_deeply ($tableau1->{b}, Matrix([$b])->transpose,  'constraint constants is m by 1 matrix');
is_deeply ($tableau1->{c}, $c,  'objective function constants'); 
is_deeply ($tableau1->{A}, $tableau1->A,  '{A} original constraint matrix accessor');
is_deeply ($tableau1->{b}, $tableau1->b,  '{b} orginal constraint constants accessor');
is_deeply ($tableau1->{c}, $tableau1->c,  '{c} original objective function constants accessor'); 

my $test_constraint_matrix = Matrix($ra_matrix->[0],$ra_matrix->[1]);
is_deeply ($tableau1->{current_constraint_matrix}, $test_constraint_matrix,
            'initialization of current_constraint_matrix');
is_deeply($tableau1->{current_constraint_matrix}, $tableau1->current_constraint_matrix,
            'current_constraint_matrix accessor');
is_deeply ($tableau1->{current_b}, $tableau1->{b},
            'initialization of current_b');
is_deeply ($tableau1->{current_b}, $tableau1->current_b,
            'current_b accessor');
is_deeply ([$tableau1->current_b->dimensions], [2,1], 'dimensions of current_b');
my $obj_row_test = [ ((-$c)->value, 0,0,1,0) ];
is_deeply ($tableau1->objective_row, $obj_row_test, 
            'initialization of $tableau->{obj_row}');

is( ref($tableau1->{obj_row}), 'Value::Matrix', '->{obj_row} has type Value::Matrix');
is(ref($tableau1->obj_row), 'Value::Matrix', '->obj_row has type Value::Matrix');
is_deeply($tableau1->obj_row, $tableau1->{obj_row}, 'verify mutator for {obj_row}');
is_deeply( ref($tableau1->objective_row), 'ARRAY', '->objective_row has type ARRAY');
is_deeply( $tableau1->objective_row, [$tableau1->{obj_row}->value], 'access to {obj_row}');
is_deeply( $tableau1->objective_row, [$tableau1->obj_row->value], 'objective_row is obj_row->value = ARRAY');

is(ref($tableau1->current_tableau), 'Value::Matrix', '-> current_tableau is Value::Matrix');
is_deeply($tableau1->current_tableau, Matrix($ra_matrix), 'entire tableau including obj coeff row');

is(ref($tableau1->S), "Value::Matrix", 'slack variables are a Value::Matrix');
is_deeply($tableau1->S, $tableau1->I($tableau1->m), 'slack variables are identity matrix');


# test basis 
is_deeply(ref($tableau1->basis_columns), "ARRAY", "{basis_column} has type ARRAY");
is_deeply($tableau1->basis_columns, [5,6], "initialization of basis");
is(ref($tableau1->current_basis_matrix), ref(Value::Matrix->I($tableau1->m) ),
     "current_basis_matrix type is MathObjectMatrix");
is_deeply($tableau1->current_basis_matrix, Value::Matrix->I($tableau1->m), 
     "initialization of basis");

# change basis and test again
$tableau1->basis(2,3);
is_deeply(ref($tableau1->basis_columns), "ARRAY", "{basis_column} has type ARRAY");
is_deeply($tableau1->basis_columns, [2,3], " basis columns set to {2,3}");
is(ref($tableau1->current_basis_matrix), ref( $test_constraint_matrix->column_slice(2,3) ), 
     "current_basis_matrix type is MathObjectMatrix");
is_deeply($tableau1->current_basis_matrix, $test_constraint_matrix->column_slice(2,3), 
     "basis_matrix for columns {2,3} is correct"  );
is_deeply( $tableau1->basis(Set(2,3)), List([2,3]),  "->basis(Set(2,3))" );
is_deeply( $tableau1->basis(List(2,3)), List([2,3]), "->basis(List(2,3))" );
is_deeply( $tableau1->basis([2,3]), List([2,3]),     "->basis([2,3])" );

# find basis column index corresponding to row index (and value of the basis coefficient)

$tableau1->basis(5,6);
diag("\nbasis is", $tableau1->basis(5,6));
diag(print $tableau1->current_tableau,"\n");
is_deeply([$tableau1->find_leaving_column(1)],  [5,1], "find_leaving_column returns [col_index, pivot_value] " );
is_deeply([$tableau1->find_leaving_column(2)],  [6,1], "find_leaving_column returns [col_index, pivot_value] " );

is_deeply($tableau1->find_next_basis_from_pivot(1,2), Set(2,6), 
   "find next basis from pivot (1,2)");
is_deeply($tableau1->find_next_basis_from_pivot(1,3), Set(3,6), 
   "find next basis from pivot (1,3)");
is_deeply($tableau1->find_next_basis_from_pivot(2,1), Set(1,5), 
    "find next basis from pivot (2,1)");
 is_deeply($tableau1->find_next_basis_from_pivot(1,1), Set(1,6), 
    "find next basis from pivot (1,1)");

throws_ok(sub {$tableau1->find_next_basis_from_pivot(2,5)}, qr/pivot point should not be in a basis column/, 
   "can't pivot in basis column (2,5)"); # probably shouldn't be doing this.
throws_ok(sub {$tableau1->find_next_basis_from_pivot(1,6)}, qr/pivot point should not be in a basis column/, 
   "can't pivot in basis column (2,6)"); # probably shouldn't be doing this.
is_deeply($tableau1->find_next_basis_from_pivot(2,1), Set(1,5), 
    "find next basis from pivot (2,1)");
throws_ok(sub {$tableau1->find_next_basis_from_pivot(2,6)}, qr/pivot point should not be in a basis column/, 
   "can't pivot in basis column (2,6)"); # probably shouldn't be doing this.


$tableau1->basis(2,3);
diag("\nbasis is", $tableau1->basis());
diag(print $tableau1->current_tableau,"\n");
is_deeply([$tableau1->find_leaving_column(1)],  [2,500], "find_leaving_column returns [col_index, pivot_value] " );
is_deeply([$tableau1->find_leaving_column(2)],  [3,500], "find_leaving_column returns [col_index, pivot_value] " );

throws_ok(sub {$tableau1->find_next_basis_from_pivot(1,2)}, qr/pivot point should not be in a basis column/, 
   "can't pivot in basis column (1,2)"); # probably shouldn't be doing this either.
throws_ok(sub {$tableau1->find_next_basis_from_pivot(1,3)}, qr/pivot point should not be in a basis column.*/, 
   "can't pivot in basis column (1,3)"); # probably shouldn't be doing this.
is_deeply($tableau1->find_next_basis_from_pivot(2,1), Set(1,2), 
    "find next basis from pivot (2,1)");
 is_deeply($tableau1->find_next_basis_from_pivot(1,1), Set(1,3), 
    "find next basis from pivot (1,1)");

$tableau1->basis(5,6);
diag("\nbasis is ", $tableau1->basis());
diag($tableau1->current_tableau,"\n");
diag("find next short cut pivots");
# ($row_index, $value, $feasible_point) = $self->find_short_cut_row()
is_deeply([$tableau1->find_short_cut_row()], [1,-4700,0], "row 1");
is_deeply([$tableau1->find_short_cut_column(1)], [1,-5000,0], "column 1 ");
is_deeply([$tableau1->find_next_short_cut_pivot()], [1,1,0,0], "pivot (1,1)");
is_deeply([$tableau1->find_next_short_cut_basis()],[1,6,0,0], "new basis {1,6} continue");
$tableau1->current_tableau(1,6);
diag($tableau1->current_tableau);

is_deeply([$tableau1->find_short_cut_row],[2,Value::Real->new(-8.4E+06),0], "find short cut row");
is_deeply([$tableau1->find_short_cut_column(2)], [2,Value::Real->new(-1.3E+06),0], "find short cut col 2 ");
is_deeply([$tableau1->find_next_short_cut_pivot()], [2,2,0,0], "pivot (2,2)");
is_deeply([$tableau1->find_next_short_cut_basis()],[1,2,0,0], "new basis {1,2} continue");

$tableau1->current_tableau(1,2);
diag($tableau1->current_tableau);



is_deeply([$tableau1->find_next_short_cut_pivot()],[undef,undef,1,0], "feasible point found");
is_deeply([$tableau1->find_next_short_cut_basis()],[1,2,1,0], 
 "all constraints positive at basis {1,2} --start phase2");
is_deeply([$tableau1->find_pivot_column('max')], [5,Value::Real->new(-1.2E+06),0],  "col 5");
is_deeply([$tableau1->find_pivot_row(5)], [2,Value::Real->new(8.4E06/3000),0], "row 2 ");
is_deeply([$tableau1->find_next_pivot('max')], [2,5,0,0], "pivot (2,5)");
is_deeply([$tableau1->find_next_basis('max')],[1,5,0,0], "new basis {1,5} continue");

$tableau1->current_tableau(1,5);
diag($tableau1->current_tableau);
is_deeply([$tableau1->find_pivot_column('max')], [6,Value::Real->new(-6000),0],  "col 6");
is_deeply([$tableau1->find_pivot_row(6)], [-1,undef,1], "unbounded ");

is_deeply([$tableau1->find_next_pivot('max')], [-1,6,0,1], "unbounded");
# this is ok -- we're looking at the dual of the bill and steve problem 
# and the original test was to minimize it not to maximize it
# recheck the original problem with websim!!!!

# regularize the output for row and column definitions if one of the flags is set.
# can we always set those to undefined?
# can we change the flag notification to 
# "unbounded, feasible_point, infeasible_tableau, optimal"?
# it might be easier to remember. 

diag("reset tableau to feasible point and try to minimize it for phase2");
$tableau1->current_tableau(1,2);
diag($tableau1->current_tableau);
is_deeply([$tableau1->find_next_short_cut_pivot()],[undef,undef,1,0], "feasible point found");
is_deeply([$tableau1->find_next_short_cut_basis()],[1,2,1,0], 
 "all constraints positive at basis {1,2} --start phase2");
 
is_deeply([$tableau1->find_pivot_column('min')], [3,Value::Real->new(1.2E+06),0],  "col 3");
is_deeply([$tableau1->find_pivot_row(3)], [1,Value::Real->new(550000/500),0], "row 1 ");
is_deeply([$tableau1->find_next_pivot('min')], [1,3,0,0], "pivot (1,3)");
is_deeply([$tableau1->find_next_basis('min')],[2,3,0,0], "new basis {2,3} continue");



$tableau1->current_tableau(2,3);
diag($tableau1->current_tableau);

is_deeply([$tableau1->find_pivot_column('min')], [4,Value::Real->new(600),0],  "col 4");
is_deeply([$tableau1->find_pivot_row(4)], [1,Value::Real->new(4500),0], "row 1 ");
is_deeply([$tableau1->find_next_pivot('min')], [1,4,0,0], "pivot (1,4)");
is_deeply([$tableau1->find_next_basis('min')],[3,4,0,0], "new basis {3,4} continue");

$tableau1->current_tableau(3,4);
diag($tableau1->current_tableau);

is_deeply([$tableau1->find_pivot_column('min')], [-1,undef,1],  "optimum");
#is_deeply([$tableau1->find_pivot_row(4)], [1,Value::Real->new(4500),0], "row 1 ");
is_deeply([$tableau1->find_next_pivot('min')], ['',-1,1,undef], "pivot (1,4) optimum");
is_deeply([$tableau1->find_next_basis('min')],[3,4,1,undef], " basis {3,4} optimum");

done_testing();