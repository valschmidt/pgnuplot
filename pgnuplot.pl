#!/usr/bin/perl
#
# pgnuplot   $Id:
#
# Val Schmidt
# LDEO/Columbia
# 
# A perl wrapper to gnuplot
#
# To Do:
# Set up a few standard ways to plot data - i.e. gps data, time stamps, etc.
#
# Implement Getopt::Long and set various levels of verbosity.
#
# Write a routine to store data on the fly allowing calculations between
# lines of data rather than only within the line. For example, one could
# want to plot differences in successive values in the data, or a boxcar 
# type running average. 


use Getopt::Std;
use File::Basename;

my $RCSID = '$Id: ';

if(!@ARGV){
    print STDOUT<<__END__;

Usage:

pgnuplot.pl is a front end script to add functionality to gnuplot.
------------------------------------------------------------------

Here is an example to illustrate:

pgnuplot.pl -fCc#[2]_c#[4]:D,:Pdots:datafile.dat::Cc#[5]*c#[6]_c#[7]/100:Ppoints:datafile_2.dat -t"Plot Title" -p"Xaxis Label" -q"Y axis Label"

Lets look at the -f argument first:

Data Sets:

Here there are two data sets to be plotted.  The first from datafile.dat, 
the second from datafile_2.dat.  A separate set of arguments are specified
for each data file and the two sets are separated by a "::".  We can add as 
many files as we like and think we have memory for by stringing them together
with "::" symbols to delimit each set of arguments.

File Arguments: 

For each data file we need to specify two columns to plot.  We do this
with the "C" flag, for example, Cc#[N]_c#[N]l, where N is the column
number starting with zero and counting from left to right.  The "C"
flag is extremely flexible as each of the c#[N} expressions above can
be any valid perl string with c#[N] to specify appropriate references
to a column. In the second file argument list in our example, we plot
the product of columns 5 and 6 against column 7 divided by 100. If we
do not specify any columns, the first two columns in our file will be
taken by default. Alternatively, we can specify just a single column
to plot by specifying "Cc#[N]_#".

Another useful example is plotting GPS data from a NMEA string, where
latitude and longitude are in columns 2 and 4 respectively, and
degrees and minutes are concatinated together - i.e. DDMM.MMMM for LAT
and DDDMM.MMMM for long.  One could do this by simply converting to
decimal degrees on the fly with something like this:

-f'Csubstr(c#[4],0,3)+substr(c#[4],3,length(c#[4]))/60_substr(c#[2],0,2)+substr(c#[2],2,length(c#[2]))/60'

Note in the above example the string is surrouned by single
is sometimes required to keep from confusing you shell.

The second optional file argument is a delimiter.  We so this with the
"D" flag, for example "D," for a comma delimited file or "D\t" for a
tab delimited file. When the "D" flag is not specified, white space is
the default.

We may also speicfy the point type to plot with the "P" flag.  Here
the options are the same as are available in gnuplot - points, dots,
lines, linespoints, etc.

Each of the file arguments are strung together with :s as shown above
and as we said before, the sets of arguments for each file are strung
together with ::.

Other Arguments:

-t'Title' -  Sets the plot title
-p'Xlabel' - Sets the x axis label
-q'Ylabel' - Sets the y axis label
-ofilename - Sets the output filename instead of the default pgnu_plot.ps
-s         - Do NOT show in gv automatically (good for scripts)
-w         - Convert plots to png format for www display
-x -y      - Set the x and y ranges. [Bug - must specify both to work] 

__END__

exit 0;
}

&getopts('F:f:MmO:o:P:p:Q:q:SsT:t:VvWwX:x:Y:y:Zz');

$filedata=        ($opt_F || $opt_f); # Columns fields and files
$multiplot=       ($opt_M || $opt_m); # Allow multiple plots per page
$output=          ($opt_O || $opt_o); # Specify output file name
$verbose=         ($opt_V || $opt_v); # Verbose
$title=           ($opt_T || $opt_t); # Add a title to the plot
$xlabel =         ($opt_P || $opt_p); # Add xaxis label to the plot
$ylabel =         ($opt_Q || $opt_q); # Add yaxis label to the plot
$show =           ($opt_S || $opt_s); # Do not show in gv (default show)
$png=             ($opt_W || $opt_w); # Convert to png if you can
$xrange=          ($opt_X || $opt_x); # Set the x range
$yrange=          ($opt_Y || $opt_y); # Set the y range
$tmpfilesave=     ($opt_Z || $opt_z); # Save the temp files (for debugging)

