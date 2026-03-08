%% Event Check: Nov 25 2012 - Detailed Data Comparison
% This script loads the detailed 'humberdefs' data to verify the lateral
% displacement event, comparing it against the summary data results.

clear; clc; close all;

%% 1. Load the Detailed Data
filename = 'humberdefs_20121125_dsa.mat';

% Check for file in likely locations
if exist(filename, 'file')
    load(filename);
elseif exist(fullfile('CW1-data', filename), 'file')
    load(fullfile('CW1-data', filename));
elseif exist(fullfile('..', 'CW1-data', filename), 'file')
    load(fullfile('..', 'CW1-data', filename));
else
    error('File %s not found. Please check the file name and location.', filename);
end

%% 2. Extract Data
% Handle case where variables are not in structure 'D'
% The file might contain: date, fftsize, frames, fs, tdata, time
% This block ensures compatibility with different data versions
if exist('D', 'var')
    % Data is inside structure D
    t_accs = D.accs_timestamp;
    t_gps  = D.gps_timestamp;
    data_accs = D.accs;
    data_gps  = D.gps;
    data_source = 'D_struct';
    
    % Extract GPS (if available)
    gps_edn = data_gps(:, 2); % East Deck North
    gps_wdn = data_gps(:, 5); % West Deck North
    
elseif exist('accs', 'var') && exist('gps', 'var')
    % Data is directly in workspace
    t_accs = accs_timestamp;
    t_gps  = gps_timestamp;
    data_accs = accs;
    data_gps  = gps;
    data_source = 'workspace';
    
    % Extract GPS
    gps_edn = data_gps(:, 2);
    gps_wdn = data_gps(:, 5);
    
elseif exist('tdata', 'var') && exist('time', 'var')
    % Data is in raw tdata/time format (likely just Accs/Wind)
    data_source = 'tdata';
    fprintf('Detected raw tdata/time format.\n');
    
    % Convert time if it is a cell array or char array
    if iscell(time) || ischar(time)
        if isempty(time)
            t_accs = [];
        else
            try
                t_accs = datenum(time);
            catch
                t_accs = [];
            end
        end
    else
        t_accs = time;
    end
    
    data_accs = tdata;
    
    % Ensure data_accs is oriented correctly (samples x channels)
    if size(data_accs, 1) < size(data_accs, 2) && size(data_accs, 1) <= 20
        data_accs = data_accs';
    end
    
    n_samples = size(data_accs, 1);
    
    % Handle Time Vector Generation/Correction
    % If time vector is missing or mismatched, regenerate it using fs
    if numel(t_accs) ~= n_samples
        if exist('fs', 'var') && ~isempty(fs)
            fprintf('Regenerating time vector (Time len: %d, Data len: %d, fs: %.2f)...\n', numel(t_accs), n_samples, fs);
            
            if isempty(t_accs)
                % Try to extract date from filename
                date_match = regexp(filename, '\d{8}', 'match');
                if ~isempty(date_match)
                    start_time = datenum(date_match{1}, 'yyyymmdd');
                else
                    start_time = datenum(2012, 11, 25); % Fallback
                end
            else
                start_time = t_accs(1);
            end
            
            t_accs = start_time + (0:n_samples-1)' / fs / 86400;
        else
            warning('Time vector mismatch and no fs found. Plotting against index.');
            t_accs = (1:n_samples)'; % Ensure column vector
        end
    end

    % Check for 16-channel format based on user definition
    % Standard format: Cols 1-3 (Sensor 1), Cols 4-6 (Sensor 2), Col 10 (Wind), Col 11 (Lat Acc)
    if size(data_accs, 2) >= 16
        fprintf('Using 16-channel tdata definition.\n');
        % Channel 1: (E+W)/2 east mm
        % Channel 4: (E+W)/2 north mm (Axial/Lateral)
        % Channel 10: WIND
        % Channel 11: LAT acc
        
        % Use the generated time vector for GPS plots
        t_gps = t_accs;
        
        % Extract and convert mm to m
        gps_mean_east = data_accs(:, 1) / 1000; 
        gps_mean_north = data_accs(:, 4) / 1000;
        
        % Map Wind, Vert, and Lat Accel
        wind_speed = data_accs(:, 10);
        acc_lat    = data_accs(:, 11) / 1000;    % Convert mm/s^2 to m/s^2
        acc_vert   = data_accs(:, 16) / 9806.65; % Convert mm/s^2 to g
        
        % Mark Wind Dir as missing for this format
        wind_dir = []; 
        
    else
        % Fallback for unknown tdata structure
        t_gps = [];
        gps_mean_east = [];
        gps_mean_north = [];
        
        wind_speed = data_accs(:, 4); % Assumption for 5-col
        wind_dir   = data_accs(:, 5); % Assumption for 5-col
        acc_lat    = data_accs(:, 3); % Assumption for 5-col
        acc_vert   = [];
        
        warning('GPS data not found or format unrecognized. Lateral Displacement plot will be empty.');
    end
    
