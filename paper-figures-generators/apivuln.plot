#!/usr/bin/gnuplot

reset

set terminal svg enhanced size 1200,270 font 'Arial,16'
set output 'apivuln.svg'

# line styles
set style line 1 lt 1 lc rgb '#00A6ED' #
#set style line 2 lt 1 lc rgb '#FFB400' #
#set style line 3 lt 1 lc rgb '#00A6ED' #
set style line 2 lt 1 lc rgb '#F6511D' #

set style data histogram
set style fill pattern 5 border -1
set style histogram rowstacked
set boxwidth 0.5 relative

set key invert top outside right horizontal font 'Arial,13' samplen 1
set grid

# Make the x axis labels easier to read.
set xtics rotate by 18 right out scale 0.5 font 'Arial,12'
set xtics out nomirror

set label '{/:Italic %: proportion of fuzzed API elements vulnerable}' enhanced at graph 0.72,0.76 font 'Arial,13'

set yrange [:60]
set ylabel "N# of API Elements"
plot for [COL=2:3] 'apivuln.dat' using COL:xticlabels(1) title columnheader ls COL - 1, \
                              '' using 0:($2+$3+6):xticlabels(1):(sprintf("%d%%", $4)) \
                                       notitle columnheader with labels font 'Arial,11'
