#!/usr/bin/perl -w 

# this file needs documentation and unit testing.
# where is it used?

##### From gage_matrix_ops
# 2014_HKUST_demo/templates/setSequentialWordProblem/bill_and_steve.pg:"gage_matrix_ops.pl",

=head1 NAME

	macros/tableau.pl
	
	

=head2 DESCRIPTION

 # We're going to have several types
 # MathObject Matrices  Value::Matrix
 # tableaus form John Jones macros
 # MathObject tableaus
 #   Containing   an  matrix $A  coefficients for constraint
 #   A vertical vector $b for constants for constraints
 #   A horizontal vector $c for coefficients for objective function
 #   A vertical vector corresponding to the  value  $z of the objective function
 #   dimensions $n problem vectors, $m constraints = $m slack variables
 #   A basis Value::Set -- positions for columns which are independent and 
 #      whose associated variables can be determined
 #      uniquely from the parameter variables.  
 #      The non-basis (parameter) variables are set to zero. 
 #
 #  state variables (assuming parameter variables are zero or when given parameter variables)
 # create the methods for updating the various containers
 # create the method for printing the tableau with all its decorations 
 # possibly with switches to turn the decorations on and off. 


The structure of the tableau is: 

	-----------------------------------------------------------
	|                    |             |    |    |
	|          A         |    S        | 0  | b  |
	|                    |             |    |    |
	----------------------------------------------
	|        -c          |     0       | 1  | 0  |
	----------------------------------------------
	Matrix A, the constraint matrix is n=num_problem_vars by m=num_slack_vars
	Matrix S, the slack variables is m by m
	Matrix b, the constraint constants is n by 1
	Matrix c, the objective function coefficients matrix is 1 by n or 2 by n
	The next to the last column holds z or objective value
	z(...x^i...) = c_i* x^i  (Einstein summation convention)
	FIXME:  allow c to be a 2 by n matrix so that you can do phase1 calculations easily 


=cut


=head2 Package main

=cut


=item tableauEquivalence 

	ANS( $tableau->cmp(checker=>tableauEquivalence()) ); 
	
 # Note: it is important to include the () at the end of tableauEquivalence
 
 # tableauEquivalence is meant to compare two matrices up to
 # reshuffling the rows and multiplying each row by a constant.
 # E.g. equivalent up to multiplying on the left by a permuation matrix 
 # or a (non-uniformly constant) diagonal matrix
 
=cut

=item  get_tableau_variable_values
 
	Parameters: ($MathObjectMatrix_tableau, $MathObjectSet_basis)
	Returns: ARRAY or ARRAY_ref 
	
Returns the solution variables to the tableau assuming 
that the parameter (non-basis) variables 
have been set to zero. It returns a list in 
array context and a reference to 
an array in scalar context. 

=item  lp_basis_pivot
	
	Parameters: ($old_tableau,$old_basis,$pivot)
	Returns: ($new_tableau, Set($new_basis),\@statevars)
	
=item linebreak_at_commas

	Parameters: ()
	Return:
	
	Useage: 
	$foochecker =  $constraints->cmp()->withPostFilter(
		linebreak_at_commas()
    );

Replaces commas with line breaks in the latex presentations of the answer checker.
Used most often when $constraints is a LinearInequality math object.



=head2 Package tableau

=item  Tableau->new(A=>Matrix, b=>Vector or Matrix, c=>Vector or Matrix)

	A => undef, # original constraint matrix  MathObjectMatrix
	b => undef, # constraint constants Vector or MathObjectMatrix 1 by n
	c => undef, # coefficients for objective function Vector or MathObjectMatrix 1 by n
	obj_row => undef, # contains the negative of the coefficients of the objective function.
	z => undef, # value for objective function
	n => undef, # dimension of problem variables (columns in A)
	m => undef, # dimension of slack variables (rows in A)
	S => undef, # square m by m matrix for slack variables
	M => undef,  # matrix of consisting of all original columns and all 
		rows except for the objective function row 
	obj_col_num => undef,
	basis => undef, # list describing the current basis columns corresponding 
		to determined variables.
	current_basis_matrix => undef,  # square invertible matrix 
		corresponding to the current basis columns
 
	current_constraint_matrix=>undef, # the current version of [A | S]
	current_b,                        # the current version of the constraint constants b
 #	current_basis_matrix              # (should be new name for B above
 #                                    # a square invertible matrix corresponding to the 
 #	                                  # current basis columns)
	# flag indicating the column (1 or n+m+1) for the objective value
	constraint_labels => undef,   (not sure if this remains relevant after pivots)
	problem_var_labels => undef, 
	slack_var_labels => undef,