else
    error('Could not find recognizable data (D, accs/gps, or tdata/time) in %s.', filename);
end

% Handle legacy D-struct extraction if not handled in tdata block
if ~exist('wind_speed', 'var')
    wind_speed = data_accs(:, 4);
    wind_dir   = data_accs(:, 5);
    acc_lat    = data_accs(:, 3);
end

%% 3. Diagnostics (Check for empty/NaN data)
fprintf('--- Data Diagnostics ---\n');
fprintf('Time Steps: %d\n', length(t_accs));
fprintf('Wind Speed: Range [%.2f, %.2f]\n', min(wind_speed), max(wind_speed));
if ~isempty(gps_mean_east), fprintf('GPS East:   Range [%.4f, %.4f] m\n', min(gps_mean_east), max(gps_mean_east)); end
if ~isempty(gps_mean_north), fprintf('GPS North:  Range [%.4f, %.4f] m\n', min(gps_mean_north), max(gps_mean_north)); end
fprintf('------------------------\n');

%% 3. Generate Plots
figure('Name', 'Event Check: Nov 25 2012 - Detailed (humberdefs)', 'NumberTitle', 'off', 'Color', 'w');

% Subplot 1: Wind Speed
subplot(4, 1, 1);
plot(t_accs, wind_speed, 'b');
ylabel('Speed (m/s)'); title('Wind Speed'); grid on;
datetick('x', 'HH:MM', 'keeplimits');
axis tight;

% Subplot 2: Vertical Acceleration (or Wind Direction if available)
subplot(4, 1, 2);
if ~isempty(acc_vert)
    plot(t_accs, acc_vert, 'r');
    ylabel('Accel (g)'); title('Vertical Acceleration (Ch 16)');
else
    plot(t_accs, wind_dir, 'r.', 'MarkerSize', 2);
    ylabel('Deg'); title('Wind Direction'); 
    ylim([0 360]); yticks(0:90:360);
end
grid on;
datetick('x', 'HH:MM', 'keeplimits');
axis tight;

% Subplot 3: Lateral Displacement (GPS North)
subplot(4, 1, 3); hold on;
if ~isempty(t_gps)
    if strcmp(data_source, 'tdata') && size(data_accs, 2) >= 16
        % Plot Mean East and Mean North for 16-channel data
        plot(t_gps, gps_mean_east, 'b', 'DisplayName', 'Mean East (Lat)');
        plot(t_gps, gps_mean_north, 'k', 'DisplayName', 'Mean North (Axial)');
    else
        plot(t_gps, gps_edn, 'k', 'DisplayName', 'East (N)');
        plot(t_gps, gps_wdn, 'm', 'DisplayName', 'West (N)');
    end
    legend('show', 'Location', 'best');
else
    text(0.5, 0.5, 'GPS Data Missing in File', 'Units', 'normalized', 'HorizontalAlignment', 'center');
end
ylabel('Disp (m)'); title('Lateral Displacement (GPS North)'); grid on;
datetick('x', 'HH:MM', 'keeplimits');
axis tight;

% Subplot 4: Lateral Acceleration
subplot(4, 1, 4);
plot(t_accs, acc_lat, 'g');
ylabel('Accel (m/s^2)'); title('Lateral Acceleration (H)'); grid on;
datetick('x', 'HH:MM', 'keeplimits');
axis tight;

xlabel('Time (UTC)');

% Link axes for zooming
linkaxes(findall(gcf, 'type', 'axes'), 'x');