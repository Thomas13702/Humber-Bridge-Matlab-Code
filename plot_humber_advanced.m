%% Advanced Structural Behaviour Plots
% This script visualizes aerodynamic stability, GPS filtering, and buffeting
% correlations for the Humber Bridge using data from Nov 25, 2012.

clear; clc; close all;

%% 1. Load Data
filename = 'humberdefs_20121125_dsa.mat';

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

%% 2. Extract Data Variables
% Handle different variable names (D.data, tdata, or accs)
if exist('D', 'var') && isfield(D, 'data')
    data = D.data;
elseif exist('tdata', 'var')
    data = tdata;
    % Ensure data is (samples x channels)
    if size(data, 1) < size(data, 2) && size(data, 1) <= 20
        data = data';
    end
elseif exist('accs', 'var')
    data = accs;
else
    error('Variable D.data, tdata, or accs not found in workspace.');
end

%% 3. Extract Specific Channels
% Mapping based on user request:
% Col 2: GPS Height Raw
% Col 5: GPS Height LPF
% Col 6: Deck Rotation
% Col 10: Wind Speed
% Col 11: Lateral Acceleration

if size(data, 2) < 11
    error('Data matrix has fewer than 11 columns. Cannot extract required channels.');
end

gps_height_raw = data(:, 2);
gps_height_lpf = data(:, 5);
deck_rotation  = data(:, 6);
wind_speed     = data(:, 10);
lat_accel      = data(:, 11);

%% 4. Create Time Vector
% Data is 1Hz for 1 day
N = size(data, 1);
Fs = 1; 
t_hours = (0:N-1)' / 3600; % Time in hours (0 to ~24)

%% 5. Generate Plots
figure('Name', 'Advanced Structural Behaviour', 'Color', 'w', 'Position', [100, 100, 1000, 800]);

% Subplot 1: Aerodynamic Stability (Wind vs Deck Torsion)
subplot(2, 2, 1);
yyaxis left
plot(t_hours, wind_speed, 'b', 'LineWidth', 1);
ylabel('Wind Speed (m/s)');
ylim([0 max(wind_speed)*1.1]);

yyaxis right
plot(t_hours, deck_rotation, 'r', 'LineWidth', 1);
ylabel('Deck Rotation (mm)');

title('Aerodynamic Stability: Wind vs. Deck Torsion');
xlabel('Time (Hours)');
grid on;
axis tight;

% Subplot 2: Filtering (Raw vs LPF Height)
subplot(2, 2, 2);
plot(t_hours, gps_height_raw, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold on;
plot(t_hours, gps_height_lpf, 'k', 'LineWidth', 1.5); % Thick black for LPF
title('Filtering: High-Freq Buffeting vs. Quasi-Static');
ylabel('GPS Height (mm)');
xlabel('Time (Hours)');
legend('Raw GPS', 'LPF GPS', 'Location', 'best');
grid on;
axis tight;

% Subplot 3: Buffeting Correlation (Wind vs Lat Accel)
% Spanning the bottom row for better visibility
subplot(2, 2, [3 4]);
scatter(wind_speed, lat_accel, 10, 'filled', 'MarkerFaceAlpha', 0.4);
title('Wind vs Lateral Acceleration Correlation');
xlabel('Wind Speed (m/s)');
ylabel('Transverse Acceleration (m/s^2)');
grid on;