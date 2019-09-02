##### from sendXMLRPC -- and simplified version of what is in Hardcopy.pm
############################################################################
#### this 
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
