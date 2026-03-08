%% Wind Rose Analysis for Nov 25, 2012
% Visualizes wind speed and direction for the specific storm event using summary data.

clear; clc; close all;

%% 1. Load Summary Data
filename = 'h_summaries20160405_simple.mat';
if exist(filename, 'file')
    load(filename);
elseif exist(fullfile('CW1-data', filename), 'file')
    load(fullfile('CW1-data', filename));
elseif exist(fullfile('..', 'CW1-data', filename), 'file')
    load(fullfile('..', 'CW1-data', filename));
else
    error('Summary file %s not found.', filename);
end

% Clean Data
data(data == -999) = NaN;

%% 2. Filter for Nov 25, 2012
target_date = datenum(2012, 11, 25);
day_mask = floor(t) == target_date;

if ~any(day_mask)
    error('No data found for Nov 25, 2012.');
end

t_event = t(day_mask);
data_event = data(day_mask, :);

%% 3. Extract Wind Data
% Find columns
idx_ws = find(strcmp(lab, 'HBB_WIH000CDS'), 1); % Speed
idx_wd = find(strcmp(lab, 'HBB_WIH000CDD'), 1); % Direction

if isempty(idx_ws) || isempty(idx_wd)
    error('Wind Speed or Direction channels not found in summary data.');
end

ws = data_event(:, idx_ws);
wd = data_event(:, idx_wd);

% Remove NaNs
valid_idx = ~isnan(ws) & ~isnan(wd);
ws = ws(valid_idx);
wd = wd(valid_idx);

fprintf('Max Wind Speed on 25/11/12: %.2f m/s\n', max(ws));

%% 4. Generate Plots
figure('Name', 'Wind Analysis 25/11/12', 'Color', 'w', 'Position', [100, 100, 1000, 500]);

% Subplot 1: Polar Scatter (Speed vs Direction)
subplot(1, 2, 1);
polarscatter(deg2rad(wd), ws, 30, ws, 'filled');
colormap(jet);
c = colorbar;
c.Label.String = 'Wind Speed (m/s)';
title('Wind Speed vs Direction (Scatter)');
rlim([0 max(ws)*1.1]);
thetaticklabels({'N','NE','E','SE','S','SW','W','NW'});

% Subplot 2: Directional Histogram
subplot(1, 2, 2);
polarhistogram(deg2rad(wd), 16, 'FaceColor', 'b', 'FaceAlpha', 0.6);
title('Wind Direction Frequency');
thetaticklabels({'N','NE','E','SE','S','SW','W','NW'});

% Add overall title
sgtitle('Wind Conditions on Nov 25, 2012');