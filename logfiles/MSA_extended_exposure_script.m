%Author: Timo Vehviläinen
%Date: August 2014
%Developed with Matlab R2013a

%% 
clear all;
close all;

%Check for any other files with the same subject name and extend
%the data to the existing vectors
files = cellstr(ls('*MSA_extended_exposure*.txt'));
Time = []; Time_uncertainty = []; Event = []; Temperature = []; VAS = []; Target_temperature = [];

%Concatenate the measurement data from all log files
for i = 1:length(files)
    filename = files{i};
    [newTime, newTime_uncertainty, newEvent, newTemperature, newVAS, newTarget_temperature] = importfile(filename);
    Time = cat(1, Time, newTime);
    Time_uncertainty = cat(1, Time_uncertainty, newTime_uncertainty);
    Event = cat(1, Event, newEvent);
    Temperature = cat(1, Temperature, newTemperature);
    VAS = cat(1, VAS, newVAS);
    Target_temperature = cat(1, Target_temperature, newTarget_temperature);
end

%Find the relevant temperature and VAS indeces
measurement_idx = find(Temperature ~= 0);
vas_idx = find(VAS ~= 0);

% Plot (with horizontal error bars for time uncertainty)
subplot(211);
herrorbar(Time(measurement_idx), Temperature(measurement_idx), Time_uncertainty(measurement_idx),'.');
title('Extended exposure experiment');
ylabel('Temperature [C]');
xlabel('Time [msec]');
subplot(212);
stairs(Time(vas_idx) / 1000, VAS(vas_idx), 'g');
ylabel('VAS-response');
xlabel('Time [msec]');