if($verbose){
    print "Options:\n";
    print "\tFile data:\n\t$filedata\n";
    print "\tMultiplot:\t\t$multiplot\n";
    print "\tOutput File:\t\t$output\n";
    print "\tVerbose:\t\t$verbose\n";
    print "\tPlot Title:\t\t$title\n";
    print "\tPlot XLabel:\t\t$xlabel\n";
    print "\tPlot YLable:\t\t$ylabel\n";
    print "\tOutput File PNG?:\t\t$png\n";
    print "\tDo not show in gv?:\t\t$show\n";
    print "\tX Range:\t\t$xrange\n";
    print "\tY Range:\t\t$yrange\n";
    print "\tSave Temporary Files:\t\t$tmpfilesave\n\n";
}

$unixtime = time;

#$xaxisformat=     
#$yaxisformat=     

## If a png is requested, and we can find the convert command from 
## Imagemagick, then we will create the normal postscript and conver it.
## But if we cannot find convert, use gnuplots native ability to
## make a png.  [A converted ps plot looks nicer.]
if($png){
    $which=`which convert`;
    if(!($which =~ /convert$/)){
	print "\nI can't find 'convert' from ImageMagic to convert\n";
	print "the plot to Portable Network Graphics (png) format\n";
	print "from postscript.  You should check your path if you think\n";
	print "it's installed.  If not you should install it.  In the mean\n";
	print "time I'll create a less nice looking PNG using gnuplot.\n\n";
	$png=GNUPLOT;
    }
    $png=CONVERT;
}
if ($verbose){
    print "PNG=$png\n";
}
## If an output file wasn't specified, check to see if we're having
## gnuplot create a PNG directly.  If not, set the output file with
## a postscript filename.  If we are creating a PNG directly, set
## the filename to have a png filename.
if(!$output && $png ne GNUPLOT){
    $output='/tmp/pgnu_plot.ps';
    if($verbose){
	print "Output not specified setting default: pngu_plot.ps\n";
    }
}elsif(!$output){
    $output='/tmp/pgnu_plot.png';
}

# We need the version of gnuplot, because version 3.8 and greater has
# different syntax. Unfortunately, there's not an easy way to get the
# version on prior versions as they don't tell it to you. So we'll use
# the omission of any response to tell us it's a the old version.

$gnuplot_V = `gnuplot -V`;
($g_version) = $gnuplot_V =~ /^gnuplot\s+(\S+)\s+/;

if ($g_version eq "3.8j" || $g_version >= 3.8){
    $gver=new;
}else{
    $gver=old;
}

if ($verbose) {
    print "gnuplot VERSION: $g_version\n";
    print "This is the $gver syntax\n";
}

# Split up the data file arguments.
@data_file_list = split(/::/, $filedata);


