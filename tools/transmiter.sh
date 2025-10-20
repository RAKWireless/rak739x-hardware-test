#!/bin/bash

# Usage
usage() {
   echo "Usage: $0 [OPTION]"
   echo ""
   echo "Options:"
   echo "  -h,--help    Print this help"
   echo "  -d,--device  The device the concentrator is under"
   echo ""
}

# Parse options
SHORT=d:h
LONG=device:help
OPTS=$(getopt --options $SHORT --longoptions $LONG -- "$@")

if [ $? -ne 0 ]; then
	usage
   exit
fi

eval set -- "$OPTS"

while :
do
   case $1 in
      -h | --help)
         usage
         exit
         ;;
      -d | --device)
         DEVICE=$2
         shift 2
         ;;
      --)
         shift;
         break
         ;;
   esac
done

if [ "$DEVICE" == "" ]; 
then
   usage
   exit
fi

# Build command
COMMAND="./tools/test_loragw_hal_tx "
[[ "$DEVICE" =~ "tty" ]] && COMMAND="$COMMAND -u "
COMMAND="$COMMAND -d $DEVICE -k 0 -c 0 -r 1250 -f 867.5 -m LORA -s 7 -b 125 -n 1000 -z 10 -t 3000 --pa 1 --pwid 0"
[[ "$DEVICE" =~ "spidev0.0" ]] && sed -i "s/RESET_GPIO=6/RESET_GPIO=17/g" ./tools/reset_lgw.sh
[[ "$DEVICE" =~ "spidev0.1" ]] && sed -i "s/RESET_GPIO=17/RESET_GPIO=6/g" ./tools/reset_lgw.sh

# Execute
$COMMAND

