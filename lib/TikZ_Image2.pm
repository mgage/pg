#!/bin/perl
###############################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader: pg/lib/PGcore.pm,v 1.6 2010/05/25 22:47:52 gage Exp $
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME
	TikZ

=head1 SYNPOSIS


=head1 DESCRIPTION

#This is a Perl Module which simplifies and automates the process of generating
# images using TikZ, and converting them into a Web-Useable format
# MV; March 2014

=cut 

=head1 USAGE

	sub tikz_graph{
		my $drawing = TikZ_Image2->new(~~%envir);
		# initialize
			$drawing->{working_dir}=$working_dir;
			$drawing->{file_name}=$file_name;
			$drawing->{destination_path}= $destination_path;
			$drawing->ext('png');
			#$drawing->set_commandline_mode("wwtest"); # "wwtest" or "macbook" or "hosted2"
		# end initialize
		# debugging /development
		$copy_command=$drawing->{copy_command};
		$pdflatex_command =$drawing->{pdflatex_command};
		$convert_command = $drawing->{convert_command};
		$display_mode = $drawing->{displayMode};
		# end debugging
		$drawing->addTex(join(" ",@_));
		$drawing->render();
		return $drawing->{final_destination_path};
	}
 
	$path = tikz_graph(<<END_TIKZ);
	\begin{tikzpicture}[main_node/.style={circle,fill=blue!20,draw,minimum size=1em,inner sep=3pt]}] 
	\draw (-4,0) -- (4,0);
	\draw (0,-2) -- (0,2);
	\draw (0,0) circle (1.5);
	\draw (0, 1.5) node[anchor=south]{N} -- (2.5,0)node [above]{y};
	\draw (1.2,0.9) node[right]{\((\vec x, x_{n})\)};
	\end{tikzpicture}
	END_TIKZ

=cut

=head2 Methods:
 
=cut

use strict; 
use warnings;
use Carp;
use PGcore;

package TikZ_Image2;
use parent qw(PGcore);
use WeBWorK::PG::IO(); # don't import subroutines directly
use String::ShellQuote;
use File::Spec;
use File::Path;
use File::Temp qw/tempdir/;


our $UNIT_TESTS_ON =0;
=item new
	#The constructor is meant to be called with no parameters
	
=cut

sub new {
	my $class = shift;
	my $rh_envir = shift;
	my $tex='';
	my $tikz_options = shift;
	my $self = {
			code			 =>	$tex, 
			tikz_options	 =>	$tikz_options,
			working_dir      => '',   # directory where processing takes place
			file_name 		 => '',
			destination_path => '',   # destination file, minus the extension 
			pdflatex_command => WeBWorK::PG::IO::pdflatexCommand(),
			convert_command  => WeBWorK::PG::IO::convertCommand(),
			copy_command     => WeBWorK::PG::IO::copyCommand(),
			rh_envir         => $rh_envir,   # pointer to the environment
			displayMode      => $rh_envir->{displayMode},
			ext              => 'png',  # or svg or png or gif
	};
	return bless $self, $class;
}

#FIXME -- passing in the actual commands to TikZ_Image2.pm
#FIXME -- is extremely dangerous.  It gives command line access
#FIXME -- to authors to insert just about any command.
#typical values for command line apps


# how should this module get the pdflatex command
# and the convert command -- it needs access to site.conf
# or else those locations need to be shared with PGcore
# Call this method in the location where you want to generate your HTML code
# OR, comment out print HTML $self->include() and use it when your image is 
# complete

#tempDirectory	=>	 /Volumes/WW_test/opt/webwork/webwork2/htdocs/tmp/daemon_course/
# tempURL	=>	 /webwork2_files/tmp/daemon_course/
# templateDirectory	=>	 /Volumes/WW_test/opt/webwork/courses/daemon_course/templates/


# these should all be in $envir->{externalPdflatexPath} etc.
# externalLaTeXPath	=>	 /Volumes/WW_test/opt/local/texlive/2010/bin/x86_64-darwin/latex
# externalDvipngPath	=>	 /Volumes/WW_test/opt/local/texlive/2010/bin/x86_64-darwin/dvipng
# externalcp	=>	 /bin/cp
# externalPdflatexPath	=>	 /Volumes/WW_test/opt/local/texlive/2010/bin/x86_64-darwin/pdflatex --shell-escape
# externalConvert	=>	 