foreach $xyfile_raw (@data_file_list) {

# Set defaults
    $delimiter_f="\s+";
    $xmath_f=$line[1];
    $ymath_f=$line[2];
    $pointtype_f="points";

    @filearg = split(/:/, $xyfile_raw);

    for ($i = 0; $i < $#filearg; $i++) {
	if ($filearg[$i]=~ /D/)
	{
	    ($delimiter_f) = $filearg[$i] =~ /D(\S+)/;
	}
	if ($filearg[$i]=~ /C/)
	{
	    ($xmath_f,$ymath_f) = $filearg[$i] =~ /C(\S+)_(\S+)/;
	    $xmath_f =~ s/c\#/\$line/g;
	    $ymath_f =~ s/c\#/\$line/g;
	    $xmath_f =~ s/\#/\$linecnt/g;
	    $ymath_f =~ s/\#/\$linecnt/g;
	}
	if ($filearg[$i]=~ /P/)
	{
	    ($pointtype_f) = $filearg[$i] =~ /P(\S+)/;
	}

    }
    push(@xyfiles, $filearg[$#filearg]);
    push(@delimiters, $delimiter_f);
    push(@xmath, $xmath_f);
    push(@ymath, $ymath_f);
    push(@pointtypes, $pointtype_f);

    if($verbose){
	print "Parsed File Arguments:\n";
	print "\tFile:\t $filearg[$#fliearg]\n";
	print "\tDelimiter:\t $delimiter_f\n";
	print "\tX Exp:\t $xmath_f\n";
	print "\tY Exp:\t $ymath_f\n";
	print "\tPoint Type:\t $pointtype_f\n\n";
    }

}

$i=0;
foreach $xyfile(@xyfiles){

    $INFILE="<$xyfile";
    $outfile=basename($xyfile);
    $OUTFILE=">/tmp/$outfile$i.tmp";
    open INFILE or die "Cannot open input file: $xyfile: $'";
    open OUTFILE or die "cannot open temporary file: $xyfile$i.tmp: $'";

    $linecnt=1;
    while (<INFILE>) {
	chomp;
	@line=split /$delimiters[$i]/, $_;

	if($verbose){
	    print "LINE:@line\n";
	    print "X Exp:\t $xmath[$i]\n";
	    print "Y Exp:\t $ymath[$i]\n";
	}
#     print "@line\n";
#    print "$line[2]\t$line[4]\n";

        $xval=eval "$xmath[$i]";
        if($@) {
            die "\nAn error occurred evaluating\n$xmath[$i].\nThis is likely a syntax error, but if this error occurred in the middle\nof processing it may be a divide by zero error, or your columns may not be well formed. \nAborting...\n";
        }
        $yval=eval "$ymath[$i]";
        if($@) {
            die "\nAn error occurred evaluating:\n$ymath[$i].\nThis is likely a syntax error, but if this error occurred in the middle\nof processing it may be a divide by zero error, or your columns may not be well formed. \nAborting...\n";
	}    

	$linecnt+=1;
	if ($verbose) {
	    print "$xval\t$yval\n";   
}
	printf(OUTFILE "$xval\t$yval\n");
	
    }

	$i+=1;	
	close INFILE;
	close OUTFILE;

	# Reset the file names to the new temporarily files. 
	$OUTFILE =~ s/^>//;
	$xyfile="$OUTFILE";	
}

$PLOT=">/tmp/plotter.p";
open PLOT or die "Cannot open plotter file: $'";

## Setup for 1 plot.
if(!$multiplot){
    
    printf(PLOT "# Gnuplot Script created by pgnuplot.pl\n\n");
    printf(PLOT "set nokey\n");

	printf(PLOT "# Set terminal settings\n");
    if($png eq "GNUPLOT"){
	printf(PLOT "set terminal png color\n");
    }else{
	printf(PLOT "set terminal postscript landscape color \"Helvetica-Bold\" 14\n");

	## The following lines create new line and point styles for
	## postscript plotting. These show up better than the
	## default. But becausee gnuplot syntax has changed we have to
	## get the version right.


	if ($gver eq "old" ){
	print PLOT<<__END__;

# Set "linestyles" - line and point styles
set linestyle 1 lt 1 lw 3 pt 7
set linestyle 2 lt 2 lw 3 pt 5
set linestyle 3 lt 3 lw 3 pt 9
set linestyle 4 lt 4 lw 3 pt 1
set linestyle 5 lt 5 lw 3 pt 2
set linestyle 6 lt 7 lw 3 pt 3
set linestyle 7 lt 3 lw 3 pt 13
set linestyle 8 lt 8 lw 3 pt 11
set linestyle 9 lt 9 lw 3 pt 8
set linestyle 10 lt 1 lw 3 pt 6

__END__


}elsif($gver eq "new"){
	
        print PLOT<<__END__;

# Set "linestyles" - line and point styles
set style line 1 lt 1 lw 3 pt 7
set style line 2 lt 2 lw 3 pt 5
set style line 3 lt 3 lw 3 pt 9
set style line 4 lt 4 lw 3 pt 1
set style line 5 lt 5 lw 3 pt 2
set style line 6 lt 7 lw 3 pt 3
set style line 7 lt 3 lw 3 pt 13
set style line 8 lt 8 lw 3 pt 11
set style line 9 lt 9 lw 3 pt 8
set style line 10 lt 1 lw 3 pt 6

__END__

}
    }
    if ($output){
	printf(PLOT "set output \"$output\"\n\n");
    }

    if($title){
	printf(PLOT "set title \"$title\"\n");
    }
    if($xlabel){
	printf(PLOT "set xlabel \"$xlabel\"\n");
    }
    if($ylabel){
	printf(PLOT "set ylabel \"$ylabel\"\n");
    }

    ## Loop through data files and add to plot command
    $i=0;
    foreach $xyfile (@xyfiles){
	if (!$plotfiles){
	    $plotfiles="\"$xyfile\" using 1:2 with $pointtypes[0]";
	}else{
	    $plotfiles="$plotfiles, \"$xyfile\" using 1:2 with $pointtypes[$i]";
	}
	$i+=1;
    }

    printf(PLOT "\n#Plot Command\n");
    printf(PLOT "plot $xrange $yrange $plotfiles\n");

} # End if not multiplot.

## Setup for multiplot.
if($multiplot){

    ## Initialize gnuplot script.
    printf(PLOT "# Gnuplot Script created by pgnuplot.pl\n\n");
    printf(PLOT "set nokey\n");
    printf(PLOT "# Set terminal settings\n");

    if($png eq "GNUPLOT"){
	printf(PLOT "set terminal png color\n");
    }else{
	printf(PLOT "set terminal postscript landscape color \"Helvetica-Bold\" 14\n");
	## The following lines create new line and point styles for 
	## post script plotting. These show up better than the default.
	print PLOT<<__END__;

# Set "linestyles" - line and point styles
set linestyle 1 lt 1 lw 3 pt 7
set linestyle 2 lt 2 lw 3 pt 5
set linestyle 3 lt 3 lw 3 pt 9
set linestyle 4 lt 4 lw 3 pt 1
set linestyle 5 lt 5 lw 3 pt 2
set linestyle 6 lt 7 lw 3 pt 3
set linestyle 7 lt 3 lw 3 pt 13
set linestyle 8 lt 8 lw 3 pt 11
set linestyle 9 lt 9 lw 3 pt 8
set linestyle 10 lt 1 lw 3 pt 6

__END__

	   }

    if ($output){
	printf(PLOT "# Set terminal settings\n");
	printf(PLOT "set output \"$output\"\n\n");
    }

    printf(PLOT "set origin 0,0\n");
    printf(PLOT "set size 1,1\n");
    printf(PLOT "set multiplot\n\n");

    $plots=$#xyfiles+1;

    ## Set Bounds and Sizes
    $plotsize = 1/$plots;

    $i=0;
    for $xyfile (@xyfiles){
	printf(PLOT "# Plots:\n\n");
	$plotorigin = $plotsize * ($i);
	printf(PLOT "set origin 0,$plotorigin\n");
	printf(PLOT "set size 1, $plotsize\n");
	printf(PLOT "plot $xrange $yrange \"$xyfile\" using 1:2 with $pointtypes[$i]\n\n");

	$i+=1;
    }

}

# Close the plot script and chmod to something others can overwrite.
close PLOT;
chmod 0666, "/tmp/plotter.p";

## Execute gnuplot
$GNUPLOT=`which gnuplot`;
chomp($GNUPLOT);
if (-e $GNUPLOT){

    $gnu_results=`$GNUPLOT /tmp/plotter.p 2>&1`;
    
    if ($gnu_results) {
	print "Gnuplot Error: $gnu_results\n";
	unlink "/tmp/plotter.p";
    }
}else{
    $gnu_results=`/usr/bin/gnuplot /tmp/plotter.p`;
    if ($gnu_results) {
	print "Gnuplot Error: $gnu_results\n";
	unlink "/tmp/plotter.p";
    }
}

# Modify ownership so subsequent runs by ohter users won't break.
chmod 0666, $output;

## Clean up.
if (!$tmpfilesave){
    foreach $xyfile (@xyfiles){
	unlink "$xyfile";
    }
    unlink "/tmp/plotter.p";
}

## Convert the results to PNG if needed, and view
if($png eq CONVERT){
    $pngfile="$output";
    $pngfile=~s/\.ps/\.png/;
    `convert -rotate 90 $output $pngfile`;
    chmod 0666, "$pngfile";
    if (!$show){
	`display $pngfile`;
    }

}else{
    if (!$show){
	`gv $output -landscape  -media Letter`;
    }
}



