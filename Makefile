prob:
	csi -s prob.scm  && \
	sort prob.dat > prob-sort.dat && \
	echo 'plot "prob-sort.dat"' | gnuplot -persist
