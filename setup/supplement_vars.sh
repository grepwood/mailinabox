#!/bin/bash
# Supplement vars.sh on CentOS

mkdir -p /lib/init
echo "TMPTIME=0" > /lib/init/vars.sh
echo "SULOGIN=no" >> /lib/init/vars.sh
echo "DELAYLOGIN=no" >> /lib/init/vars.sh
echo "UTC=yes" >> /lib/init/vars.sh
echo "VERBOSE=no" >> /lib/init/vars.sh
echo "FSCKFIX=no" >> /lib/init/vars.sh
echo "unset EDITMOTD" >> /lib/init/vars.sh
echo "unset RAMRUN" >> /lib/init/vars.sh
echo "unset RAMLOCK" >> /lib/init/vars.sh
echo "if [ -r /proc/cmdline ]; then" >> /lib/init/vars.sh
printf "\tfor ARG in \$(cat /proc/cmdline); do\n" >> /lib/init/vars.sh
printf "\t\tcase \$ARG in\n" >> /lib/init/vars.sh
printf "\t\tNOSWAP=yes\n" >> /lib/init/vars.sh
printf "\t\tbreak\n" >> /lib/init/vars.sh
printf "\t\t;;\n" >> /lib/init/vars.sh
printf "\t\tif [ \"\$RUNLEVEL\" ] && [ \"\$PREVLEVEL\" ] ; then\n" >> /lib/init/vars.sh
printf "\t\t\tVERBOSE=\"no\"\n" >> /lib/init/vars.sh
printf "\t\tfi\n" >> /lib/init/vars.sh
printf "\t\tbreak\n" >> /lib/init/vars.sh
printf "\t\t;;\n" >> /lib/init/vars.sh
printf "\tesac\n" >> /lib/init/vars.sh
printf "\tdone\n" >> /lib/init/vars.sh
echo "fi" >> /lib/init/vars.sh
echo "if [ \"\$INIT_VERBOSE\" ] ; then" >> /lib/init/vars.sh
printf "\tVERBOSE=\"\$INIT_VERBOSE\"\n" >> /lib/init/vars.sh
echo "fi" >> /lib/init/vars.sh
