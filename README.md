# pgnuplot

pgnuplot.pl is a front end script to add functionality to gnuplot.
------------------------------------------------------------------

Here is an example to illustrate:

    pgnuplot.pl -fCc#[2]_c#[4]:D,:Pdots:datafile.dat::Cc#[5]*c#[6]_c#[7]/100:Ppoints
:datafile_2.dat -t"Plot Title" -p"Xaxis Label" -q"Y axis Label"

Lets look at the `-f` argument first:

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
don't specify any columns, the first two columns in our file will be
taken by default. Alternatively, we can specify just a single column
to plot by specifying "Cc#[N]_#".

Another useful example is plotting GPS data from a NMEA string, where
latitude and longitude are in columns 2 and 4 respectively, and
degrees and minutes are concatinated together - i.e. DDMM.MMMM for LAT
and DDDMM.MMMM for long.  One could do this by simply converting to
decimal degrees on the fly with something like this:

-fCsubstr(c#[4],0,3)+substr(c#[4],3,length(c#[4]))/60_substr(c#[2],0,2)+substr(c
#[2],2,length(c#[2]))/60

The second optional file argument is a delimiter.  We so this with the
"D" flag, for example "D," for a comma delimited file or "D\t" for a
tab delimited file. When the "D" flag is not specified, white space is
the default.

We may also speicfy the point type to plot with the "P" flag.  Here
the options are the same as are available in gnuplot - points, dots,
lines, linespoints, etc.

Each of the file arguments are strung together with :'s as shown above
and as we said before, the sets of arguments for each file are strung
together with ::.

Other Arguments:

Self explainitory:
-t'Title'
-p'Xlabel'
-q'Ylabel'


