%% Advanced SHM Analysis - Group 2 (Grade 70+ Plots)
% This script generates advanced engineering plots for the Humber Bridge,
% focusing on data reduction comparisons, dynamic response isolation,
% deck torsion, and long-term stiffness analysis.

clear; clc; close all;

%% 1. Load Datasets
% Define file paths
file_summary = 'h_summaries20160405_simple.mat';
file_event   = 'humberdefs_20121125_dsa.mat';

% --- Load Summary Data ---
if exist(file_summary, 'file')
    load(file_summary);
elseif exist(fullfile('CW1-data', file_summary), 'file')
    load(fullfile('CW1-data', file_summary));
else
    error('Summary file %s not found.', file_summary);
end
% Clean Summary Data (-999 to NaN)
data(data == -999) = NaN;
summary_data = data;
summary_t = t;
summary_lab = lab;
clear data t lab; % Clear to avoid confusion with event data

% --- Load Event Data (1Hz) ---
if exist(file_event, 'file')
    load(file_event);
elseif exist(fullfile('CW1-data', file_event), 'file')
    load(fullfile('CW1-data', file_event));
else
    error('Event file %s not found.', file_event);
end

% Extract Event Data (Handle structure variations)
if exist('D', 'var') && isfield(D, 'data')
    event_data = D.data;
    % Time vector generation (1Hz assumed if not present)
    if isfield(D, 'accs_timestamp')
        event_t = D.accs_timestamp;
    else
        N = size(event_data, 1);
        event_t = datenum(2012, 11, 25) + (0:N-1)'/86400;
    end
elseif exist('tdata', 'var')
    event_data = tdata;
    if size(event_data, 1) < size(event_data, 2), event_data = event_data'; end
    if exist('time', 'var') && isnumeric(time) && ~isempty(time)
        event_t = time;
    elseif exist('time', 'var') && (iscell(time) || ischar(time))
        try 
            event_t = datenum(time); 
        catch
            event_t = []; 
        end
        if isempty(event_t), N = size(event_data, 1); event_t = datenum(2012, 11, 25) + (0:N-1)'/86400; end
    else
        N = size(event_data, 1);
        event_t = datenum(2012, 11, 25) + (0:N-1)'/86400;
    end
else
    error('Could not extract event data.');
end

%% 2. Plot 9: Data Reduction Comparison (1Hz vs 30-min)
% Objective: Overlay raw 1Hz wind speed with 30-min mean wind speed.

% Create unified figure window with tabs
fig = figure('Name', 'Advanced SHM Analysis', 'Color', 'w', 'Position', [100, 100, 1000, 600]);
tabgp = uitabgroup(fig);

% Tab 1: Data Reduction
tab1 = uitab(tabgp, 'Title', 'Data Reduction');
axes('Parent', tab1);

% 2a. Extract 1Hz Wind Speed (Col 10)
ws_1hz = event_data(:, 10);

% 2b. Extract 30-min Wind Speed for Nov 25, 2012
% Find index for 'HBB_WIH000CDS' (Mean Wind Speed)
idx_ws_summary = find(strcmp(summary_lab, 'HBB_WIH000CDS'), 1);
if isempty(idx_ws_summary)
    warning('Summary wind speed channel not found. Using Col 1 as fallback.');
    idx_ws_summary = 1;
end

% Filter summary data for the specific day
target_day = floor(event_t(1));
day_mask = floor(summary_t) == target_day;
t_day_summary = summary_t(day_mask);
ws_day_summary = summary_data(day_mask, idx_ws_summary);

% Shift summary timestamps by 15 mins (center of 30-min interval) for alignment
t_day_summary_centered = t_day_summary + 15/(24*60);

% 2c. Plot
plot(event_t, ws_1hz, 'Color', [0.6 0.8 1], 'LineWidth', 0.5); hold on; % Light Blue
plot(t_day_summary_centered, ws_day_summary, 'r-o', 'LineWidth', 2, 'MarkerFaceColor', 'r'); % Red Bold

title('Data Reduction: 1Hz Raw vs 30-min Mean (Wind Speed)');
ylabel('Wind Speed (m/s)');
xlabel('Time (UTC)');
legend('1Hz Raw Data', '30-min Mean Statistics');
datetick('x', 'HH:MM', 'keeplimits');
grid on;
axis tight;

%% 3. Plot 10: Dynamic Response Isolation (HPF)
% Objective: HPF on GPS Height to isolate traffic/buffeting.

