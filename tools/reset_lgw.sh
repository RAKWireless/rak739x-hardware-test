#!/usr/bin/env bash

GPIO_CHIP="giochip0"
RESET_GPIO=17

GPIOSET="gpioset -m time -u 100000 ${GPIO_CHIP}"

# Reset gateway
echo "Concentrator reset through ${GPIO_CHIP}:${RESET_GPIO} (using libgpiod)"
${GPIOSET} ${RESET_GPIO}=0 2>/dev/null
${GPIOSET} ${RESET_GPIO}=1 2>/dev/null
${GPIOSET} ${RESET_GPIO}=0 2>/dev/null

exit 0
