all: incubot.so incubot-read incubot-localhost

incubot.so: incubot.scm analysis.scm dispatch.scm bot.scm incubot-read
	csc -s incubot.scm

incubot-read: incubot-read.scm
	csc -static -R srfi-1,srfi-4,srfi-13,srfi-18,srfi-69 incubot-read.scm

incubot-freenode: incubot-freenode.scm incubot.so
	csc incubot-freenode.scm

incubot-localhost: incubot-localhost.scm incubot.so
	csc incubot-localhost.scm

prob:
	csi -s prob.scm  && \
	sort prob.dat > prob-sort.dat && \
	echo 'plot "prob-sort.dat"' | gnuplot -persist
