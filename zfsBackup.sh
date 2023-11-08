#!/bin/sh

help()
{
  echo "Usage: zfssnap
                [ -p | --prefix ]
                [ -r | --retention ]
                [ -s | --src_0]"
  exit 2
}

SHORT=p:,r:,h:,l:,s:
LONG=prefix:,retention:,help:,log:,src_0:
OPTS=$(getopt -a -n $0 --options $SHORT --longoptions $LONG -- "$@")

VALID_ARGUMENTS=$# # Returns the count of arguments that are in short or long options

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  help
fi

eval set -- "$OPTS"

# These variables are named first because they are nested in other variables.
snap_prefix=snap
retention=90
src_0="pool_0/dataset_0"
log=/dev/null

while :
do
  case "$1" in
    -p | --prefix )
      snap_prefix="$2"
      shift 2
      ;;
    -r | --retention )
      retention="$2"
      shift 2
      ;;
    -s | --src_0 )
      src_0="$2"
      shift 2
      ;;
    -h | --help)
      help
      ;;
    -l | --log)
      log="$2"
      shift 2
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      help
      ;;
  esac
done

# Full paths to these utilities are needed when running the script from cron.
date=/bin/date
grep=/usr/bin/grep
sed=/usr/bin/sed
sort=/usr/bin/sort
xargs=/usr/bin/xargs
zfs=/sbin/zfs

today="$snap_prefix-`date +%Y%m%d%H%M`"
snap_today="$src_0@$today"
snap_old=`$zfs list -t snapshot -o name | $grep "$src_0@$snap_prefix*" | $sort -r | $sed 1,${retention}d | $xargs -n 1`

# Create a blank line between the previous log entry and this one.
echo >> $log

# Print the name of the script.
echo "$0 $#" >> $log

# Print the current date/time.
$date >> $log

echo >> $log

# Look for today's snapshot and, if not found, create it.
if $zfs list -H -o name -t snapshot | $grep "$snap_today" > /dev/null
then
	echo "Today's snapshot '$snap_today' already exists." >> $log
	# Uncomment if you want the script to exit when it does not create today's snapshot:
	#exit 1
else
	echo "Taking today's snapshot: $snap_today" >> $log
	$zfs snapshot -r $snap_today >> $log 2>&1
fi

echo >> $log

# Remove snapshot(s) older than the value assigned to $retention.
echo "Attempting to destroy old snapshots..." >> $log

if [ -n "$snap_old" ]
then
	echo "Destroying the following old snapshots:" >> $log
	echo "$snap_old" >> $log
	$zfs list -t snapshot -o name | $grep "$src_0@$snap_prefix*" | $sort -r | $sed 1,${retention}d | $xargs -n 1 $zfs destroy -r >> $log 2>&1
else
    echo "Could not find any snapshots to destroy."	>> $log
fi

# Mark the end of the script with a delimiter.
echo "**********" >> $log
# END OF SCRIPT