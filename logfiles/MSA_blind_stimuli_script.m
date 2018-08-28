%Author: Timo Vehviläinen
%Date: August 2014
%Developed with Matlab R2013a

%% 
clear all;
close all;

%[Time, Time_uncertainty, Event, Temperature, VAS, Target_temperature] = importfile('MSA_extended_exposure.txt');

%Check for any other files with the same scenario name and extend
%the data to the existing vectors
files = cellstr(ls('long_test-MSA_blind_stimuli*.txt'));
Time = [];Time_uncertainty = [];Event = [];Temperature = [];VAS = [];Target_temperature = [];

%Concatenate the measurement data from all log files
for i = 1:length(files)
    filename = files{i};
    [newTime, newTime_uncertainty, newEvent, newTemperature, newVAS, newTarget_temperature] = importfile(filename);
    start_idx = find(strcmp(newEvent(:), 'Start Sequence') == 1);
    measurement_idx = find(newTemperature > 5);
    measurement_idx(measurement_idx < start_idx) = [];
    Time = cat(1, Time, newTime(measurement_idx));
    Time_uncertainty = cat(1, Time_uncertainty, newTime_uncertainty(measurement_idx));
    Event = cat(1, Event, newEvent);
    Temperature = cat(1, Temperature, newTemperature(measurement_idx));
    VAS = cat(1, VAS, newVAS);
    Target_temperature = cat(1, Target_temperature, newTarget_temperature);
end
    
%separate the different sequence runs from the vectors
run_change_idx = find(diff(Time) < 0) + 1;

%deal with only one run in the vector
if isempty(run_change_idx)
    run_change_idx = [1 length(Time)];
else
    %add values to the end and beginning of the vector for indexing convenience
    run_change_idx = [1 run_change_idx' length(Time)];
end

%Plot properties
figure;
title('Blind stimulus experiment');
ylabel('Temperature [C]');
xlabel('Time [msec]');
axis = [0 60000 25 55];
grid on;
hold all;

%plot each run separately on the same figure
for i = 1:(length(run_change_idx) - 1)
    run_idx = run_change_idx(i):run_change_idx(i+1) - 1;
    start_time = Time(run_idx(1))
    plot((Time(run_idx) - start_time), Temperature(run_idx));
end
