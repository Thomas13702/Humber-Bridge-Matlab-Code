%% Humber Bridge SHM Data Visualization
% This script loads summary data, cleans it, and plots key parameters
% to identify interesting events.

clear; clc; close all;

%% 1. Load the Data
filename = 'h_summaries20160405_simple.mat';
if exist(filename, 'file')
    load(filename);
elseif exist(fullfile('CW1-data', filename), 'file')
    load(fullfile('CW1-data', filename));
else
    error('File %s not found in current directory or CW1-data subdirectory.', filename);
end

%% 2. Clean the Data
% Replace -999 with NaN so plots don't get distorted
data(data == -999) = NaN;

%% 3. Find Indices for Key Channels
% Define the channel names we are interested in
target_channels = {
    'Wind Speed', 'HBB_WIH000CDS';
    'Temperature', 'HBB_TSH000CDA';
    'Expansion', 'EXH077ED';
    'RMS Accel', 'RMS_VE'
};

indices = zeros(size(target_channels, 1), 1);

% Find column indices in 'lab'
for i = 1:size(target_channels, 1)
    channel_name = target_channels{i, 2};
    % Use strcmp to find exact match in the cell array of strings
    idx = find(strcmp(lab, channel_name));
    
    if isempty(idx)
        warning('Channel %s not found in dataset.', channel_name);
    else
        indices(i) = idx(1); 
    end
end

%% 4. Generate Plots
figure('Name', 'Humber Bridge SHM Summary', 'NumberTitle', 'off', 'Color', 'w');

% Loop to create subplots
plot_colors = {'b', 'r', 'k', 'm'};
y_labels = {'Wind Speed (m/s)', 'Temp (C)', 'Disp (mm)', 'RMS Accel (g)'};

for i = 1:4
    subplot(4, 1, i);
    idx = indices(i);
    if idx > 0
        plot(t, data(:, idx), plot_colors{i});
        ylabel(y_labels{i});
        title([target_channels{i, 1} ' (' target_channels{i, 2} ')'], 'Interpreter', 'none');
        grid on;
        datetick('x', 'yyyy-mm-dd', 'keeplimits');
    end
end

xlabel('Date');

% Link axes for zooming
linkaxes(findall(gcf, 'type', 'axes'), 'x');