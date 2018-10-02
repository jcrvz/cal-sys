import os
import glob
#import datetime as dt
import time
#from time import strftime, gmtime, localtime
#import sys
#import numpy
#from math import pi

#os.system('modprobe w1-gpio')
#os.system('modprobe w1-therm')
base_dir = '/sys/bus/w1/devices/'
device_folder = glob.glob(base_dir+'28*')

devices = {'0315652579ff':0, # air1
'03156525f3ff':1, # air2
'0115657384ff':2, # air3
'021561a71dff':3, # water1
'031561a8ddff':4, # water2
'031561a971ff':5} # water3

base_file = 'calorimeter'
ext_file = '.txt'
time_start = time.time()
time_file = time.strftime('%d%m%y',(time.localtime(time_start)))
filename = base_file + ext_file

#waiting_dev = 0.01 # sec / waiting per device read
waiting_time = 60*5 # sec = 60*( t[min] )
#number_reps = 30 # reps per devices

# Volume of water inside the tank
volume = 0.040224331754990294562901453901 # m^3

# If the file doesn't exist, then create it
if os.path.isfile(filename) == False:
	fid = open(filename,'w')
	fid.close()

def read_temp_raw():
	while True:
		try:
			f=open(device_file,'r')
			lines=f.readlines();
			f.close()
			break
		except (IOError, EOFError) as e:
			pass
		except:
			print("An undefined error has ocurred!")
			pass
	return lines

def read_temp():
	lines=read_temp_raw()
	while lines[0].strip()[-3:]!='YES':
		time.sleep(0.5)
		lines=read_temp_raw()
	equals_pos=lines[1].find('t=')
	if equals_pos!=-1:
		temp_string=lines[1][equals_pos+2:]
		temp_c=float(temp_string)/1000.0
	return temp_c

def water_properties(temp_val):
	density_val = 1.6255e-05**temp_val**3 - 0.0060214*temp_val**2 + 0.02093*temp_val + 1000.1 # kg/m^3
	capacity_val = -3.5877e-08*temp_val**5 + 1.2118e-05*temp_val**4 - 0.0015636*temp_val**3 + 0.10363*temp_val**2 - 3.2662*temp_val + 4216.2 # J/kg.K
	return density_val, capacity_val

while True:
	# Read current time
	current_time = time.time()

	# Reset measuremnts
	measurements = [-1.0,-1.0,-1.0,-1.0,-1.0,-1.0]
	rho 		 = [-1.0,-1.0,-1.0,-1.0] # TW1 TW2 TW3 TWA
	cp 			 = [-1.0,-1.0,-1.0,-1.0]
	HeatPowers 	 = [-1.0,-1.0,-1.0,-1.0]
	Delta_temps 	 = [-1.0,-1.0,-1.0,-1.0]

	# Update sensors measurements
	for dev in device_folder:
		device_file=dev+'/w1_slave'
		dev_id=dev.strip()[-12:]
		measurements[devices[dev_id]] = read_temp()

	# Get all water measurements
	current_temps = [measurements[k] for k in range(3,6) if measurements[k] > 0]

	# Find the average temperature
	current_temps.extend([sum(current_temps, 0.0)/len(current_temps)])

	# Read previous data
	last_line = os.popen("tail -n 1 %s" %filename).read()
	last_data = last_line.split('\t')
	if len(last_data) != 1:
		past_time 	 = float(last_data[0])
		past_temps 	 = [float(st) for st in last_data[4:8]]
	else:
		past_time 	 = current_time
		past_temps 	 = current_temps

	for k in range(0,4):
		# Determine the thermophysical properties
		rho[k], cp[k] = water_properties(current_temps[k])

		# Calculate the finite differences
		Delta_temps[k] = round(current_temps[k] - past_temps[k],3)
		Delta_time 	  = round(current_time - past_time,0)

		# Verify if there is any change to report
		if (abs(Delta_temps[k]) != 0.0) & (Delta_time != 0.0):
			# Estimate the heat power
			HeatPowers[k] = volume*rho[k]*cp[k]*Delta_temps[k]/Delta_time
		else:
			HeatPowers[k] = float('nan')

	# Open and write new data
	with open(filename,'a') as output:
		time_str = '%d' % current_time
		air_temps_str   = ''.join(['%.3f'%(measurements[k]) + '\t' for k in range(0,3)]) # temperatures from water
		water_temps_str = ''.join(['%.3f'%(current_temps[k]) + '\t' for k in range(0,4)]) # temperatures from water
		#Delta_temp_str  = ''.join(['%.3f'%(Delta_temps[k]) + '\t' for k in range(0,4)]) # differences of temperature
		#Delta_time_str = '%d' % Delta_time
		#HeatPower_str = ''.join(['%.1f'%(HeatPowers[k]) + '\t' for k in range(0,4)]) # heat powers
		TimeLabel = time.strftime('%H:%M:%S-%d/%m/%y',time.localtime(current_time))

		output.write(time_str + '\t' + air_temps_str + water_temps_str + TimeLabel + '\n')
	output.close()

	time.sleep(waiting_time)
