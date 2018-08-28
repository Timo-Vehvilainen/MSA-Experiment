%Author: Timo Vehvilï¿½inen
%Date: August 2014
%Developed with Matlab R2013a

%% 
clear all;
close all;
mean_error = [[] []]
for slope_number = 1:5

    %slopes-matrix holds the following 3 columns:
    %   [   time_diff   temp_diff   slope   ]
    %where:
    %   - time_diff tells the time difference between the start of the peak
    %       and the apex of the peak
    %   - temp_diff tell the temperature difference between the start of the peak
    %       and the apex of the peak
    %   - slope is (temp_diff / time_diff)
    slopes = [[] [] []];
    is_skin = 'noskin';
    for j = 1:2
        subplot(2,2,((j*2)-1));
        
        %Retrieve the data. filenames have to be of a specific format, eg
        %"slope5_noskin-MSA_peak_threshold.txt"
        filename = sprintf('slope%d_%s-MSA_peak_threshold.txt', slope_number, is_skin);
        [Time, Time_uncertainty, Event, Temperature, VAS, Target_temperature] = importfile(filename);
        
        %Check for any other files with the same subject name and extend
        %the data to the existing vectors
        
        counter = 1;
        while true
            filename = sprintf('slope%d_%s-MSA_peak_threshold%d.txt', slope_number, is_skin, counter);
            if exist(filename, 'file') == 2
                [newTime, newTime_uncertainty, newEvent, newTemperature, newVAS, newTarget_temperature] = importfile(filename);
                Time = cat(1, Time, newTime);
                Time_uncertainty = cat(1, Time_uncertainty, newTime_uncertainty);
                Event = cat(1, Event, newEvent);
                Temperature = cat(1, Temperature, newTemperature);
                VAS = cat(1, VAS, newVAS);
                Target_temperature = cat(1, Target_temperature, newTarget_temperature);
                counter = counter + 1;
                continue;
            end
            break;
        end
        
        
        %Remove faulty measurements, where temperature = 0 
        false_indices = intersect(find(strcmp(Event, 'Measurement') == 1), find(Temperature < 4));
        Time(false_indices) = [];
        Time_uncertainty(false_indices) = [];
        Event(false_indices) = [];
        Temperature(false_indices) = [];
        VAS(false_indices) = [];
        Target_temperature(false_indices) = [];

        %Extract he indices where peaks happen
        measurement_idx = find(strcmp(Event(:), 'Measurement') == 1);
        slope_idx = find(Target_temperature(:) ~= 0);

        %Make a helper vector to differentiate between different peaks (with tolerance of 1, for VAS-changes)
        peak_changes = find(diff(slope_idx) > 2) + 1;
        peak_changes = [1, peak_changes'];

        %Plot properties
        ylabel('Lämpötila [\circC]');
        xlabel('Aika piikin alusta [s]');
        axis([0 70 0 55]);
        %Finnish titles
        if strcmp(is_skin, 'skin') == 1
            iho = 'ihokontaktilla';
        else
            iho = 'ilman ihokontaktia';
        end
        title(sprintf('Lämpötilamittaukset %s', iho));
        grid on;
        set(gca,'xtick',0:10:70);
        set(gca,'ytick',0:5:55);
        hold on;
        

        %Plot all the peaks on top of each other
        for i = 1:(length(peak_changes) - 1)
            %Get next entire peak
            current_slope_idxs = slope_idx(peak_changes(i):peak_changes(i+1)-1);

            %ignore throwaway values
            if numel(current_slope_idxs) < 2
               continue; 
            end

            %Get peak data
            current_peak = [Time(current_slope_idxs(2:end)), Temperature(current_slope_idxs(2:end))];

            %Set the peak to start from time 0
            current_peak_start_time = Time(current_slope_idxs(2));
            
            %Get the peak index and construct actual slope data
            [peak_temp, peak_idx] = max(abs(current_peak(:,2) - current_peak(2,2)));
            time_dif = current_peak(peak_idx, 1) - current_peak_start_time;
            slopes(i, 1) = time_dif / 1000;
            slopes(i, 2) = current_peak(peak_idx, 2) - current_peak(2, 2);
            slopes(i, 3) = slopes(i, 2) / slopes(i, 1);
            if current_peak(2, 2) < 35
                color = 'g-';
            else
                color = 'b-';
            end
            
            %Plot
            blueline = plot((current_peak(:, 1) - current_peak_start_time) / 1000, current_peak(:, 2), color);

        end
        
        %Plot the ideal spike on top of the other spikes
        x = linspace(0, 50000, 10000);
        y_down = 38 - slope_number * x;
        y_up = 38 + slope_number * x;
        redline = plot(x, y_down, 'r-', 'LineWidth', 1)
        plot(x, y_up, 'r-', 'LineWidth', 1);
        
        if strcmp(is_skin, 'noskin') == 1
            legend([blueline, redline], {'mitatut piikit', 'ideaalinopeus S_{MSA}'});
        end

        %Plotting the actual measured slopes alongside temperature data 
        subplot(2,2,(j*2));
        slopes = sortrows(slopes, 2);
        hold on;
        blueline = plot(slopes(:,2), slopes(:,3), 'b.-') 
        redline = plot([-30 0], [(slope_number*(-1)) (slope_number * (-1))], 'r-', 'LineWidth', 1)
        plot([0,15],[slope_number slope_number], 'r-', 'LineWidth', 1);
        title(sprintf('Todellinen kulmakerroin %s', iho));
        ylabel('Kulmakerroin [\circC/sec]');
        xlabel('Piikin amplitudi [\circC]');
        axis([-30 30 -6 6]);
        grid on;
        set(gca,'xtick',-30:5:30);
        set(gca,'ytick',-6:1:6);
        
        if strcmp(is_skin, 'noskin') == 1
            legend([blueline, redline], {'nopeus S', 'S_{MSA}'}, 'Location', 'southeast');
        end
        
        negative_mean = [];
        positive_mean = [];
        for i = 1:size(slopes, 1)
            if slopes(i, 2) < -5
                negative_mean(end+1) = slopes(i, 3);
            elseif slopes(i, 2) > 5
                positive_mean(end+1) = slopes(i, 3);
            end
        end
        mean_error(end+1, 1) =  (-1)*slope_number - mean(negative_mean);
        mean_error(end, 2) =  slope_number - mean(positive_mean);
        
        hold off;
        slopes = [];
        
        %save image
        filename = sprintf('FigureSlope%d', slope_number);
        print('-dpdf', filename);
        
        %Prepare for reading the skin-contact file
        is_skin = 'skin';
    end
    mean_error
    figure;
end
close all;

close;