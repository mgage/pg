#!/usr/bin/perl -w

use v5.12.3;
use strict;

use lib "/Volumes/WW_test/opt/webwork/pg_2014/lib";
use lib "/Volumes/WW_test/opt/webwork/pg_2014/macros";
use lib "/Volumes/WW_test/opt/webwork/webwork2/lib";

use Test::More qw(no_plan);
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
#require "Matrix.pl";

our %context;

sub Context {
	Parser::Context->current(\%context,@_)
}

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
 
 my $m = [[Real(3),4,6],[2,1,5],[4,2,1],[1,4,-5]];
 my $matrix = Matrix($m);
 say "matrix ",$matrix;
 say "matrix-data ",$matrix->data;
 say "matrix-data expanded ", map {$_} @{$matrix->data};
 say "matrix-data refs ", map {ref($_)} @{$matrix->data};
say "matrix-data data ", join " ", map {'|'.join(' ',$_->value).'|'} @{$matrix->data};
 say "matrix-data value ", join " ", map {'|'.join(' ',$_->value).'|'} @{$matrix->data};
 say "matrix-value ", join ", ", map {'['.(join ' ', @$_).']'} $matrix->value;
done_testing();
