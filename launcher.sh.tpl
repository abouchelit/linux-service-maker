#!/bin/sh -e

DAEMON="${CMD_START}"     # command line for the program
#daemon_OPT=""            # arguments provided to the program
DAEMONUSER="root"         # utilisateur du programme
daemon_NAME="${APP_NAME}" # daemon name, has to be the same as the program executable

PATH="/sbin:/bin:/usr/sbin:/usr/bin"

# If the command is not found within the path, the program exits with a return code 0
test -x $DAEMON || exit 0

. /lib/lsb/init-functions # this is for ubuntu and debian distributions 

d_start () {
        log_daemon_msg "Starting system $daemon_NAME Daemon"
	start-stop-daemon --background --name $daemon_NAME --start --quiet --chuid $DAEMONUSER --exec $DAEMON #-- $daemon_OPT
        log_end_msg $?
}

# TODO: fix the stop issue
d_stop () {
        log_daemon_msg "Stopping system $daemon_NAME Daemon"
	#start-stop-daemon --name $daemon_NAME --stop --retry 5 --quiet --name $daemon_NAME --> need to kill the launcher and the java process
	
	log_daemon_msg "start-stop-daemon failed to stop the service $daemon_NAME --> killing service with the dirty way"
	RES=$(killall -qg $daemon_NAME)

	log_end_msg $?
}

case "$1" in

        start|stop)
                d_${1}
                ;;

        restart|reload|force-reload)
                        d_stop
                        d_start
                ;;

        force-stop)
               d_stop
                killall -qg $daemon_NAME || true
                sleep 2
                killall -qg -9 $daemon_NAME || true
                ;;

        status)
                status_of_proc "$daemon_NAME" "$DAEMON" "system-wide $daemon_NAME" && exit 0 || exit $?
                ;;
        *)
                echo "Usage: /etc/init.d/$daemon_NAME {start|stop|force-stop|restart|reload|force-reload|status}"
                exit 1
                ;;
esac
exit 0

