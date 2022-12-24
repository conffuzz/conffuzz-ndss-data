#!/usr/bin/gnuplot

reset

set terminal svg enhanced size 1200,270 font 'Arial,16'
set output 'typesvuln.svg'

# line styles
# set style line 2 lt 1 lc rgb '#00A6ED' #
# set style line 3 lt 1 lc rgb '#FFB400' #
# set style line 4 lt 1 lc rgb '#00A6ED' #
# set style line 5 lt 1 lc rgb '#F6511D' #

set style data histogram
set style fill pattern 5 border -1
set style histogram rowstacked
set boxwidth 0.4 relative

set key invert top outside right horizontal enhanced font 'Arial,13' samplen 1
set grid

# Make the x axis labels easier to read.
set xtics rotate by 18 right out scale 0.5 font 'Arial,12'
set xtics out nomirror

set label '{/:Italic X/Y: Unique custom structs / Total crashes involving structs}' enhanced at graph 0.025,0.755 font 'Arial,13'

set yrange [:120]
set ylabel "N# of Crashes"
plot for [COL=2:5] 'typesvuln.dat' using COL:xticlabels(1) enhanced title columnheader ls COL + 4, \
                                '' using ($0+0.65):(113):(stringcolumn(1) eq "gpg / libgcrypt" ? \
                                                          sprintf("%d", $2+$3+$4+$5) : "") \
                                         notitle columnheader with labels font 'Arial,11', \
                                '' using 0:($2+$3+$4+$5+10):xticlabels(1):($4 != 0 ? sprintf("%d/%d", $6, $4) : "0") \
                                         notitle columnheader with labels font 'Arial,12.5', \
                                '' using ($0-0.68):(111):(stringcolumn(1) eq "gpg / libgcrypt" ? \
                                                          sprintf("%d/%d", $6, $4) : "") \
                                         notitle columnheader with labels font 'Arial,12.5', \