my $extern_pdflatex='';

sub addTex {
	my $self= shift;
	$self->{code} .= shift;
}

sub ext {
	my $self = shift;
	if (@_) {
		return $self->{ext} = shift;
	} else {
		return $self->{ext};
	}

}
sub header {
	my $self = shift;
	my @output=();
	push @output, "\\documentclass{standalone}\n";
	push @output, "\\usepackage{tikz}\n";
	push @output, "\\usepackage{comment}\n"; # often used in tikz graphs
	push @output, "\\begin{document}\n";
#	push @output, "\\begin{tikzpicture}[".$self->{tikz_options}."]\n";
	@output;
}

sub footer {
	my $self = shift;
	my @output=();
#	push @output, "\\end{tikzpicture}\n";
	push @output, "\\end{document}\n";
	@output;
}


sub render {
	my $self = shift;
	my $working_dir =  $self->{working_dir};
	my $working_file_path = "$working_dir/tikz_hardcopy";
	my $html_directory   = $self->{html_temp};
	my $fh;
	open( $fh, ">", "$working_file_path.tex" ) or warn "Can't open $working_file_path.tex for writing<br/>\n";
	chmod( 0777, "$working_file_path.tex");
	print $fh $self->header();
	print $fh $self->{code}."\n";	
	print $fh $self->footer();
	close $fh;	
	my $pdflatex_command = $self->{pdflatex_command};
	my $render_tex_cmd = "cd " . shell_quote($working_dir) . " && "
		. $pdflatex_command
		. " $working_file_path.tex >pdflatex.stdout 2>pdflatex.stderr hardcopy";
	print STDERR "render command:  $render_tex_cmd  \n";
	eval {
		my $result = system "$render_tex_cmd";  # produces a .pdf file
		print STDERR "result from render_tex_cmd  is $result  (256 is bad) command is $render_tex_cmd ";
	};
	if ($@) {
		print STDERR "error in rendering tikz file with command $render_tex_cmd \n\n $@"
	}
	unless (-r "$working_dir/tikz_hardcopy.pdf" ) {
		warn "file $working_dir/tikz_hardcopy.pdf was not created<br/>\n";
	} else {
		warn "file $working_dir/hardcopy.pdf created<br/>\n";
		unless ($self->convert) {
			warn "convert operation failed<br/>\n";
		} else {
			warn "convert operation success<br/>\n";	
			unless ($self->copy) {
				warn "copy operation failed<br/>\n";
			} else {
				warn "copy operation succeeded<br/>\n";
			}
		}
	}
	#$self->clean_up;

# here I'm assuming there's some file open which generates the HTML code for the
# problem and its page, so render() should be called in the problem text portion
# of a PG file.
	#print HTML $self->include();
}
sub convert {
	my $self = shift;
	my $working_dir =  $self->{working_dir};
	my $working_file_path = "$working_dir/tikz_hardcopy";
	my $ext = $self->{ext};   # or png or gif or svg?
	my $convert_command = $self->{convert_command};
	if ($ext eq 'png' or $ext eq 'gif'){
		warn "converting: ","$convert_command $working_file_path.pdf $working_file_path.$ext","\n"; 
		system "$convert_command $working_file_path.pdf $working_file_path.$ext";
	}
	elsif($ext eq 'svg'){
		system "/usr/local/bin/pdf2svg $working_file_path.pdf $working_file_path.$ext";
	}
	return -r "$working_file_path.$ext";
}

############# notes
# pdf2svg does a much better job of creating vector svg.  convert produces svg, but a rastor
# image of the pdf file.  I was unable to get inkscape to convert properly from the command line.
# All many to system should perhaps be replaced by perl calls or moved to IO.pm to 
# limit the number of direct accesses to the disk from PG
#############


