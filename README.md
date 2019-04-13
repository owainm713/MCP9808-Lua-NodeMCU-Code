# MCP9808-Lua-NodeMCU-Code Collection of functions to use the MCP9808 digital temerpature sensor

This contains functions which can be used to configure an MCP9808 digital temperature sensor from
an ESP8266 running Lua/NodeMCU 2.2.  For testing I used an Adafruit MCP9808 breakout board connected
to an Adafruit Feather Huzzah ESP8266 board.

This code requires both the i2c and bit NodeMCU modules as part of your firmware build

For physical connections 
-MCP9808 SCL - ESP8266 SCL 
-MCP9808 SDA - ESP8266 SDA
-MCP9808 Vdd - ESP8266 3V
-MCP9808 Gnd - ESP8266 Gnd
-MCP9808 Alert - is open drain so requires a pull-up resistor if using

The entire set of functions takes about 10k of memory. To shave that down only include the functions 
you need in your program.  

The following are the base functions that are generally required most set ups
-read_register(devAddr, regAddr)
-read_word_register(devAddr, regAddr)
-write_register(devAddr, regAddr, regValue)
-write_word_register(devAddr, regAddr, regValue)
-twos_complement_conversion(value)
-conversion_to_twos_complement(value)
-read_temperature()

These next functions pick and choose as required if you want to do more than read the temperature
-set_t_lower(temperature)
-set_t_upper(temperature)
-set_t_critical(temperature)
-set_resolution(res)
-set_hysteresis(hys)
-set_shutdown(mode)
-set_critical_lock()
-set_window_lock()
-set_alerts(control, select, polarity, mode)
-get_alerts()
-clear_interrupt()

Refer to the MCP9808 datasheet for info on how to use the various settings of the sensor
