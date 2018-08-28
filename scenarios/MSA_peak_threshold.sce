/*
Author : Timo Vehviläinen
Date: August 2014
Developed with Presentation Version 17.1
*/

scenario = "MSA_peak_threshold";

#HEADER
write_codes = false;
stimulus_properties = Event, string, Temperature, number, VAS, number, Target_temperature, number;
response_matching = simple_matching;
#Set 4 response buttons [recommend PAGE_UP, UP_ARROW, PAGE_DOWN, DOWN_ARROW, SPACE and ENTER to go with code prompts]
active_buttons = 6;
button_codes = 1,2,3,4,5,6;
default_font_size = 20;
scenario_type = fMRI;
pulse_code = 64; #tarvitaan
scan_period = 2675; #tarvitaan jos mode on emulation
pulses_per_scan = 40; # leikemaara
pulse_width = 20; 


#######################################################################

#SDL
begin;

picture {
	text {		
		transparent_color = 0,0,0;
		text_align = align_left;
		caption = "mri sync received, starting...";  
	};
	x = 0; y = 0;
} mrisync;

# -- Sync scanner with the 
trial {
	picture mrisync;
	time=0;
	mri_pulse = 1;
	duration=1000; # Multiple of the TR, need to check what it will be
	code="fix";
} wait_sync;

#A text picture used to display the current state of the scenario
picture {
	text {		
		transparent_color = 0,0,0;
		text_align = align_left;
		caption = "Starting up...";  
	} progress;
	x = 0; y = 200;
	
	text {
		transparent_color =0,0,0;
		caption = " ";
	} subject;
	x = 0; y = -200;
	
	text {
		transparent_color =0,0,0;
		caption = "+";
	} cursor;
	x = 0; y = -50;
	
	text {
		transparent_color =0,0,0;
		caption = "-";
	} VAS_upper_bound;
	x = 0; y = 50;
	
	text {
		transparent_color =0,0,0;
		caption = "-";
	} VAS_lower_bound;
	x = 0; y = -50;
	
	text {
		transparent_color =0,0,0;
		caption = " ";
	} target;
	x = 200; y = 0;
	
	text {
		caption = "Peak threshold scenario";
		font_size = 40;
	} title;
	x = 0; y = 350;
	
	text {
		caption = "Press PAGE_UP to raise temperature 1 degree, \nUP_ARROW to raise temperature 0.1 degrees, \nPAGE_DOWN to lower temperature 1 degree, \nDOWN_ARROW to lower temperature 0.1 degrees,\nSPACE to initiate peak, \nor ENTER to exit program";
	} instruction;
	x = -300; y = 0;
	
} display;

#A stimulus event used for logging various events, and for backup temporary logs
trial{ 
	stimulus_event { 
		save_logfile { filename = "failsafe.log"; }; 
	} log_code; 
} log_event;

####################################################################3

#PCL
begin_pcl;
wait_sync.present();

/*
***	INCLUDE				start_up.pcl
***					
***	This external pcl-file requires that the following things are in place in order to work:
***		
***		- a picture called "display", which includes a text stimulus called "progress".
***		- a trial called log_event, which includes a stimulus event called log_code
***
***	See start_up.pcl, subroutines.pcl and initialisation.pcl for more info.
*/

include_once "MSA_start_up.pcl";

#Check that the thermode has reached default temperature before starting any sequence
progress.set_caption("Checking initial temperature...", true);
display.present();

wait_for_start_temp(iport, oport);

#Start the main scenario
progress.set_caption("Starting experiment...", true);
display.present();

#Set variables
string current_temp_text = "Current temperature [C] = xxxx";
string subject_text = "Subject VAS: 0";
string target_text = "Target temperature = xxxx";
string target_log = "0";
double start_temp = hex_to_double(experiment_data[1]); 
subject.set_caption(subject_text, true);
double last_response_count = response_manager.total_response_count();
double last_target_temperature = hex_to_double(experiment_data[4]);
target.set_caption(target_text.replace("xxxx", string(last_target_temperature)), true);

