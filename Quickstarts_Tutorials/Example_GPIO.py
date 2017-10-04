# SL 2017

import argparse
import RPi.GPIO as GPIO
import time

parser = argparse.ArgumentParser()
parser.add_argument('--value', '-V', type=int, required=True, help='The value to write to the LED, 0 for off or anything else for on')
parser.add_argument('--duration', '-D', type=int, required=True, help='The time in seconds to apply the specified value to the LED')
args = parser.parse_args()

print("Driving LED with value {} for {} seconds...".format(args.value, args.duration))

try:

	GPIO.setmode(GPIO.BCM) # Use broadcom numbering
	GPIO.setup(26, GPIO.OUT)
	GPIO.output(26, args.value)
	time.sleep(args.duration)
	GPIO.output(26, 0)

except:
	pass
finally:
	GPIO.cleanup()
