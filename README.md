# Hardware tests for RAK739x boards

This is a shell script that uses shutil2 to perform unit tests on  different hardware features in the RAK7391, RAK7392, RAK7393 and RAK7394. Different tests are run based on the different possible configurations. Conofiguration are defined by their configuration ID, a string that uniquely identifies the features in a device.

Current configuration IDs are:

```
$ ./rak739x_tests.sh 

Usage: ./rak739x_tests.sh <configuration_id>

Posible configuration_id values:
* rak7391-indoor-lora
* rak7391-indoor-lora-2g4
* rak7391-indoor-lora-lte
* rak7391-indoor-lora-mioty
* rak7391-indoor-lora-mioty-lte
* rak7391-outdoor-lora
* rak7391-outdoor-lora-lte
* rak7391-outdoor-lora-mioty
* rak7391-outdoor-lora-mioty-lte
* rak7392-lora
* rak7392-lte
* rak7392-mioty
* rak7393-lora-lte
* rak7393-lora-16ch-lte
* rak7393-lora-2g4-lte
* rak7393-lora-mioty-lte
* rak7394-lora
```

Running a certain configuration executes a subset of the available tests. A successful run looks like this:

```
$ ./rak739x_tests.sh rak7391-indoor-lora-mioty-lte

Dependency virtualenv already available
Dependency lshw already available
Dependency jq already available
Installing required python packages

CPU: Raspberry Pi Compute Module 4 Rev 1.1
CPU Serial Number: 10000000df6b752a
Memory: 3.7Gi
Storage: 29G
Device EUI: d83addFFFE061d3d
OS: rakpios-0.9.2-arm64

testLED
testBuzzer
testGPIOExpanders
testWiFi
testFanDriver
testOLED
testADC
testRTC
testSecurityElement
testTemperatureSensor
Temperature: 38.4 ºC
Humidity: 37.0 %
testRAK5146
Concentrator in /dev/ttyACM0 with EUI 0016C001F1568704 (corecell)
testRAK8213       
testMioty
testEMMC
testADM1184e
testUSB2
testUSB3
testUSB2UART
testRTL8125

Removing python packages

Ran 19 tests.

OK
```

An unsuccessful run, on the contrary, looks like this (requesting a RAK5148 that's not there):

```
$ ./rak739x_tests.sh rak7391-indoor-lora-2g4

Dependency virtualenv already available
Dependency lshw already available
Dependency jq already available
Installing required python packages

CPU: Raspberry Pi Compute Module 4 Rev 1.1
CPU Serial Number: 10000000df6b752a
Memory: 3.7Gi
Storage: 29G
Device EUI: d83addFFFE061d3d
OS: rakpios-0.9.2-arm64

testLED
testBuzzer
testGPIOExpanders
testWiFi
testFanDriver
testOLED
testADC
testRTC
testSecurityElement
testTemperatureSensor
Temperature: 38.6 ºC
Humidity: 37.4 %
testRAK5146
Concentrator in /dev/ttyACM0 with EUI 0016C001F1568704 (corecell)
testRAK5148       
ASSERT:Wrong number of RAK5148 found expected:<1> but was:<0>
shunit2:ERROR testRAK5148() returned non-zero return code.
testEMMC
testADM1184e
testUSB2
testUSB3
testUSB2UART
testRTL8125

Removing python packages

Ran 18 tests.

FAILED (failures=1)
```