=item  $self->current_tableau
		Parameters: ()
		Returns:  A MathObjectMatrix_tableau
		
This represents the current version of the tableau

=item  $self->objective_row
		Parameters: ()
		Returns: 

=item  $self->basis
		Parameter: ARRAY or ARRAY_ref or ()
		Returns: MathObject_list
		
		FiXME -- this should accept a MathObject_List (or MO_Set?)
		
=head3 Package Tableau (eventually package Matrix?)

=item  $self->row_slice

		Parameter: @slice or \@slice 
		Return: MathObject matrix

=item  $self->extract_rows

		Parameter: @slice or \@slice 
		Return: two dimensional array ref 
		
=item  extract_rows_to_list

		Parameter: @slice or \@slice 
		Return: MathObject List of row references

=item   $self->extract_columns

		Parameter: @slice or \@slice 
		Return: two dimensional array ref 

=item  $self->column_slice

		Parameter: @slice or \@slice 
		Return: MathObject Matrix

=item  $self->extract_columns_to_list

		Parameter: @slice or \@slice 
		Return: MathObject List of Matrix references ?

=item $self->submatrix

		Parameter:(rows=>\@row_slice,columns=>\@column_slice)
		Return: MathObject matrix
		
=cut 

=head3 References:

MathObject Matrix methods: L<http://webwork.maa.org/wiki/Matrix_(MathObject_Class)>
MathObject Contexts: L<http://webwork.maa.org/wiki/Common_Contexts>
CPAN RealMatrix docs: L<http://search.cpan.org/~leto/Math-MatrixReal-2.09/lib/Math/MatrixReal.pm>

More references: L<lib/Matrix.pm>

=cut


sub _tableau_init {};   # don't reload this file

# loadMacros("tableau_main_subroutines.pl");


=head4 Subroutines added to the main:: Package


=cut

=item tableauEquivalence



=cut

sub tableauEquivalence {
	return sub {
		my ($correct, $student, $ansHash) = @_;
		# DEBUG_MESSAGE("executing tableau equivalence");
		# convert matrices to arrays of row references
		my @rows1 = matrix_extract_rows($correct);
		my @rows2 = matrix_extract_rows($student);
		# compare the rows as lists with each row being compared as 
		# a parallel Vector (i.e. up to multiples)
		my $score = List(@rows1)->cmp( checker =>
				sub {
					my ($listcorrect,$liststudent,$listansHash,$nth,$value)=@_;
					my $listscore = Vector($listcorrect)->cmp(parallel=>1)
						  ->evaluate(Vector($liststudent))->{score};
					return $listscore;
				}
		)->evaluate(List(@rows2))->{score};
		return $score;
	}
 }

=item linebreak_at_commas
	
	Useage: 
	
	$foochecker =  $constraints->cmp()->withPostFilter(
 		linebreak_at_commas()
 	);

=cut


sub linebreak_at_commas {
	return sub {
		my $ans=shift;
		my $foo = $ans->{correct_ans_latex_string};
		$foo =~ s/,/,\\\\\\\\/g;
		($ans->{correct_ans_latex_string})=~ s/,/,\\\\\\\\/g;
		($ans->{preview_latex_string})=~ s/,/,\\\\\\\\/g;
		#DEBUG_MESSAGE("foo", $foo);
		#DEBUG_MESSAGE( "correct", $ans->{correct_ans_latex_string} );
		#DEBUG_MESSAGE( "preview",  $ans->{preview_latex_string} );
		#DEBUG_MESSAGE("section4ans1 ", pretty_print($ans, $displayMode));
		$ans;
	};
}

