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
use String::ShellQuote;

our $UNIT_TESTS_ON =0;
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
			working_dir      => '',   # directory where processing takes place
			file_name 		 => '',
			destination_path => '',   # destination file, minus the extension 
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
#	push @output, "\\usepackage{comment}\n"; # often used in tikz graphs
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

#here I'm assuming there's some file open which generates the HTML code for the
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

#Separating out the html so as not to get confused
# sub include {
# 	my $html= qq|<img src=img.png alt="TikZ Image">|;
# 	return $html;
# }

##### from sendXMLRPC -- and simplified version of what is in Hardcopy.pm
############################################################################

sub create_pdf_output {
	my $tex_file_name = shift;
	my @errors=();   
	print "pdf mode\n" if $UNIT_TESTS_ON;
	my $pdf_file_name = $tex_file_name;
	$pdf_file_name =~ s/\.\w+$/\.pdf/;    # replace extension with pdf
	
	##########################################
	# create working directory
	# input() -- should be able to rely on defaults
	# output()  $working_dir_path
	##########################################
	
	# create a randomly-named working directory in the TEMPOUTPUTDIR() directory
	my $working_dir_path = eval { tempdir("work.XXXXXXXX", DIR => TEMPOUTPUTDIR()) };
	if ($@) {
		push @errors, "Couldn't create temporary working directory: $@";
	}
	# make sure the directory can be read by other daemons e.g. lighttpd
	chmod 0755, $working_dir_path;

	# do some error checking
	unless (-e $working_dir_path) {
		push @errors, "Temporary directory ".$working_dir_path
			." does not exist, but creation didn't fail. This shouldn't happen.";
	}
	unless (-w $working_dir_path) {
		push @errors, "Temporary directory ".$working_dir_path
			." is not writeable.";

	}
	
	# catch errors if directory is not made (should be global, outside subroutine)
	if (@errors) {
		print "There were errors in creating the working directory for processing tex to pdf. \n".
	      join("\n", @errors);
	    delete_temp_dir($working_dir_path);
	    return 0; # FAIL if no working directory
	}
	
	
	########################################
	# try to mv the tex file into the working directory
	########################################

	my $src_path = TEMPOUTPUTDIR().$tex_file_name;
	my $dest_path = "$working_dir_path/$tex_file_name";
	my $mv_cmd = "2>&1 mv ". shell_quote("$src_path", "$dest_path");
	my $mv_out = readpipe $mv_cmd;
	if ($?) {
		push @errors, "Failed to rename $src_path  to "
			."$dest_path in directory \n"
			."$mv_out";
		print join("\n",@errors);
	}

	##########################################
	# process tex file to pdf  (if working directory was created)
	##########################################
	@errors =();  # reset errors
	
	my $tex_file_path = $dest_path;
	my $pdf_path = "$working_dir_path/$pdf_file_name";
	print "pdflatex $tex_file_path\n" if $UNIT_TESTS_ON;
	
	# call pdflatex - we don't want to chdir in the mod_perl process, as
	# that might step on the feet of other things (esp. in Apache 2.0)
	my $pdflatex_cmd = "cd " . shell_quote($working_dir_path) . " && "
		. "pdflatex"
		. " $tex_file_name >pdflatex.stdout 2>pdflatex.stderr hardcopy";
	if (my $rawexit = system $pdflatex_cmd) {
		my $exit = $rawexit >> 8;
		my $signal = $rawexit & 127;
		my $core = $rawexit & 128;
		push @errors, "Failed to convert TeX to PDF with command $pdflatex_cmd))"
			." (exit=$exit signal=$signal core=$core).";
		
		# read hardcopy.log and report first error
		my $hardcopy_log = "$working_dir_path/$tex_file_name";
		$hardcopy_log =~ s/\.tex$/\.log/;   # replace extension
		if (-e $hardcopy_log) {
			if (open my $LOG, "<", $hardcopy_log) {
				my $line;
				while ($line = <$LOG>) {
					last if $line =~ /^!\s+/;
				}
				my $first_error = $line;
				while ($line = <$LOG>) {
					last if $line =~ /^!\s+/;
					$first_error .= $line;
				}
				close $LOG;
				if (defined $first_error) {
					push @errors, "First error in TeX log is: $first_error";
				} else {
					push @errors, "No errors encoundered in TeX log.";
				}
			} else {
				push @errors, "Could not read TeX log: $!";
			}
		} else {
			push @errors, "No TeX log was found.";
		}
	}
	
	########################################
	# try to rename the pdf file
	########################################

	my $src_path1 = $pdf_path;
	my $final_pdf_path = TEMPOUTPUTDIR().$pdf_file_name;
	my $mv_cmd1 = "2>&1 mv ". shell_quote("$src_path1", "$final_pdf_path");
	my $mv_out1 = readpipe $mv_cmd1;
	if ($?) {
		push @errors, "Failed to rename $src_path  to "
			."$final_pdf_path in directory \n"
			."$mv_out1";
	}
	

	##################################################	
	# remove the temp directory if there are no errors
	##################################################
	if (@errors) {
		print "Errors in converting the tex file to pdf: ".join("\n", @errors);
		return 0;
	}
	
	unless (@errors or $UNIT_TESTS_ON) {
		delete_temp_dir($working_dir_path);
	} 
	
 
	
	
	# return path to pdf file
	print "pdflatex to $final_pdf_path DONE\n" if $UNIT_TESTS_ON;
	# this is doable but will require changing directories
	# look at the solution done using hardcopy
	return $final_pdf_path;}

# helper function to remove temp dirs
sub delete_temp_dir {
	my ($temp_dir_path) = @_;
	
	my $rm_cmd = "2>&1 rm -rf " . shell_quote($temp_dir_path);  #can use perl command for this??
	my $rm_out = readpipe $rm_cmd;
	if ($?) {
		print "Failed to remove temporary directory '".$temp_dir_path."':\n$rm_out\n";
		return 0;
	} else {
		return 1;
	}
}


1;
