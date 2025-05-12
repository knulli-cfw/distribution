#!/bin/sh

SUSPEND_FLAG="/var/run/suspend-flag"

# Define the lowest CPU frequency (this value is an example)
LOWEST_FREQ=240000

# Define the input device for the power button
INPUT_DEVICE=/dev/input/event0

# Define the path to save the current CPU frequency
CURRENT_FREQ_PATH=/tmp/current_cpu_freq

# Path to the CPU frequency setting
CPUFREQ_PATH=/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

# Define the path for the backlight control
BACKLIGHT_PATH=/sys/class/backlight/backlight.2/bl_power

# Global list of process names to suspend/resume
PROCESSES_TO_MANAGE="retroarch drastic flycast mupen64plus PPSSPP" #SDLPoP OpenBOR4432 OpenBOR6510 VVVVVV"

# Function to save current CPU frequency and set to lowest
save_and_reduce_cpu_freq() {
    # Save the current CPU frequency
    cat $CPUFREQ_PATH > $CURRENT_FREQ_PATH

    # Set the CPU to the lowest frequency
    echo $LOWEST_FREQ > $CPUFREQ_PATH
}

# Function to suspend processes
suspend_processes() {
    for proc in $PROCESSES_TO_MANAGE; do
        local pids=$(pidof $proc)
        for pid in $pids; do
	    echo $proc "-" $pid
            kill -SIGSTOP $pid
        done
    done
}

new_suspend_processes() {
    for proc in $PROCESSES_TO_MANAGE; do
        local pids=$(ps aux | awk -v pname="$proc" '$11==pname {print $2}')
	echo $proc $pid
        for pid in $pids; do
            kill -SIGSTOP $pid
        done
    done
}


# Function to resume processes
resume_processes() {
    for proc in $PROCESSES_TO_MANAGE; do
        local pids=$(pidof $proc)
        for pid in $pids; do
            kill -SIGCONT $pid
        done
    done
}

# Function to turn off the screen
turn_off_screen() {
    # Turn off the backlight
    echo 4 > $BACKLIGHT_PATH
}

# Function to restore the screen
restore_screen() {
    # Turn on the backlight
    echo 0 > $BACKLIGHT_PATH
}

# Function to enter soft suspend
enter_soft_suspend() {
    if [ ! -f "$SUSPEND_FLAG" ]; then
        # Only enter suspend if we're not already suspended
        save_and_reduce_cpu_freq
        suspend_processes
        turn_off_screen

        # Set the flag to indicate the system is now in suspend mode
        touch "$SUSPEND_FLAG"
    fi
}

# Function to exit soft suspend
exit_soft_suspend() {
    if [ -f "$SUSPEND_FLAG" ]; then
        # Restore the CPU frequency
        cat "$CURRENT_FREQ_PATH" > "$CPUFREQ_PATH"

	# Restore the screen
	restore_screen

	# Resume processes
	resume_processes

        # Remove the flag to indicate the system is now in normal mode
        rm -f "$SUSPEND_FLAG"
    fi
}

# Check the current state and call the appropriate function
if [ -f "$SUSPEND_FLAG" ]; then
    exit_soft_suspend
else
    enter_soft_suspend
fi

