--MCP9808, collection of functions for use with the MCP9808
-- digital temperature sensor
-- based on NodeMCU 2.2

-- created April 12, 2019
-- modified April 12, 2019

--[[
Copyright 2019 Owain Martin

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]


-- i2c setup
-- id - always 0
-- pinSDA - 2 - board pin 4  can be any pin 
-- pinSCL - 1 - board pin 5  can be any pin 
-- speed - only i2c.SLOW supported

-- Note adafruit documentation has board pin 4 & 5 to NodeMCU 2 & 1 reversed

i2c.setup(0, 2, 1, i2c.SLOW)
i2cAddress = 0x18

-- single byte read
function read_register(devAddr, regAddr)

    local ack, lsb, data
    
    i2c.start(0)
    ack = i2c.address(0,devAddr,i2c.TRANSMITTER) 
    i2c.write(0,regAddr) -- address of register to read
    i2c.start(0)    
    i2c.address(0, devAddr, i2c.RECEIVER)
    data = i2c.read(0,1)
    i2c.stop(0)

    lsb = string.byte(data)

    return lsb
end

-- single word read
function read_word_register(devAddr, regAddr)

    local ack, data, msb, lsb
    
    i2c.start(0)
    ack = i2c.address(0,devAddr,i2c.TRANSMITTER)
    i2c.write(0,regAddr) -- address of register to read
    i2c.start(0)    
    i2c.address(0, devAddr, i2c.RECEIVER)
    data = i2c.read(0,2)    
    i2c.stop(0)

    msb, lsb = string.byte(data,1,2)

    return msb, lsb
end

-- single byte write
function write_register(devAddr, regAddr, regValue)

    local ack
    
    i2c.start(0)
    ack = i2c.address(0,devAddr,i2c.TRANSMITTER) 
    i2c.write(0,regAddr, regValue)       
    i2c.stop(0)

    return
end

-- single word write
function write_word_register(devAddr, regAddr, regValue)

    local msb, lsb, ack

    -- break regValue into msb & lsb
    msb = bit.band(regValue, 0xFF00)
    msb = bit.rshift(msb, 8)  -- 0x1F
    lsb = bit.band(regValue, 0x00FF) -- 0x8C

    -- send data
    i2c.start(0)
    ack = i2c.address(0,devAddr,i2c.TRANSMITTER) 
    i2c.write(0,regAddr,{msb, lsb})    
    i2c.stop(0)

    return
end

function twos_complement_conversion(value)

    -- test the sign bit, bit 12    
    if bit.isset(value, 12) == true then
        --print("negative number")
        value = bit.band(value, 0xFFF) -- strip off sign bit
        value = bit.bxor(value, 0xFFF)
        value = -(value+1)
        value = value/16
    else
        --print("positive number")
        value = value/16  

    end

    return value
end

function conversion_to_twos_complement(value)

    if value < 0 then
        --print("negative number")
        value = value * -16
        value = bit.band(value, 0xFFF)
        value = bit.bxor(value, 0x1FFF)
        value = value + 1
    else
        --print("positive number")
        value = value * 16
        value = bit.band(value, 0xFFF)
    end

    return value
end

function read_temperature()

    -- read_temperature, function to return the temperature
    -- value stored in register 0x05 (T ambient)

    local msb, lsb, temperature

    msb, lsb = read_word_register(0x18, 0x05)   -- read data from sensor Ta register
    temperature = bit.lshift(msb, 8) + lsb      -- combine 2 bytes of data together
    print(string.format("%x", temperature))
    temperature = bit.band(temperature, 0x1FFF) -- strip off alert flags from temperature data
    temperature = twos_complement_conversion(temperature)  -- convert 2s comp to normal 

    return temperature
end

function set_t_lower(temperature)

    -- set_t_lower, function to set the T lower temperature
    -- this sets register 0x03

    temperature = conversion_to_twos_complement(temperature)
    write_word_register(0x18, 0x03, temperature)

    return
end

function set_t_upper(temperature)

    -- set_t_upper, function to set the T upper temperature
    -- this sets register 0x02

    temperature = conversion_to_twos_complement(temperature)
    write_word_register(0x18, 0x02, temperature)

    return
end

function set_t_critical(temperature)

    -- set_t_critical, function to set the T critical temperature
    -- this sets register 0x04

    temperature = conversion_to_twos_complement(temperature)
    write_word_register(0x18, 0x04, temperature)

    return
end

function set_resolution(res)

    -- set_resolutionm function to set the  sensor resolution
    -- values; 0.5, 0.25, 0.125, 0.0625 degress C
    -- sets bits 0 & 1 of register 0x08

    local resBits

    if res == 0.5 then
        resBits = 0x00
    elseif res == 0.25 then
        resBits = 0x01
    elseif res == 0.125 then
        resBits = 0x02
    else
        resBits = 0x03
    end

    write_register(i2cAddress, 0x08, resBits)

    return
end

function set_hysteresis(hys)

    -- set_hysteresis, function to set the sensor hysteresis level
    -- values; 0, 1.5, 3, 6 degrees C
    -- sets bits 9 & 10 of register 0x01

    local bit9, bit10, msb, lsb, regValue

    if hys == 0 then
        bit9 = 0
        bit10 = 0
    elseif hys == 1.5 then
        bit9 = 1
        bit10 = 0
    elseif hys == 3 then
        bit9 = 0
        bit10 = 1
    else
        bit9 = 1
        bit10 = 1
    end

    -- get config register data (reg 0x01)
    msb, lsb = read_word_register(i2cAddress, 0x01)

    -- set bits 9 & 10
    if bit9 == 1 then
        msb = bit.set(msb, 1)
    else
        msb = bit.clear(msb, 1)
    end

    if bit10 == 1 then
        msb = bit.set(msb, 2)
    else
        msb = bit.clear(msb, 2)
    end

    regValue = bit.lshift(msb, 8) + lsb
    write_word_register(i2cAddress, 0x01, regValue)

    return
end

function set_shutdown(mode)

    -- set_shutdown, function to set the sensor shutdown mode
    -- value true = shutdown/low power mode, false = continuous conversion
    -- sets bit 8 of register 0x01

    local msb, lsb, regValue

    -- get config register data (reg 0x01)
    msb, lsb = read_word_register(i2cAddress, 0x01)

    if mode == true then
        msb = bit.set(msb, 0)
    else
        msb = bit.clear(msb, 0)
    end

    -- write value back to config register
    regValue = bit.lshift(msb, 8) + lsb
    write_word_register(i2cAddress, 0x01, regValue)

    return
end

function set_critical_lock()

    -- set_critical_lock, function to enable the sensor critical
    -- temperature lock
    -- sets bit 7 of register 0x01

    -- Note: once set the lock can only be cleared by a
    -- power on reset

    local msb, lsb, regValue

     -- get config register data (reg 0x01)
    msb, lsb = read_word_register(i2cAddress, 0x01)
       
    lsb = bit.set(msb, 7)
    
    -- write value back to config register
    regValue = bit.lshift(msb, 8) + lsb
    write_word_register(i2cAddress, 0x01, regValue)

    return
end

function set_window_lock()

    -- set_window_lock, function to enable the sensor window
    -- temperature lock
    -- sets bit 6 of register 0x01

    -- Note: once set the lock can only be cleared by a
    -- power on reset

    local msb, lsb, regValue

     -- get config register data (reg 0x01)
    msb, lsb = read_word_register(i2cAddress, 0x01)
       
    lsb = bit.set(msb, 6)
    
    -- write value back to config register
    regValue = bit.lshift(msb, 8) + lsb
    write_word_register(i2cAddress, 0x01, regValue)

    return
end
    

function set_alerts(control, select, polarity, mode)

    -- set_alerts, function to set the alert propoerties of the sensor including:
    -- control:  true/false  - bit 3
    -- select: all/critical  - bit 2
    -- polarity:  high/low   - bit 1
    -- mode: comparator/interrupt - bit 0
    -- sets bits 0-3 of register 0x01

    local msb, lsb, regValue

    -- get config register data (reg 0x01)
    msb, lsb = read_word_register(i2cAddress, 0x01)

    if control == true then
        lsb = bit.set(lsb, 3)
    else
        lsb = bit.clear(lsb, 3)
    end

    if select == "critical" then
        lsb = bit.set(lsb, 2)
    else
        lsb = bit.clear(lsb, 2)
    end

    if polarity == "high" then
        lsb = bit.set(lsb, 1)
    else
        lsb = bit.clear(lsb, 1)
    end

    if mode == "interrupt" then
        lsb = bit.set(lsb, 0)
    else
        lsb = bit.clear(lsb, 0)
    end

    -- write value back to config register
    regValue = bit.lshift(msb, 8) + lsb
    write_word_register(i2cAddress, 0x01, regValue)

    return
end    

function get_alerts()

    -- get_alerts, function to get the sensor alert data including
    -- Ta vs Tup, Tlow, Tcrit bits 13-15 in register 0x05
    -- Alert Status, bit 4 in register 0x01

    local msb, lsb, regValue, Ta, alertStatus

    -- get Ta vs data from reg 0x05
    msb, lsb = read_word_register(i2cAddress, 0x05)
    Ta = bit.band(msb, 0xE0)
    Ta = bit.rshift(Ta, 5)

    -- get Alert Status from reg 0x01
    msb, lsb = read_word_register(i2cAddress, 0x01)
    alertStatus = bit.isset(lsb, 4)

    return Ta, alertStatus
end

function clear_interrupt()

    -- clear_interrupt, function to set the sensor clear interrupt
    -- bit to cleat the interrupt, when in interrupt mode
    -- sets bit 5 of register 0x01

    local msb, lsb, regValue

    -- get config register data (reg 0x01)
    msb, lsb = read_word_register(i2cAddress, 0x01)

    -- set bit 5
    lsb = bit.set(lsb, 5)

    -- write value back to config register
    regValue = bit.lshift(msb, 8) + lsb
    write_word_register(i2cAddress, 0x01, regValue)

    return
end

--  function example area ----------

set_resolution(0.0625)
set_t_lower(10.5)
set_t_upper(19.75)
set_t_critical(25)
set_hysteresis(1.5)
set_alerts(true, "all", "high", "comparator")

-- read all the registers and print their value in Hex
for i = 1, 7, 1 do
    msb, lsb = read_word_register(0x18, i)
    print(string.format("%x", msb),string.format("%x", lsb))
end

lsb = read_register(0x18, 0x08)
print(lsb)

print(read_temperature())
print(get_alerts())