=item linebreak_at_commas
	
	Useage: 
	
	lop_display($tableau, align=>'cccc|cc|c|c', toplevel=>[qw(x1,x2,x3,x4,s1,s2,P,b)])
 	
Pretty prints the output of a matrix as a LOP with separating labels and 
variable labels.

=cut
sub lop_display {
	my $tableau = shift;
	%options = @_;
	$options{alignment} = ($options{alignment})? $options{alignment}:"|ccccc|cc|c|c|";
	@toplevel = ();
	if (exists( ($options{toplevel})) ) {
		@toplevel = @{$options{toplevel}};
		$toplevel[0]=[$toplevel[0],headerrow=>1, midrule=>1];
	}
	@matrix = $tableau1->current_tableau->value;
	$last_row = $#matrix; # last row is objective coefficients 
	$matrix[$last_row-1]->[0]=[$matrix[$last_row-1]->[0],midrule=>1];
	$matrix[$last_row]->[0]=[$matrix[$last_row]->[0],midrule=>1];
	DataTable([[@toplevel],@matrix],align=>$options{alignment}); 
}


##################################################
package Tableau;
our @ISA = qw(Value::Matrix Value);

sub class {"Matrix"};
 
sub _Matrix {    # can we just import this?
	Value::Matrix->new(@_);
}

sub new {
	my $self = shift; my $class = ref($self) || $self;
	my $context = (Value::isContext($_[0]) ? shift : $self->context);
	my $tableau = {
		A => undef, # constraint matrix  MathObjectMatrix
		b => undef, # constraint constants Vector or MathObjectMatrix 1 by n
		c => undef, # coefficients for objective function  MathObjectMatrix 1 by n or 2 by n matrix
		obj_row => undef, # contains the negative of the coefficients of the objective function.
		z => undef, # value for objective function
		n => undef, # dimension of problem variables (columns in A)
		m => undef, # dimension of slack variables (rows in A)
		S => undef, # square m by m matrix for slack variables
		basis => undef, # list describing the current basis columns corresponding to determined variables.
		B => undef,  # square invertible matrix corresponding to the current basis columns
		M => undef,  # matrix of consisting of all columns and all rows except for the objective function row
		current_constraint_matrix=>undef,
		current_coeff=>undef,
		current_b => undef,
		obj_col_index => undef, # an array reference indicating the columns (e.g 1 or n+m+1) for the objective value or values
		constraint_labels => undef,
		problem_var_labels => undef, 
		slack_var_labels => undef,

		@_,
	};
	bless $tableau, $class;
	$tableau->initialize();
	return $tableau;
}


# the following are used to construct the tableau
# initialize
# assemble_matrix
# objective_row

sub initialize {
	$self= shift;
	unless (ref($self->{A}) =~ /Value::Matrix/ &&
	        ref($self->{b}) =~ /Value::Vector|Value::Matrix/ && 
	        ref($self->{c}) =~ /Value::Vector|Value::Matrix/){
		Value::Error ("Error: Required inputs for creating tableau:\n". 
		"Tableau(A=> Matrix, b=>ColumnVector or Matrix, c=>Vector or Matrix)");
	}
	my ($m, $n)=($self->{A}->dimensions);
	$self->{n}=$self->{n}//$n;
	$self->{m}=$self->{m}//$m;
	# main::DEBUG_MESSAGE("m $m, n $n");
	$self->{S} = Value::Matrix->I($m);
	$self->{basis} = [($n+1)...($n+$m)] unless ref($self->{basis})=~/ARRAY/;
	
	my @rows = $self->assemble_matrix;
	# main::DEBUG_MESSAGE("rows", map {ref($_)?$_->value :$_} map {@$_} @rows);
	$self->{M} = _Matrix([@rows]); #original matrix
	$self->{current_constraint_matrix}= $self->{M};
	$self->{data}= $self->{M}->data;
	$self->{current_basis_matrix} = $self->{M}->submatrix(rows=>[1..($self->{m})],columns=>$self->{basis});
	$self->{obj_row} = _Matrix(@{$self->objective_row()});
	$self->basis($self->basis()->value);
	return();	
}
		
