#! /bin/sh

# -----------------------------------------------------------------------------
# Unit test suite for RAK739X boards
# -----------------------------------------------------------------------------

. ./tools/utils.sh

# -----------------------------------------------------------------------------

AVAILABLE_CONFIGURATIONS=" 
  rak7391-indoor-lora 
  rak7391-indoor-lora-2g4
  rak7391-indoor-lora-lte 
  rak7391-indoor-lora-mioty
  rak7391-indoor-lora-mioty-lte
  rak7391-outdoor-lora
  rak7391-outdoor-lora-lte
  rak7391-outdoor-lora-mioty
  rak7391-outdoor-lora-mioty-lte
  rak7392-lora
  rak7392-lte
  rak7392-mioty
  rak7393-lora
  rak7393-lora-lte
  rak7393-lora-16ch-lte
  rak7393-lora-2g4-lte
  rak7393-lora-mioty-lte
  rak7394-lora
  transmission
"

print_configurations() {
  echo
  echo "${COLOR_ERROR}Posible configuration_id values:${COLOR_END}"
  for CONFIGURATION in $AVAILABLE_CONFIGURATIONS
  do
    echo "${COLOR_ERROR}* $CONFIGURATION"
  done
  echo
}

# Show usages if called without parameters
if [ $# -ne 1 ] 
then
  echo
  echo "${COLOR_ERROR}Usage: $0 <configuration_id>${COLOR_END}"
  print_configurations
  exit 1
fi
CONFIGURATION="$1"
shift

# Show valid parameters if wrong input
if [ $( echo $AVAILABLE_CONFIGURATIONS | grep -w $CONFIGURATION | wc -l ) -ne 1 ]
then
  echo
  echo "${COLOR_ERROR}Wrong configuration value.${COLOR_END}"
  print_configurations
  exit 1
fi

# Carrier board
CARRIER_BOARD=$( echo $CONFIGURATION | cut -d'-' -f1 )
IS_RAK7391=$( [ "$CARRIER_BOARD" = "rak7391" ] && echo 1 || echo 0 )
IS_RAK7392=$( [ "$CARRIER_BOARD" = "rak7392" ] && echo 1 || echo 0 )
IS_RAK7393=$( [ "$CARRIER_BOARD" = "rak7393" ] && echo 1 || echo 0 )
IS_RAK7394=$( [ "$CARRIER_BOARD" = "rak7394" ] && echo 1 || echo 0 )

IS_TRANSMISSION=$( [ "$CARRIER_BOARD" = "transmission" ] && echo 1 || echo 0 )

# Features, based on configuration id
HAS_RAK5146=$( echo $CONFIGURATION | grep -w "lora" | wc -l )
HAS_RAK5148=$( echo $CONFIGURATION | grep -w "2g4" | wc -l )
HAS_RAK8123=$( echo $CONFIGURATION | grep -w "lte" | wc -l )
HAS_MIOTY=$( echo $CONFIGURATION | grep -w "mioty" | wc -l )
HAS_RAK1906=$( echo $CONFIGURATION | grep -w "rak7391" | grep -w "indoor" | wc -l )
HAS_WIFI=$( [ $IS_TRANSMISSION -eq 1 ] && echo 0 || echo 1 )
HAS_CAMERAS=0
HAS_EMMC=$( [ $IS_TRANSMISSION -eq 1 ] && echo 0 || echo 1 )
HAS_NVME=0
HAS_RTC=$(( $IS_RAK7391 || $IS_RAK7392 || $IS_RAK7393 ))
HAS_LEDS=$(( $IS_RAK7391 || $IS_RAK7393 ))
HAS_BUTTON=$(( $IS_RAK7392 || $IS_RAK7393 ))
HAS_BUZZER=$IS_RAK7391
HAS_GPIO_EXPANDERS=$IS_RAK7391
HAS_FAN_DRIVER=$IS_RAK7391
HAS_ADC=$IS_RAK7391
HAS_SHTC3=$IS_RAK7391
HAS_ASM1184e=$(( $IS_RAK7391 || $IS_RAK7392 ))
HAS_RTL8125=$(( $IS_RAK7391 || $IS_RAK7392 ))
HAS_VL805=$(( $IS_RAK7391 || $IS_RAK7392 || $IS_RAK7394 ))
HAS_CH340=$(( $IS_RAK7391 || $IS_RAK7393 ))
HAS_ATEC608=$IS_RAK7391
HAS_USB2HUB=$(( $IS_RAK7391 || $IS_RAK7393 ))
HAS_RTL8111=$IS_RAK7392

EXPECTED_RAK5146=$( [ $( echo $CONFIGURATION | grep -w "16ch" | wc -l ) -eq 1 ] && echo 2 || echo 1 )
EXPECTED_CH340=$( [ $IS_RAK7391 -eq 1 ] && echo 2 || echo 1 )
EXPECTED_USB2HUB=$( [ $IS_RAK7391 -eq 1 ] && echo 2 || echo 1 )
EXPECTED_CAMERAS=1

# -----------------------------------------------------------------------------

oneTimeSetUp() {

  # Install dependencies
  dependencyCheck virtualenv python3-virtualenv
  dependencyCheck i2cdetect i2c-tools
  dependencyCheck jq
  dependencyCheck lshw

  # Enable I2C
  if [ $( raspi-config nonint get_i2c ) -ne 0 ]
  then
    echo "${COLOR_INFO}Enabling I2C${COLOR_END}"
    sudo raspi-config nonint do_i2c 0
  fi

  # Old libgpiod
  if [ ! -f /usr/bin/libgpiod.so.2 ]
  then
    echo "${COLOR_INFO}Copying libgpiod.so.2 to /usr/bin/${COLOR_END}"
    sudo cp tools/libgpiod.so.2 /usr/bin/
    sudo ldconfig
  fi

  # info
  systemInfo

  return 0

}

oneTimeTearDown() {
  
  # Hack for https://github.com/kward/shunit2/issues/112
  [ "${_shunit_name_}" = 'EXIT' ] && return 0

  # Tear down python environment
  #pythonEnvRemove

  return 0

}

# -----------------------------------------------------------------------------

testTransmission() {
  echo "${COLOR_CYAN}Starting transmission test${COLOR_RESET}"
  echo -n "${COLOR_YELLOW}"
  tools/transmiter.sh -d /dev/ttyACM0
  echo -n "${COLOR_END}"
  assertEquals 1 1
}

testLED() {
  local RET=255
  if command -v gpiofind >/dev/null 2>&1
  then
    [ $IS_RAK7391 -eq 1 ] && RET=$( gpioset 2 6=0 && gpioset 2 7=0 && sleep 1 && gpioset 2 6=1 && gpioset 2 7=1 && echo $? )
    [ $IS_RAK7393 -eq 1 ] && RET=$( gpioset 0 5=0 && sleep 1 && gpioset 0 5=1 && echo $? )
  else
    [ $IS_RAK7391 -eq 1 ] && RET=$( gpioset -t0 IO0_6=0 && gpioset -t0 IO0_7=0 && sleep 1 && gpioset -t0 IO0_6=1 && gpioset -t0 IO0_7=1 && echo $? )
    [ $IS_RAK7393 -eq 1 ] && RET=$( gpioset -t0 GPIO5=0 && sleep 1 && gpioset -t0 GPIO5=1 && echo $? )
  fi
  assertEquals "Error toggling the LEDs on the carrier board" 0 $RET
}

testButton() {
  # TODO RAK7392/3: Test GPIO16 going down on button press
  echo "${COLOR_CYAN}Press the device reset button NOW${COLOR_RESET}"
  echo -n "${COLOR_YELLOW}"
  timeout 20 gpiomon -n1 -f $( gpiofind GPIO16 )
  echo -n "${COLOR_END}"
  assertEquals "Error detecting button click" 0 $?
}

testBuzzer() {
  tools/buzzer.sh
  assertEquals "Error playing buzzer" 0 $?
}

testCameras() {
  COUNT=$( vcgencmd get_camera | cut -d' ' -f2 | sed  's/detected=//' | sed 's/,//' )
  assertEquals "Wrong number of cameras" $EXPECTED_CAMERAS $COUNT
}

testGPIOExpanders() {
  # GPIO Expanders are binded so the expected output is 1 meaning the device is busy
  i2cget -y 1 0x26 > /dev/null 2>&1
  assertEquals "GPIO Expander #1 not found" 1 $?
  i2cget -y 1 0x27 > /dev/null 2>&1
  assertEquals "GPIO Expander #1 not found" 1 $?
}

testFanDriver() {
  i2cget -y 1 0x2f > /dev/null 2>&1
  assertEquals "Fan driver not found" 0 $?
  PRODUCTID=$( i2cget -y 1 0x2f 0xfd b 2>/dev/null )
  assertEquals "Fan driver Product ID mismatch" 0x37 $PRODUCTID
  MANUFACTURERID=$( i2cget -y 1 0x2f 0xfe b 2>/dev/null )
  assertEquals "Fan driver Manufacturer ID mismatch" 0x5d $MANUFACTURERID
}

testOLED() {
  i2cget -y 1 0x3c > /dev/null 2>&1
  assertEquals "OLED screen not found" 0 $?
}

testADC() {
  i2cget -y 1 0x4b > /dev/null 2>&1
  assertEquals "ADC not found" 0 $?
}

testRTC() {
  # RTC is binded so the expected output is 1 meaning the device is busy
  i2cget -y 1 0x51 > /dev/null 2>&1
  assertEquals "RTC not found" 1 $?
}

testSecurityElement() {
  i2cget -y 1 0x60 > /dev/null 2>&1
  assertEquals "Security element not found" 0 $?
}

testTemperatureSensor() {
  echo -n "${COLOR_YELLOW}"
  ./tools/shtc3_read
  echo -n "${COLOR_END}"
  assertEquals "Error retrieving temperature from Temperature sensort" 0 $?
}

testRAK5146() {
  DESIGN="corecell" ./tools/find_concentrator.sh
  assertEquals "Wrong number of RAK5146 found" $EXPECTED_RAK5146 $?
}

testRAK5148() {
  DESIGN="sx1280" ./tools/find_concentrator.sh
  assertEquals "Wrong number of RAK5148 found" 1 $?
}

testRAK8213() {
  COUNT=$( lsusb | grep EG95 | wc -l )
  assertEquals "RAK8213-EG95 LTE module not found" 1 $COUNT
}

testMioty() {
  COUNT=$( lshw -quiet -businfo -c communication 2>/dev/null | grep "GWC-62-MY-868" | wc -l )
  assertEquals "Mioty module not found" 1 $COUNT
}

testEMMC() {
  COUNT=$( lsblk | grep disk | grep -v boot | grep -w "mmcblk0" | wc -l )
  assertEquals "eMMC drive not found" 1 $COUNT
}

testNVMe() {
  COUNT=$( lsblk | grep disk | grep -v boot | grep -w "nvme0n1" | wc -l )
  assertEquals "NMVe drive not found" 1 $COUNT
}

testASM1184() {
  COUNT=$( lspci | grep ASM1184e | wc -l )
  assertEquals "ASM1184e PCIe Switch not found" 5 $COUNT
}

testUSB2Hub() {
  COUNT=$( lsusb | grep "Terminus Technology" | wc -l )
  assertEquals "USB2 Hub not found" $EXPECTED_USB2HUB $COUNT
}

testVL805() {
  COUNT=$( lspci | grep VL805 | wc -l )
  assertEquals "VL805 USB3 Hub not found" 1 $COUNT
}

testCH340() {
  COUNT=$( lsusb | grep CH340 | wc -l )
  assertEquals "CH340 USB to UART chip not found" $EXPECTED_CH340 $COUNT
}

testRTL8125() {
  COUNT=$( lspci | grep RTL8125 | wc -l )
  assertEquals "RTL8125 2.4Gb Ethernet chip not found" 1 $COUNT
}

testRTL8111() {
  COUNT=$( lspci | grep RTL8111 | wc -l )
  assertEquals "RTL8111 Ethernet chip not found" 2 $COUNT
}

testWiFi() {
  COUNT=$( ip link show | grep wlan0 | wc -l )
  assertEquals "WiFi interface not found" 1 $COUNT
}

# -----------------------------------------------------------------------------

suite() {
  
  [ $HAS_BUZZER -eq 1 ] && suite_addTest testBuzzer
  [ $HAS_BUTTON -eq 1 ] && suite_addTest testButton
  [ $HAS_LEDS -eq 1 ] && suite_addTest testLED
  [ $HAS_CAMERAS -eq 1 ] && suite_addTest testCameras
  [ $HAS_GPIO_EXPANDERS -eq 1 ] && suite_addTest testGPIOExpanders
  [ $HAS_WIFI -eq 1 ] && suite_addTest testWiFi
  [ $HAS_FAN_DRIVER -eq 1 ] && suite_addTest testFanDriver
  [ $HAS_RAK1906 -eq 1 ] && suite_addTest testOLED
  [ $HAS_ADC -eq 1 ] && suite_addTest testADC
  [ $HAS_RTC -eq 1 ] && suite_addTest testRTC
  [ $HAS_ATEC608 -eq 1 ] && suite_addTest testSecurityElement
  [ $HAS_SHTC3 -eq 1 ] && suite_addTest testTemperatureSensor
  [ $HAS_RAK8123 -eq 1 ] && suite_addTest testRAK8213
  [ $HAS_EMMC -eq 1 ] && suite_addTest testEMMC
  [ $HAS_NVME -eq 1 ] && suite_addTest testNVMe
  [ $HAS_ASM1184e -eq 1 ] && suite_addTest testASM1184
  [ $HAS_USB2HUB -eq 1 ] && suite_addTest testUSB2Hub
  [ $HAS_VL805 -eq 1 ] && suite_addTest testVL805
  [ $HAS_CH340 -eq 1 ] && suite_addTest testCH340
  [ $HAS_RTL8125 -eq 1 ] && suite_addTest testRTL8125
  [ $HAS_RTL8111 -eq 1 ] && suite_addTest testRTL8111
  [ $HAS_MIOTY -eq 1 ] && suite_addTest testMioty
  [ $HAS_RAK5146 -eq 1 ] && suite_addTest testRAK5146
  [ $HAS_RAK5148 -eq 1 ] && suite_addTest testRAK5148

  [ $IS_TRANSMISSION -eq 1 ] && suite_addTest testTransmission

}

# -----------------------------------------------------------------------------

echo
. ./shunit2/shunit2
echo