% Tab 2: Dynamic Response
tab2 = uitab(tabgp, 'Title', 'Dynamic Response');

% 3a. Extract GPS Height (Assume Col 3 based on [E, N, H] pattern)
if size(event_data, 2) >= 3
    gps_h_raw = event_data(:, 3); % East Deck Height (mm)
else
    error('Insufficient columns for GPS Height.');
end

% 3b. High-Pass Filter
% Remove quasi-static (< 0.05 Hz) using moving mean subtraction
fs = 1; % Hz
fc = 0.05; % Cutoff frequency (Hz)
window_size = round(fs / fc);

% Calculate dynamic component (Raw - Moving Mean)
gps_h_dynamic = gps_h_raw - movmean(gps_h_raw, window_size);

% 3c. Plot
subplot(2, 1, 1, 'Parent', tab2);
plot(event_t, gps_h_raw, 'k');
title('Raw GPS Height (Quasi-Static + Dynamic)');
ylabel('Disp (mm)');
datetick('x', 'HH:MM', 'keeplimits');
grid on; axis tight;

subplot(2, 1, 2, 'Parent', tab2);
plot(event_t, gps_h_dynamic, 'b');
title(sprintf('Isolated Dynamic Response (HPF > %.2f Hz)', fc));
ylabel('Disp (mm)');
xlabel('Time (UTC)');
datetick('x', 'HH:MM', 'keeplimits');
grid on; axis tight;

%% 4. Plot 11: Deck Torsion (East vs West Differential)
% Objective: Plot difference between East and West GPS Height.

% Tab 3: Deck Torsion
tab3 = uitab(tabgp, 'Title', 'Deck Torsion');
axes('Parent', tab3);

% 4a. Extract Heights (Assuming Sensor 1=Cols 1-3, Sensor 2=Cols 4-6)
if size(event_data, 2) >= 6
    h_east = event_data(:, 3);
    h_west = event_data(:, 6);
    
    % 4b. Calculate Torsion
    torsion_diff = h_east - h_west;
    
    % 4c. Plot
    plot(event_t, torsion_diff, 'm', 'LineWidth', 1);
    title('Deck Torsion: East Height - West Height');
    ylabel('Differential Disp. (mm)');
    xlabel('Time (UTC)');
    datetick('x', 'HH:MM', 'keeplimits');
    grid on; axis tight;
    
    % Add mean line
    yline(mean(torsion_diff, 'omitnan'), 'k--', 'Mean Twist');
else
    text(0.5, 0.5, 'Insufficient Data for Torsion (Need 6+ GPS cols)', 'HorizontalAlignment', 'center');
end

%% 5. Plot 12: Long-Term Stiffness (Freq vs Temp)
% Objective: Scatter plot of Fundamental Freq vs Temperature.

% Tab 4: Stiffness vs Temp
tab4 = uitab(tabgp, 'Title', 'Stiffness vs Temp');
axes('Parent', tab4);

% 5a. Find Indices
% Look for Frequency channel (e.g., FREQ_VS1) and Temperature
idx_freq = find(contains(summary_lab, 'FREQ') & contains(summary_lab, 'VS1'), 1);
if isempty(idx_freq), idx_freq = find(contains(summary_lab, 'FREQ'), 1); end
idx_temp = find(strcmp(summary_lab, 'HBB_TSH000CDA'), 1);

if ~isempty(idx_freq) && ~isempty(idx_temp)
    % 5b. Extract and Clean Data
    freq_data = summary_data(:, idx_freq);
    temp_data = summary_data(:, idx_temp);
    valid_mask = ~isnan(freq_data) & ~isnan(temp_data);
    
    % 5c. Plot
    scatter(temp_data(valid_mask), freq_data(valid_mask), 15, 'filled', 'MarkerFaceAlpha', 0.5);
    
    % Fit Trend Line
    p = polyfit(temp_data(valid_mask), freq_data(valid_mask), 1);
    x_fit = linspace(min(temp_data), max(temp_data), 100);
    y_fit = polyval(p, x_fit);
    hold on; plot(x_fit, y_fit, 'r-', 'LineWidth', 2);
    
    title(['Long-Term Stiffness: ' summary_lab{idx_freq} ' vs Temperature']);
    xlabel('Temperature (°C)');
    ylabel('Fundamental Frequency (Hz)');
    legend('Observations', 'Linear Trend', 'Location', 'best');
    grid on;
else
    warning('Could not find Frequency or Temperature channels for Plot 12.');
end