sub assemble_matrix {
	my $self = shift;
	my @rows =();
	my $m = $self->{m};
	my $n = $self->{n};
	# sanity check for b;
	if (ref($self->{b}) =~/Vector/) {
		# replace by n by 1 matrix
		$self->{b}=Value::Matrix->new([[$self->{b}->value]])->transpose;
	}
	my ($constraint_rows, $constraint_cols) = $self->{b}->dimensions;
	unless ($constraint_rows== $m and $constraint_cols == 1 ) {
		Value::Error("constraint matrix b is $constraint_rows by $constraint_cols but should
		be $m by 1 to match the constraint matrix A ");
	}

	foreach my $i (1..$m) {
		my @current_row=();
		foreach my $j (1..$n) {
			push @current_row, $self->{A}->element($i, $j)->value;
		}
		foreach my $j (1..$m) {
			push @current_row, $self->{S}->element($i,$j)->value; # slack variables
		}
		push @current_row, 0, $self->{b}->row($i)->value;    # obj column and constant column
		push @rows, [@current_row]; 
	}

	return @rows;   # these are the matrices A | S | obj | b   
	                # the final row describing the objective function 
	                # is not in this part of the matrix
}

sub objective_row {
	my $self = shift;
	# sanity check for objective row
	
	
	my @last_row=();
	push @last_row, ( -($self->{c}) )->value;  # add the negative coefficients of the obj function
	foreach my $i (1..($self->{m})) { push @last_row, 0 }; # add 0s for the slack variables
	push @last_row, 1, 0; # add the 1 for the objective value and 0 for the initial value
	return \@last_row;
}

=item current_tableau

	Useage:
		$MathObjectmatrix = $self->current_tableau
		$MathObjectmatrix = $self->current_tableau(3,4) #updates basis to (3,4)
		
Returns the current constraint matrix, including the constraint constants AND the 
row containing the objective function coefficients. 
		
=cut
sub current_tableau {
	my $self = shift;
	my @basis = @_;
	if (@basis) {
		$self->basis(@basis);
	}
	# find the coefficients associated with the basis columns
	my $c_B  = $self->{obj_row}->extract_columns($self->{basis} );
	my $c_B2 = Value::Vector->new([ map {$_->value} @$c_B]);
#	my $current_constraint_matrix = $self->{current_constraint_matrix};
#	my $B = $self->{current_basis_matrix};
	#main::DEBUG_MESSAGE( "basis: current_constraint_matrix $current_constraint_matrix");
	#main::DEBUG_MESSAGE( "current_tableau: matrix is $current_constraint_matrix");
	#main::DEBUG_MESSAGE( "current_basis matrix: $B");
#	my $correction_coeff = ($c_B2*($self->{current_constraint_matrix}) )->row(1);
	# subtract the correction coefficients from the obj_row
	# this essentially extends Gauss reduction applied to the obj_row
#	my $obj_row_normalized =  abs($self->{current_basis_matrix}->det->value)*$self->{obj_row};
	#main::DEBUG_MESSAGE(" normalized obj row ",$obj_row_normalized->value);
	#main::DEBUG_MESSAGE(" correction coeff ", $correction_coeff->value);
#	my $current_coeff = $obj_row_normalized-$correction_coeff ;
#	$self->{current_coeff}= $current_coeff; 

	#main::DEBUG_MESSAGE("subtract these two ", (($self->{current_basis_matrix}->det) *$self->{obj_row}), " | ", ($c_B*$current_tableau)->dimensions);
	#main::DEBUG_MESSAGE("all coefficients", join('|', $self->{obj_row}->value ) );
	#main::DEBUG_MESSAGE("current coefficients", join('|', @current_coeff) );
    #main::DEBUG_MESSAGE("type of $self->{basis}", ref($self->{basis}) );
	#main::DEBUG_MESSAGE("current basis",join("|", @{$self->{basis}}));
	#main::DEBUG_MESSAGE("CURRENT STATE ", $current_tableau);
	return _Matrix( @{$self->{current_constraint_matrix}->extract_rows},$self->{current_coeff} );
	#return( $self->{current_coeff} );
}

sub basis {
	my $self = shift;  #update basis
	                   # basis is stored as an ARRAY reference. 
	                   # basis is exported as a list
	                   # FIXME should basis be sorted?
	Value::Error( "call basis as a method") unless ref($self)=~/Tableau/;
	my @input = @_;
	return Value::List->new($self->{basis}) unless @input;  #return basis if no input
	my $new_basis;
	if (ref( $input[0]) =~/ARRAY/) {
		$new_basis=$input[0];
	} elsif (ref( $input[0]) =~/List|Set/){
		$new_basis = $input[0]->value;
	} else { # input is assumed to be an array
		$new_basis = \@input;
	}
	$self->{basis}= $new_basis;  # this should always be an ARRAY
	WARN_MESSAGE("basis $new_basis was not stored as an array reference") 
	     unless ref($new_basis)=~/ARRAY/;
	
	
	$self->{current_basis_matrix} = $self->{M}->submatrix(rows=>[1..($self->{m})],columns=>$self->{basis});
	my $B = $self->{current_basis_matrix};
	#main::DEBUG_MESSAGE("basis: B is $B" );
	my $Badj = abs($self->{current_basis_matrix}->det->value) * ($self->{current_basis_matrix}->inverse);
	my $M = $self->{M};
	my ($row_dim, $col_dim) = $M->dimensions;
	my $current_constraint_matrix = $Badj*$M;
	my $c_B  = $self->{obj_row}->extract_columns($self->{basis} );
	my $c_B2 = Value::Vector->new([ map {$_->value} @$c_B]);
	my $correction_coeff = ($c_B2*($current_constraint_matrix) )->row(1); 
	my $obj_row_normalized =  abs($self->{current_basis_matrix}->det->value)*$self->{obj_row};
	my $current_coeff = $obj_row_normalized-$correction_coeff ;
	# updates
	$self->{current_basis_matrix}= $B;
	$self->{data} = $current_constraint_matrix->data;
	$self->{current_constraint_matrix} = $current_constraint_matrix; 
	$self->{current_coeff}= $current_coeff; 
	$self->{current_b} = $current_constraint_matrix->column($col_dim);
	 # the A | S | obj | b
	# main::DEBUG_MESSAGE( "basis: current_constraint_matrix $current_constraint_matrix ".
	# ref($self->{current_constraint_matrix}) );
	# main::DEBUG_MESSAGE("basis self ",ref($self), "---", ref($self->{basis}));
	return Value::List->new($self->{basis});	
} 


=item find_next_basis 

	($row, $col,$optimum,$unbounded) = $self->find_next_basis (max/min, obj_row_number)
	
In phase 2 of the simplex method calculates the next basis.  
$optimum or $unbounded is set
if the process has found on the optimum value, or the column 
$col gives a certificate of unboundedness.


=cut 


sub find_next_basis {
	my $self = shift;
	my $max_or_min = shift;
	my $obj_row_number = shift;
	my ( $row_index, $col_index, $optimum, $unbounded)= 
	     $self->find_next_pivot($max_or_min, $obj_row_number);
	my $flag;
	my $basis;
	if ($optimum or $unbounded) {
		$basis=$self->basis();
	} else {
		$flag = '';
		$basis =$self->find_next_basis_from_pivot($row_index,$col_index);
		
	}
	return( $basis->value, $optimum,$unbounded );
	
}

=item find_next_pivot

	($row, $col,$optimum,$unbounded) = $self->find_next_pivot (max/minm obj_row_number)
	
This is used in phase2 so the possible outcomes are only $optimum and $unbounded.
$infeasible is not possible.  Use the lowest index strategy to find the next pivot
point. This calls find_pivot_row and find_pivot_column.  $row and $col are undefined if 
either $optimum or $unbounded is set.

=cut

sub find_next_pivot {
	my $self = shift;
	my $max_or_min = shift;
	my $obj_row_number =shift;

	# sanity check max or min in find pivot column
	my ($col_index, $value, $row_index, $optimum, $unbounded) = ('','','','');
	($col_index, $value, $optimum) = $self->find_pivot_column($max_or_min, $obj_row_number);
#	main::DEBUG_MESSAGE("find_next_pivot: col: $col_index, value: $value opt: $optimum ");
	return ( $row_index, $col_index, $optimum, $unbounded) if $optimum;
	($row_index, $value, $unbounded) = $self->find_pivot_row($col_index);
#	main::DEBUG_MESSAGE("find_next pivot row: $row_index, value: $value unbound: $unbounded");
	return($row_index, $col_index, $optimum, $unbounded);
}
	


=item find_next_basis_from_pivot

	List(basis) = $self->find_next_basis (row_index, col_index) 

Calculate the next basis from the current basis given the pivot  position.

=cut  

sub find_next_basis_from_pivot {
	my $self = shift;
	my $row_index = shift;
	my $col_index =shift;
	# sanity check max or min in find pivot column
 	my $basis = main::Set($self->{basis});	
 	my ($leaving_col_index, $value) = $self->find_leaving_column($row_index);
 	$basis = main::Set( $basis - main::Set($leaving_col_index) + main::Set($col_index));
 	# main::DEBUG_MESSAGE( "basis is $basis, leaving index $leaving_col_index
 	#    entering index is $col_index");
 	#$basis = [$basis->value, main::Real($col_index)];
 	return ($basis);
} 



=item find_pivot_column

	($index, $value, $optimum) = $self->find_pivot_column (max/min, obj_row_number)
	
This finds the left most obj function coefficient that is negative (for maximizing)
or positive (for minimizing) and returns the value and the index.  Only the 
index is really needed for this method.  The row number is included because there might
be more than one objective function in the table (for example when using
the Auxiliary method in phase1 of the simplex method.)  If there is no coefficient
of the appropriate sign then the $optimum flag is set and $index and $value
are undefined.

=cut

sub find_pivot_column {
	my $self = shift;
	my $max_or_min = shift;
	my $obj_row_index  = shift;
	# sanity check
	unless ($max_or_min =~ /max|min/) {
		Value::Error( "The optimization method must be 
		'max' or 'min'. |$max_or_min| is not defined.");
	}
	my $obj_row_matrix = $self->{current_coeff};
	#FIXME $obj_row_matrix is this a 1 by n or an n dimensional matrix??
	my ($obj_col_dim) = $obj_row_matrix->dimensions;
	my $obj_row_dim   = 1;
	$obj_col_dim=$obj_col_dim-2;
	#sanity check row	
	if (not defined($obj_row_index) ) {
		$obj_row_index = 1;
	} elsif ($obj_row_index<1 or $obj_row_index >$obj_row_dim){
		Value::Error( "The choice for the objective row $obj_row_index is out of range.");
	} 
	#FIXME -- make sure objective row is always a two dimensional matrix, often with one row.
	

	my @obj_row = @{$obj_row_matrix->extract_rows($obj_row_index)};
	my $index = -1;
	my $optimum = 1;
	my $value = undef;
# 	main::DEBUG_MESSAGE(" coldim: $obj_col_dim , row: $obj_row_index obj_matrix: $obj_row_matrix ".ref($obj_row_matrix) );
# 	main::DEBUG_MESSAGE(" \@obj_row ",  join(' ', @obj_row ) );
	for (my $k=1; $k<=$obj_col_dim; $k++) {
#		main::DEBUG_MESSAGE("find pivot column: k $k, " .$obj_row_matrix->element($k)->value);
		if ( ($obj_row_matrix->element($k) < 0 and $max_or_min eq 'max') or 
		     ($obj_row_matrix->element($k) > 0 and $max_or_min eq 'min') ) {
		    $index = $k; #memorize index
		    $value = $obj_row_matrix->element($k);
		    $optimum = 0;
		    last;        # found first coefficient with correct sign
		 }
	}
	return ($index, $value, $optimum);
}

=item find_pivot_row

	($index, $value, $unbounded) = $self->find_pivot_row(col_number)

Compares the ratio $b[$j]/a[$j, $col_number] and chooses the smallest
non-negative entry.  It assumes that we are in phase2 of simplex methods
so that $b[j]>0; If all entries are negative (or infinity) then
the $unbounded flag is set and returned and the $index and $value
quantities are undefined.

=cut

sub find_pivot_row {
	my $self = shift;
	my $column_index = shift;
	my ($row_dim, $col_dim) = $self->{M}->dimensions;
	$col_dim = $col_dim-2; # omit the obj_value and constraint columns
	# sanity check column_index
	unless (1<=$column_index and $column_index <= $col_dim) {
		Value::Error( "Column index must be between 1 and $col_dim" );
	}
	# main::DEBUG_MESSAGE("dim = ($row_dim, $col_dim)");
	my $value = undef;
	my $index = -1;
	my $unbounded = 1;
	for (my $k=1; $k<=$row_dim; $k++) {
	    my $m = $self->{current_constraint_matrix}->element($k,$column_index);
	    # main::DEBUG_MESSAGE(" m[$k,$column_index] is ", $m->value);
		next if $m <=0;
		my $b = $self->{current_b}->element($k,1);
		# main::DEBUG_MESSAGE(" b[$k] is ", $b->value);
		# main::DEBUG_MESSAGE("finding pivot row in column $column_index, row: $k ", ($b/$m)->value);	
		if ( not defined($value) or $b/$m < $value) {
			$value = $b/$m;
			$index = $k; # memorize index
			$unbounded = 0;
		}
	}
	return( $index, $value, $unbounded);	
}




=item find_leaving_column

	($index, $value) = $self->find_leaving_column(obj_row_number)

Finds the non-basis column with a non-zero entry in the given row. When
called with the pivot row number this index gives the column which will 
be removed from the basis while the pivot col number gives the basis 
column which will become a parameter column.

=cut

sub find_leaving_column {
	my $self = shift;
	my $row_index = shift;
	my ($row_dim,$col_dim) = $self->{current_constraint_matrix}->dimensions;
	$col_dim= $col_dim - 1; # both problem and slack variables are included
	# but not the constraint column or the obj_value column(s) (the latter are zero)
	# FIXME
	#sanity check row index;
	unless (1<=$row_index and $row_index <= $row_dim) {
		Value::Error("The row number must be between 1 and $row_dim" );
	}
	my $basis = main::Set($self->{basis});
	my $index = 0;
	my $value = undef;
	foreach my $k  (1..$col_dim) {
		next unless $basis->contains(main::Set($k));
		$m_ik = $self->{current_constraint_matrix}->element($row_index, $k);
		next unless $m_ik !=0;
		$index = $k; # memorize index
		$value = $m_ik;
		last;
	}
	return( $index, $value);
}

=item find_short_cut_row

	($index, $value, $feasible)=$self->find_short_cut_row
	
Find the most negative entry in the constraint column vector $b. If all entries
are positive then the tableau represents a feasible point, $feasible is set to 1
and $index and $value are undefined.

=cut

sub find_short_cut_row {
	my $self = shift;
#	my @b = map {$_->value} @{ $self->{b}->column(1)->data }; #get raw numbers
#	main::DEBUG_MESSAGE("b is ", join(" ", @b ));
	my ($row_dim, $col_dim) = $self->{b}->dimensions;
#	main::DEBUG_MESSAGE($self->{b}->dimensions);
#	main::DEBUG_MESSAGE("dimensions of b: $row_dim, $col_dim ");
	my $col_index = 1;
	my $index = undef;
	my $value = undef;
	my $feasible = 1;
	for (my $k=1; $k<=$row_dim; $k++) {
		my $b_k1 = $self->{current_b}->element($k,$col_index);
		# main::DEBUG_MESSAGE("b[$k] = $b_k1");
		next if $b_k1>=0; #skip positive entries; 
		$index =$k;
		$value = $b_k1;
		$feasible = 0;
		last;	
	}
	return ( $index, $value, $feasible);
}

=item find_short_cut_column

	($index, $value, $infeasible) = $self->find_short_cut_column(row number)

Find the left most negative entry in the specified row.  If all coefficients are 
positive then the tableau represents an infeasible LOP, the $infeasible flag is set,
and the $index and $value are undefined.

=cut

sub find_short_cut_column {
	my $self = shift;
	my $row_index = shift;
	my ($row_dim,$col_dim) = $self->{M}->dimensions;
	$col_dim = $col_dim - 1; # omit constraint column
	       # FIXME to adjust for additional obj_value columns
	#sanity check row index
	unless (1<= $row_index and $row_index <= $row_dim) {
		Value::Error("The row must be between 1 and $row_dim");
	}
	my $index = undef;
	my $value = undef;
	my $infeasible = 1;
	for (my $k = 1; $k<=$col_dim; $k++ ) {
		my $m_ik = $self->{current_constraint_matrix}->element($row_index, $k);
		# main::DEBUG_MESSAGE( "in M: ($row_index, $k) contains $m_ik");
		next if $m_ik >=0;
		$index = $k;
		$value = $m_ik;
		$infeasible = 0;
		last;
	}
	return( $index, $value, $infeasible);	
}

=item find_next_short_cut_pivot 

	($row, $col, $feasible, $infeasible) = $self->find_next_short_cut_pivot
	
	
Following the short-cut algorithm this chooses the next pivot by choosing the row
with the most negative constraint constant entry (top most first in case of tie) and 
then the left most negative entry in that row. 

The process stops with either $feasible=1 (state variables give a feasible point for the 
constraints) or $infeasible=1 (a row in the tableau shows that the LOP has empty domain.)
	
=cut

=item find_next_short_cut_basis


=cut 

# eventually these routines should be included in the Value::Matrix 
# module?
package Value::Matrix;

sub _Matrix {
	Value::Matrix->new(@_);
}

sub row_slice {
	my $self = shift;
	@slice = @_;
	return _Matrix( $self->extract_rows(@slice) );
}
sub extract_rows {
	my $self = shift;
	my @slice = @_;
	if (ref($slice[0]) =~ /ARRAY/) { # handle array reference
		@slice = @{$slice[0]};
	} elsif (@slice == 0) { # export all rows to List
		@slice = ( 1..(($self->dimensions)[0]) );	
	}
	return [map {$self->row($_)} @slice ]; #prefer to pass references when possible
}
sub column_slice {
	my $self = shift;
	return _Matrix( $self->extract_columns(@_) )->transpose;  # matrix is built as rows then transposed.
}
sub extract_columns { 
	my $self = shift;
	my @slice = @_;
	if (ref($slice[0]) =~ /ARRAY/) { # handle array reference
		@slice = @{$slice[0]};
	} elsif (@slice == 0) { # export all columns to an array
		@slice = ( 1..(($self->dimensions)[1] ) );	
	}
    return  [map { $self->transpose->row($_) } @slice] ; 
    # returns the columns as an array of 1 by n row matrices containing values
    # if you pull columns directly you get an array of 1 by n  column vectors.
    # prefer to pass references when possible
}
sub extract_rows_to_list {
	my $self = shift;
	Value::List->new($self->extract_rows(@_));
}
sub extract_columns_to_list {
	my $self = shift;
	Value::List->new($self->extract_columns(@_) );
}

sub submatrix {
	my $self = shift;
	my %options = @_;
	my($m,$n) = $self->dimensions;
	my $row_slice = ($options{rows})?$options{rows}:[1..$m];
	my $col_slice = ($options{columns})?$options{columns}:[1..$n];
	return $self->row_slice($row_slice)->column_slice($col_slice);
}



1;
