all: incubot.so read incubot-localhost

incubot.so: incubot.scm analysis.scm dispatch.scm bot.scm read
	csc -s incubot.scm

read: read.scm
	csc read.scm

incubot-freenode: incubot-freenode.scm incubot.so
	csc incubot-freenode.scm

incubot-localhost: incubot-localhost.scm incubot.so
	csc incubot-localhost.scm

prob:
	csi -s prob.scm  && \
	sort prob.dat > prob-sort.dat && \
	echo 'plot "prob-sort.dat"' | gnuplot -persist
