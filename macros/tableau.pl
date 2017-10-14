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

	A => undef, # constraint matrix  MathObjectMatrix
	b => undef, # constraint constants Vector or MathObjectMatrix 1 by n
	c => undef, # coefficients for objective function Vector or MathObjectMatrix 1 by n
	obj_row => undef, # contains the negative of the coefficients of the objective function.
	z => undef, # value for objective function
	n => undef, # dimension of problem variables (columns in A)
	m => undef, # dimension of slack variables (rows in A)
	S => undef, # square m by m matrix for slack variables
	basis => undef, # list describing the current basis columns corresponding to determined variables.
	B => undef,  # square invertible matrix corresponding to the current basis columns
	M => undef,  # matrix of consisting of all columns and all rows except for the objective function row 
	obj_col_num => undef, 
	# flag indicating the column (1 or n+m+1) for the objective value
	constraint_labels => undef,
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

loadMacros("tableau_main_subroutines.pl");


=head4 Subroutines added to the main:: Package


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


##################################################
package Tableau;
our @ISA = qw(Value::Matrix Value);


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
		main::WARN_MESSAGE("Error: Required inputs: Tableau(A=> Matrix, b=>Vector, c=>Vector)");
		return;
	}
	my ($m, $n)=($self->{A}->dimensions);
	$self->{n}=$self->{n}//$n;
	$self->{m}=$self->{m}//$m;
	# main::DEBUG_MESSAGE("m $m, n $n");
	$self->{S} = Value::Matrix->I($m);
	$self->{basis} = [($n+1)...($n+$m)] unless ref($self->{basis})=~/ARRAY/;
	my @rows = $self->assemble_matrix;
	# main::DEBUG_MESSAGE("rows", map {ref($_)?$_->value :$_} map {@$_} @rows);
	$self->{M} = _Matrix([@rows]);
	$self->{B} = $self->{M}->submatrix(rows=>[1..($self->{m})],columns=>$self->{basis});
	$self->{obj_row} = _Matrix(@{$self->objective_row()});
	return();	
}
		
sub assemble_matrix {
	my $self = shift;
	my @rows =();
	my $m = $self->{m};
	my $n = $self->{n};
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
	my @last_row=();
	push @last_row, ( -($self->{c}) )->value;  # add the negative coefficients of the obj function
	foreach my $i (1..($self->{m})) { push @last_row, 0 }; # add 0s for the slack variables
	push @last_row, 1, 0; # add the 1 for the objective value and 0 for the initial valu
	return \@last_row;
}

# return a matrix containing the entire tableau
sub current_tableau {
	my $self = shift;
	my $Badj = ($self->{B}->det->value) * ($self->{B}->inverse);
	my $current_tableau = $Badj * $self->{M};  # the A | S | obj | b
	$self->{current_tableau}=$current_tableau;
	# find the coefficients associated with the basis columns
	my $c_B  = $self->{obj_row}->extract_columns($self->{basis} );
	my $c_B2 = Value::Vector->new([ map {$_->value} @$c_B]);
	my $correction_coeff = ($c_B2*$current_tableau )->row(1);
	# subtract the correction coefficients from the obj_row
	# this essentially extends Gauss reduction applied to the obj_row
	my $obj_row_normalized = ($self->{B}->det->value) *$self->{obj_row};
	#main::DEBUG_MESSAGE(" normalized obj row ",$obj_row_normalized->value);
	#main::DEBUG_MESSAGE(" correction coeff ", $correction_coeff->value);
	my $current_coeff = $obj_row_normalized-$correction_coeff ;
	$self->{current_coeff}= $current_coeff; 

	#main::DEBUG_MESSAGE("subtract these two ", (($self->{B}->det) *$self->{obj_row}), " | ", ($c_B*$current_tableau)->dimensions);
	#main::DEBUG_MESSAGE("all coefficients", join('|', $self->{obj_row}->value ) );
	#main::DEBUG_MESSAGE("current coefficients", join('|', @current_coeff) );
    #main::DEBUG_MESSAGE("type of $self->{basis}", ref($self->{basis}) );
	#main::DEBUG_MESSAGE("current basis",join("|", @{$self->{basis}}));
	#main::DEBUG_MESSAGE("CURRENT STATE ", $current_tableau);
	return _Matrix( @{$current_tableau->extract_rows},$self->{current_coeff} );
	#return( $self->{current_coeff} );
}

sub basis {
	my $self = shift;  #update basis
	                   # basis is stored as an ARRAY reference. 
	                   # basis is exported as a list
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
	$self->{basis}= $new_basis;
	$self->{B} = $self->{M}->submatrix(rows=>[1..($self->{m})],columns=>$self->{basis});
	return Value::List->new($self->{basis});	
} 




package Value::Matrix;

sub _Matrix {
	Value::Matrix->new(@_);
}

sub row_slice {
	$self = shift;
	@slice = @_;
	return _Matrix( $self->extract_rows(@slice) );
}
sub extract_rows {
	$self = shift;
	my @slice = @_;
	if (ref($slice[0]) =~ /ARRAY/) { # handle array reference
		@slice = @{$slice[0]};
	} elsif (@slice == 0) { # export all rows to List
		@slice = ( 1..(($self->dimensions)[0]) );	
	}
	return [map {$self->row($_)} @slice ]; #prefer to pass references when possible
}
sub column_slice {
	$self = shift;
	return _Matrix( $self->extract_columns(@_) )->transpose;  # matrix is built as rows then transposed.
}
sub extract_columns { 
	$self = shift;
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
