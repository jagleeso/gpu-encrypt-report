#!/system/bin/sh
cd /data/local/tmp

# Run the opencl_aes test program 100 times consecutively.
# We vary this between the two experiments by
# 1) leaving the display off during the test (and not interacting with the phone)
# 2) turning the display on during the test (by pressing the lock button on the side)

# Observations when doing 1) 
# (refer to 100_consecutive_runs.txt)
#
# Observations when doing 2) 
#
# a)
# on first unlock, phone stalls while loading, display elements not completely loaded
# after locking and and unlocking again it works (Launcher app crashed) 
#
# b)
# - on first unlock (did it earlier this time), phone screen shows up, swipe to unlock, screen goes black
# - screen looks like its on, but its completely unresponsive to lock/unlock/touch; forced to reboot
# - opencl_aes program is not returning consistent results (encrypted data is 00's)
# - analyzing the top output of a newly booted instance to this broken state indicates all the com.android and com.google processes have 

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100; do
    ./opencl_aes
done
