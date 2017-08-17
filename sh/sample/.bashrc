# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

if [ "${SSH_TTY}x" != "x" ]; then
cat <<__EOF__
##########################################################
##                                                      ##
## ASCII TEXT                                           ##
## http://www.patorjk.com/software/taag/                ##
##                                                      ##
##########################################################
__EOF__
fi
