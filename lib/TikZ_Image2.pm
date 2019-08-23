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

package TikZ_Image2;
use WeBWorK::PG::IO;

=item new
	#The constructor is meant to be called with no parameters
	
=cut

sub new {
	my $class = shift;
	my $rh_envir = shift;
	my $tex=();
	my $tikz_options = shift;
	my $self = {
			code			 =>	$tex, 
			tikz_options	 =>	$tikz_options,
			working_dir      => '',
			file_name 		 => '',
			destination_path => '',
			pdflatex_command => WeBWorK::PG::IO::pdflatexCommand(),
			convert_command  => WeBWorK::PG::IO::convertCommand(),
			copy_command     => WeBWorK::PG::IO::copyCommand(),
			# rh_envir       => $rh_envir,   # pointer to the environment
			displayMode      => $rh_envir->{displayMode},
			ext              => 'png',  # or svg or png or gif
	};
	return bless $self, $class;
}

#FIXME -- passing in the actual commands to TikZ_Image2.pm
#FIXME -- is extremely dangerous.  It gives command line access
#FIXME -- to authors to insert just about any command.
#FIXME -- allow ext to be overridden
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
# sub set_commandline_mode {
# 	my $self = shift;
# 	my $commandline_mode = shift;    #FIXME this section is temporary
# 	my $working_dir = $self->{working_dir};
# 	if ($commandline_mode eq 'wwtest') {		
# 		$extern_pdflatex="/Volumes/WW_test/opt/local/bin/pdflatex --shell-escape";
# 		$self->{convert_command}  = "convert $working_dir/hardcopy.pdf "; #add destination file later
# 		$self->{copy_command}     = "cp ";
# 	} elsif ( $commandline_mode eq 'macbook') {
# 		$extern_pdflatex ="/Library/TeX/texbin/pdflatex --shell-escape";
# 		$self->{convert_command}  = "/usr/local/bin/convert $working_dir/hardcopy.pdf ";
# 		$self->{copy_command}     = "cp ";
# 	} elsif ( $commandline_mode eq 'hosted2') {
# 		$extern_pdflatex="/usr/local/bin/pdflatex --shell-escape";
# 		$self->{convert_command}  = "/usr/local/bin/convert $working_dir/hardcopy.pdf "; #add destination file later
# 		$self->{copy_command}     = "cp ";
# 	}
# 	$self->{pdflatex_command} =  "cd " . $working_dir . " && "
# 		. $extern_pdflatex. " >pdflatex.stdout 2>pdflatex.stderr hardcopy.tex";
# }
# Insert your TikZ image code, not including begin and end tags, as a single
# string parameter for this method. Works best single quoted.
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

# how should this module get the pdflatex command
# and the convert command -- it needs access to site.conf
# or else those locations need to be shared with PGcore
# Call this method in the location where you want to generate your HTML code
# OR, comment out print HTML $self->include() and use it when your image is 
# complete
sub render {
	my $self = shift;
	my $working_dir =  $self->{working_dir};
	my $file_name = $self->{file_name};
	my $file_path = "$working_dir/hardcopy";
	my $html_directory   = $self->{html_temp};
	my $fh;
	open( $fh, ">", "$file_path.tex" ) or warn "Can't open $file_path.tex for writing<br/>\n";
	chmod( 0777, "$file_path.tex");
	print $fh $self->header();
	print $fh $self->{code}."\n";	
	print $fh $self->footer();
	close $fh;	
	my $pdflatex_command = $self->{pdflatex_command};
	warn "render:  $pdflatex_command <br/>\n";
	system "$pdflatex_command ";  # produces a .pdf file
	unless (-r "$working_dir/hardcopy.pdf" ) {
		warn "file $working_dir/hardcopy.pdf was not created<br/>\n";
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

#here I'm assuming there's some file open which generates the HTML code for the
# problem and its page, so render() should be called in the problem text portion
# of a PG file.
	#print HTML $self->include();
}
sub convert {
	my $self = shift;
	my $working_dir =  $self->{working_dir};
	my $file_name = $self->{file_name};
	my $file_path = "$working_dir/$file_name";
	my $ext = $self->{ext};   # or png or gif
	my $convert_command = $self->{convert_command};
	warn "converting: ","$convert_command  $file_path.$ext","\n"; 
	system "$convert_command  $file_path.$ext";
	return -r "$file_path.$ext";
}

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
	my $file_name = $self->{file_name};
	my $file_path = "$working_dir/$file_name";
	my $destination_path = $self->{destination_path};
	my $copy_command = $self->{copy_command};
	my $ext = $self->{ext};
	if ($self->{displayMode} ne 'TeX') {
		warn "copy: $copy_command $working_dir/$file_name.$ext $destination_path.$ext\n";	
		system "$copy_command $working_dir/$file_name.$ext $destination_path.$ext";
		$self->{final_destination_path}= "$destination_path.$ext";
		return -r "$destination_path.$ext";
	} else {
		warn "copy: $copy_command $working_dir/hardcopy.pdf $destination_path.pdf\n";	
		system "$copy_command $working_dir/hardcopy.pdf $destination_path.pdf";
		$self->{final_destination_path}= "$destination_path.pdf";
		return -r "$destination_path.pdf";
	}
}

#Separating out the html so as not to get confused
sub include {
	my $html= qq|<img src=img.png alt="TikZ Image">|;
	return $html;
}
1;