#Set up mouse
mouse the_mouse = response_manager.get_mouse(1);
the_mouse.poll();
int mouse_y = the_mouse.y();

#The main loop of the scenario

loop until check_init(iport) begin #escape from the program if the signal time-outs

	send_command("M000", iport, oport);

	wait_interval (200);
	
	#get the latest signal from the device
	string signal = get_latest_signal(iport);
	
	#If the latest signal is still an echo from a previous temperature change, ignore it.
	#Otherwise incorrect temperatures would be logged.
	if signal[1] == 'T' || signal[1] == 'C' then
		continue;
	end;
	
	double temp = hex_to_double(signal);
	the_mouse.poll();
	
	#Check if the mouse has been moved since the last loop. Change cursor & text accordingly.
	if mouse_y != the_mouse.y() then
			mouse_y = the_mouse.y();
			display.set_part_y(3, ((mouse_y - 50)));
			
			log_code.set_event_code("VAS Change," + string(temp) + "," + string(mouse_y));
			log_event.present();
			
			subject.set_caption(subject_text.replace("0", string(mouse_y )), true);
			display.present();
	end;
	
	#Log the temperature measurement
	log_code.set_event_code("Measurement," + string(temp) + ", ," + target_log);
	log_event.present();
	
	progress.set_caption(current_temp_text.replace("xxxx", string(temp)), true);
	display.present();
	
	#Check if response buttons have been pressed since the last loop
	if response_manager.total_response_count() > last_response_count && response_manager.last_response() != 0 then
		
		last_response_count = last_response_count + 1;
		
		#Prepare to change the target temperature
		int last_response = response_manager.last_response();
		
		#Raise target temperature by 1 degree
		if last_response == 1 && last_target_temperature < 54 then
			last_target_temperature = last_target_temperature + 1;
		
		#or by 0.1 degree
		elseif last_response == 2 && last_target_temperature < 54 then
			last_target_temperature = last_target_temperature + 0.1;
		
		#or Lower target temperature by 1 degree
		elseif last_response == 3 && last_target_temperature > 4 then
			last_target_temperature = last_target_temperature - 1;
		
		#or by 0.1 degree
		elseif last_response == 4 && last_target_temperature > 4 then
			last_target_temperature = last_target_temperature - 0.1;
		
		#or initiate peak
		elseif last_response == 5 then
			
			string target_temperature = "T" + int_to_hex(int(10 * last_target_temperature));
			send_command(target_temperature, iport, oport);
			send_command("C003", iport, oport);
			target_log = string(hex_to_double(target_temperature));
			log_code.set_event_code("Initiate Peak," + string(temp) + ", ," + target_log);
			log_event.present();
			
		#or Exit Loop
		elseif last_response == 6 then
			log_code.set_event_code("Exit program," + string(temp));
			log_event.present();
			break;
		end;
		
		#Display the new target temperature
		target.set_caption(target_text.replace("xxxx", string(last_target_temperature)), true);
	end;
	
	#Check for the subject response switch
	if signal[1] == 'P' then 
		
		log_code.set_event_code("Subject Response," + string(hex_to_double(signal)));
		log_event.present();
		
		progress.set_caption("Subject response occured!", true);
		display.present();
		
		#Go back to starting temperature, and wait for it to settle
		last_target_temperature = hex_to_double(experiment_data[1]);
		
		target.set_caption(target_text.replace("xxxx", string(last_target_temperature)), true);
		wait_for_start_temp(iport, oport);
		
	#record peak temperatures
	elseif (signal[1] == 'F' ||
			(target_log != "0" &&
			(int(target_log) < start_temp && temp < int(target_log)) ||
			(int(target_log) > start_temp && temp > int(target_log))))then
		
		progress.set_caption("Peak Temperature reached: " +  string(hex_to_double(signal)), true);
		display.present();
		
		log_code.set_event_code("Peak Temperature," + string(hex_to_double(signal)) + ", ," + target_log);
		log_event.present();
		wait_for_start_temp(iport, oport);
		target_log = "0";
		
	end;
end;

progress.set_caption("Ending experiment...", true);
display.present();