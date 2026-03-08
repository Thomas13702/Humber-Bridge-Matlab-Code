%% Event Check: Nov 25 2012 - Lateral Shift
% This script isolates data for Nov 25, 2012 to inspect a potential
% lateral shift event using summary data.

clear; clc; close all;

%% 1. Load the Summary Data
filename = 'h_summaries20160405_simple.mat';
if exist(filename, 'file')
    load(filename);
elseif exist(fullfile('CW1-data', filename), 'file')
    load(fullfile('CW1-data', filename));
elseif exist(fullfile('..', 'CW1-data', filename), 'file')
    load(fullfile('..', 'CW1-data', filename));
else
    error('File %s not found in current directory, CW1-data subdirectory, or ../CW1-data.', filename);
end

%% 2. Clean Data
% Replace -999 with NaN to avoid plotting artifacts
data(data == -999) = NaN;

%% 3. Filter for Target Date (Nov 25, 2012)
target_date = datenum(2012, 11, 25);
% Find indices where the integer part of time matches the target date
% floor(t) gives the date without the time component
day_indices = floor(t) == target_date;

if ~any(day_indices)
    warning('No data found for Nov 25, 2012.');
    return;
end

t_event = t(day_indices);
data_event = data(day_indices, :);

%% 4. Identify Channels
% Helper function to find column index safely
get_idx = @(name) find(strcmp(lab, name), 1);

% Wind Speed: HBB_WIH000CDS (fallback to NOAA_WIS if needed)
idx_ws = get_idx('HBB_WIH000CDS');
if isempty(idx_ws), idx_ws = get_idx('NOAA_WIS'); end

% Wind Direction: HBB_WIH000CDD
idx_wd = get_idx('HBB_WIH000CDD');

% Lateral Displacement (GPS): GPH000EDE or GPH000WDE
% (Lateral direction for Humber Bridge is East-West)
idx_lat_e1 = get_idx('GPH000EDE'); % East Deck East
idx_lat_e2 = get_idx('GPH000WDE'); % West Deck East

% Lateral Acceleration: RMS_H
idx_acc_lat = get_idx('RMS_H');

%% 5. Generate Plots
figure('Name', 'Event Check: Nov 25 2012 - Lateral Shift', 'NumberTitle', 'off', 'Color', 'w');

% Define common time limits for alignment
t_lims = [min(t_event), max(t_event)];

% Subplot 1: Wind Speed
subplot(4, 1, 1);
if ~isempty(idx_ws), plot(t_event, data_event(:, idx_ws), 'b'); end
ylabel('Speed (m/s)'); title('Wind Speed'); grid on;
xlim(t_lims); datetick('x', 'HH:MM', 'keeplimits');

% Subplot 2: Wind Direction
subplot(4, 1, 2);
if ~isempty(idx_wd), plot(t_event, data_event(:, idx_wd), 'r.', 'MarkerSize', 8); end
ylabel('Deg'); title('Wind Direction'); grid on;
ylim([0 360]); yticks(0:90:360);
xlim(t_lims); datetick('x', 'HH:MM', 'keeplimits');

% Subplot 3: Lateral Displacement (GPS)
subplot(4, 1, 3); hold on;
if ~isempty(idx_lat_e1), plot(t_event, data_event(:, idx_lat_e1), 'k', 'DisplayName', 'East Deck (E)'); end
if ~isempty(idx_lat_e2), plot(t_event, data_event(:, idx_lat_e2), 'm', 'DisplayName', 'West Deck (E)'); end
ylabel('Disp (m)'); title('Lateral Displacement (GPS East)'); grid on;
if ~isempty(idx_lat_e1) || ~isempty(idx_lat_e2), legend('show', 'Location', 'best'); end
xlim(t_lims); datetick('x', 'HH:MM', 'keeplimits');

% Subplot 4: Lateral Acceleration
subplot(4, 1, 4);
if ~isempty(idx_acc_lat), plot(t_event, data_event(:, idx_acc_lat), 'g'); end
ylabel('RMS (g)'); title('Lateral Acceleration (RMS_H)'); grid on;
xlim(t_lims); datetick('x', 'HH:MM', 'keeplimits');

xlabel('Time (UTC)');

% Link axes for zooming
linkaxes(findall(gcf, 'type', 'axes'), 'x');