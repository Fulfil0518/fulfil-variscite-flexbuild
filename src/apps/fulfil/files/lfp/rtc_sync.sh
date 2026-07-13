#!/bin/bash

# Define I2C bus and device address
I2C_BUS=2
I2C_ADDR=0x68

# Function to set RTC from system time
set_rtc_from_system() {
    # Get current system time components
    local sec=$(date +%S)
    local min=$(date +%M)
    local hour=$(date +%H)
    local day=$(date +%u)    # Day of week (1-7)
    local date=$(date +%d)
    local month=$(date +%m)
    local year=$(date +%y)

    # Convert decimal to BCD format
    sec_bcd=$(printf "0x%02X" $((10#$sec / 10 * 16 + 10#$sec % 10)))
    min_bcd=$(printf "0x%02X" $((10#$min / 10 * 16 + 10#$min % 10)))
    hour_bcd=$(printf "0x%02X" $((10#$hour / 10 * 16 + 10#$hour % 10)))
    day_bcd=$(printf "0x%02X" $((10#$day / 10 * 16 + 10#$day % 10)))
    date_bcd=$(printf "0x%02X" $((10#$date / 10 * 16 + 10#$date % 10)))
    month_bcd=$(printf "0x%02X" $((10#$month / 10 * 16 + 10#$month % 10)))
    year_bcd=$(printf "0x%02X" $((10#$year / 10 * 16 + 10#$year % 10)))

    # Write time components to RTC registers
    i2cset -y $I2C_BUS $I2C_ADDR 0x00 $sec_bcd    # Seconds
    i2cset -y $I2C_BUS $I2C_ADDR 0x01 $min_bcd    # Minutes
    i2cset -y $I2C_BUS $I2C_ADDR 0x02 $hour_bcd   # Hours
    i2cset -y $I2C_BUS $I2C_ADDR 0x03 $day_bcd    # Day of week
    i2cset -y $I2C_BUS $I2C_ADDR 0x04 $date_bcd   # Date
    i2cset -y $I2C_BUS $I2C_ADDR 0x05 $month_bcd  # Month
    i2cset -y $I2C_BUS $I2C_ADDR 0x06 $year_bcd   # Year
}

# Function to set system time from RTC
set_system_from_rtc() {
    # Read time components from RTC registers
    sec_bcd=$(i2cget -y $I2C_BUS $I2C_ADDR 0x00)
    min_bcd=$(i2cget -y $I2C_BUS $I2C_ADDR 0x01)
    hour_bcd=$(i2cget -y $I2C_BUS $I2C_ADDR 0x02)
    day_bcd=$(i2cget -y $I2C_BUS $I2C_ADDR 0x03)
    date_bcd=$(i2cget -y $I2C_BUS $I2C_ADDR 0x04)
    month_bcd=$(i2cget -y $I2C_BUS $I2C_ADDR 0x05)
    year_bcd=$(i2cget -y $I2C_BUS $I2C_ADDR 0x06)

    # Strip '0x' prefix
    sec_bcd=${sec_bcd#0x}
    min_bcd=${min_bcd#0x}
    hour_bcd=${hour_bcd#0x}
    day_bcd=${day_bcd#0x}
    date_bcd=${date_bcd#0x}
    month_bcd=${month_bcd#0x}
    year_bcd=${year_bcd#0x}

    # Convert BCD to decimal
    sec=$(( ( (0x$sec_bcd & 0xF0) >> 4 ) * 10 + (0x$sec_bcd & 0x0F) ))
    min=$(( ( (0x$min_bcd & 0xF0) >> 4 ) * 10 + (0x$min_bcd & 0x0F) ))
    hour=$(( ( (0x$hour_bcd & 0xF0) >> 4 ) * 10 + (0x$hour_bcd & 0x0F) ))
    day=$(( ( (0x$day_bcd & 0xF0) >> 4 ) * 10 + (0x$day_bcd & 0x0F) ))
    date=$(( ( (0x$date_bcd & 0xF0) >> 4 ) * 10 + (0x$date_bcd & 0x0F) ))
    month=$(( ( (0x$month_bcd & 0xF0) >> 4 ) * 10 + (0x$month_bcd & 0x0F) ))
    year=$(( ( (0x$year_bcd & 0xF0) >> 4 ) * 10 + (0x$year_bcd & 0x0F) ))

    # Adjust year to include century
    year=$((year + 2000))

    # Assemble date string in format 'YYYY-MM-DD HH:MM:SS'
    datetime=$(printf "%04d-%02d-%02d %02d:%02d:%02d" $year $month $date $hour $min $sec)

    # Set system time
    date -s "$datetime"
}

# Main script logic
case "$1" in
    set)
        set_rtc_from_system
        ;;
    get)
        set_system_from_rtc
        ;;
    *)
        echo "Usage: $0 [set|get]"
        ;;
esac
