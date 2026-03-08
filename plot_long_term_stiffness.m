%% Long-Term Stiffness Analysis (Frequency vs Temperature)
% Generates a scatter plot showing the relationship between natural frequency
% and temperature for the Humber Bridge.

clear; clc; close all;

%% 1. Load Data
filename = 'h_summaries20160405_simple.mat';

% Check for file in likely locations
if exist(filename, 'file')
    load(filename);
elseif exist(fullfile('CW1-data', filename), 'file')
    load(fullfile('CW1-data', filename));
elseif exist(fullfile('..', 'CW1-data', filename), 'file')
    load(fullfile('..', 'CW1-data', filename));
else
    error('File %s not found. Please ensure the data file is in the path.', filename);
end

%% 2. Data Cleaning
% Replace -999 with NaN to handle missing data
data(data == -999) = NaN;

%% 3. Extract Variables
% Helper function to find column index safely
get_idx = @(name) find(strcmp(lab, name), 1);

% Target 1: Fundamental Vertical Frequency (FREQ_VS1)
idx_freq = get_idx('FREQ_VS1');
if isempty(idx_freq)
    error('Channel FREQ_VS1 not found in dataset.');
end

% Target 2: Midspan Temperature (TSH000CDT or fallback HBB_TSH000CDA)
idx_temp = get_idx('TSH000CDT');
if isempty(idx_temp)
    fprintf('Primary temperature channel TSH000CDT not found. Trying fallback HBB_TSH000CDA...\n');
    idx_temp = get_idx('HBB_TSH000CDA');
end

if isempty(idx_temp)
    error('No suitable temperature channel found (TSH000CDT or HBB_TSH000CDA).');
end

% Extract vectors
freq = data(:, idx_freq);
temp = data(:, idx_temp);

% Remove NaNs for clean plotting (intersection of valid data)
valid_mask = ~isnan(freq) & ~isnan(temp);
freq_clean = freq(valid_mask);
temp_clean = temp(valid_mask);

fprintf('Data points available after cleaning: %d\n', length(freq_clean));

%% 4. Generate Scatter Plot
figure('Name', 'Long-Term Stiffness', 'Color', 'w', 'Position', [100, 100, 800, 600]);

% Scatter plot with semi-transparent markers
scatter(temp_clean, freq_clean, 15, 'filled', 'MarkerFaceColor', 'b', 'MarkerFaceAlpha', 0.3);

grid on;
xlabel('Midspan Temperature (°C)', 'FontSize', 12);
ylabel('Fundamental Vertical Frequency (Hz)', 'FontSize', 12);
title('Long-Term Stiffness: Frequency vs Temperature', 'FontSize', 14);