sub clean_up {
	my $self = shift;
	my $working_dir =  $self->{working_dir};
	my $file_name = $self->{file_name};
	my $file_path = "$working_dir/$file_name";
	if (-e "$file_path.tex") {
		# warn "clean up rm -f $working_dir/*";
		system "rm -f $working_dir/*";
	}
}
sub copy {
	my $self = shift;
	my $working_dir =  $self->{working_dir};
	#  my $file_name = $self->{file_name};
	my $ext = $self->{ext};
	my $source_file_path = "$working_dir/tikz_hardcopy/hardcopy.$ext";
	my $destination_path = $self->{destination_path};
	my $copy_command = $self->{copy_command};
	if ($self->{displayMode} ne 'TeX') {
		warn "copy: $copy_command $working_dir/tikz_hardcopy.$ext $destination_path.$ext\n";	
		system "$copy_command $working_dir/tikz_hardcopy.$ext $destination_path.$ext";
		#system "$copy_command $working_dir/hardcopy.pdf  $destination_path.pdf";
		#system "$copy_command $working_dir/hardcopy.svg $destination_path.svg";
		#system "$copy_command $working_dir/hardcopy.gif $destination_path.gif";
		$self->{final_destination_path}= "$destination_path.$ext";
		return -r "$destination_path.$ext";
	} else {
		warn "copy: $copy_command $working_dir/tikz_hardcopy.pdf $destination_path.pdf\n";	
		system "$copy_command $working_dir/tikz_hardcopy.pdf $destination_path.pdf";
		$self->{final_destination_path}= "$destination_path.pdf";
		return -r "$destination_path.pdf";
	}
}



##### originally from Hardcopy.pm  #####
### creating the temporary Directory is proving difficult###
### File::Path won't work inside the Safe compartment (it uses 'use' for error error messages)
### File::Temp did not seem to be working either -- but it should be considered
### possibly mkpath or mkdir -p could be used 
###
###


###### tempDirectory storage for tempDirectory since this inherits from PGcore
###### 
sub tempDirectory {
	my $self = shift;
	$self->{working_dir};
}


# This subroutine is being tested in pg/t/tikz_test4.pg
sub create_working_directory {
	my $self=shift();

# we want to make the temp directory web-accessible, for error reporting
	# use mkpath to ensure it exists (mkpath is pretty much ``mkdir -p'')"
	
	#my $temp_dir_parent_path = "tikz_hardcopy";
	#warn "tempdirectory $temp_dir_parent_path";

	# eval { $dir = File::Temp->newdir() };
	# eval { File::Path::mkpath($temp_dir_parent_path )};
	eval { $self->surePathToTmpFile("tikz_hardcopy/hardcopy.tex") };
	if ($@) {
		warn "Couldn't create hardcopy directory tikz_hardcopy: $@";
	}
	my $temp_dir_parent_path = ($self->tempDirectory)."tikz_hardcopy";
	warn "temp_dir_parent_path = $temp_dir_parent_path";
	warn "ready to create new work directory";
	
	my $temp_dir_path = File::Temp->newdir('work.XXXXX',
	      DIR=> $temp_dir_parent_path,
	      CLEANUP => 0);
	warn "working directory temp_dir_path $temp_dir_path";
	
	# make sure the directory can be read by other daemons e.g. lighttpd
	chmod 0755, $temp_dir_path;
	
	# do some error checking
	unless (-e $temp_dir_path) {
		$self->add_errors("Temporary directory '".$self->encode_pg_and_html($temp_dir_path)
			."' does not exist, but creation didn't fail. This shouldn't happen.");
		return;
	}
 	unless (-w $temp_dir_path) {
 		$self->add_errors("Temporary directory '".$self->encode_pg_and_html($temp_dir_path)
 			."' is not writeable.");
 		$self->delete_temp_dir($temp_dir_path);
 		return;
 	}
 	$self->{working_dir} = $temp_dir_path;
 	my $tex_file_name = "hardcopy.tex";
 	$self->{tex_file_name} = $tex_file_name;
# 	$self->{tex_file_path} = "$temp_dir_path/$tex_file_name";
# 	my $out = {
# 		temp_dir_path => $temp_dir_path,
# 		tex_file_name => $tex_file_name,
# 		tex_file_path => $temp_dir_path/$tex_file_name
# 	};
	
	return 1;
}

sub add_errors {
	my ($self, @errors) = @_;
	push @{$self->{hardcopy_errors}}, @errors;
}

sub get_errors {
	my ($self) = @_;
	return $self->{hardcopy_errors} ? @{$self->{hardcopy_errors}} : ();
}

sub get_errors_ref {
	my ($self) = @_;
	return $self->{hardcopy_errors};
}




1;
