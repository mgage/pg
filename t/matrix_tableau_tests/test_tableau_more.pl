#!/usr/bin/perl -w

use lib "/Volumes/WW_test/opt/webwork/pg_2014/lib";
use lib "/Volumes/WW_test/opt/webwork/pg_2014/macros";
use lib "/Volumes/WW_test/opt/webwork/webwork2/lib";

use Test::More;
use Parser;
use Value;
require "tableau.pl";
require "Value.pl";



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

ok (1==1, "trivial first test");
ok (defined($tableau1), 'tableau has been defined and loaded');
is ($tableau1->{m}, 2,  'number of constraints is 2');
is ($tableau1->{n}, 4,  'number of variables is 4');
is_deeply ( [$tableau1->{m},$tableau1->{n}], [$tableau1->{A}->dimensions], '{m},{n} match dimensions of A');
is_deeply ($tableau1->{A}, $A,  'constraint matrix');
is_deeply ($tableau1->{b}, Matrix([$b])->transpose,  'constraint constants is m by 1 matrix');
is_deeply ($tableau1->{c}, $c,  'objective function constants'); 
my $test_constraint_matrix = Matrix($ra_matrix->[0],$ra_matrix->[1]);
is_deeply ($tableau1->{current_constraint_matrix}, $test_constraint_matrix,
            'initialization of current_constraint_matrix');
is_deeply ($tableau1->{current_b}, $tableau1->{b},
            'initialization of current_b');
my $obj_row_test = [ ((-$c)->value, 0,0,1,0) ];
is_deeply ($tableau1->objective_row, $obj_row_test, 
            'initialization of $tableau->{obj_row}');
is_deeply( ref($tableau1->objective_row), 'ARRAY', '->objective_row has type ARRAY');
is_deeply( ref($tableau1->{obj_row}), 'Value::Matrix', '->{obj_row} has type Value::Matrix');

is_deeply( $tableau1->objective_row, [$tableau1->{obj_row}->value], 'access to {obj_row}');
is_deeply($tableau1->current_tableau, Matrix($ra_matrix), 'entire tableau including obj coeff row');
is(ref($tableau1->current_tableau), 'Value::Matrix', '-> current_tableau is Value::Matrix');

# check accessors?  Use antlers?
            
done_testing();