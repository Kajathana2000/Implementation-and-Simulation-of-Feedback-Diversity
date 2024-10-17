% Define the operating frequency (800 MHz)
freq = 800e6;

% Define the speed of light in m/s
c = physconst("lightspeed");

% Calculate the wavelength in meters
lambda = c / freq;

% Define the bandwidth fraction (10%)
BW_frac = 0.1;

% Calculate the minimum and maximum frequencies
fmin = freq - BW_frac * freq;
fmax = freq + BW_frac * freq;

% Create two identical dipole antennas with half-wavelength length and thin width
d1 = dipole('Length', lambda / 2, 'Width', lambda / 200);
d2 = dipole('Length', lambda / 2, 'Width', lambda / 200);

% Set the spacing between the antennas to 5 wavelengths
range = 5 * lambda;

% Create a linear array with the two dipole elements
l = linearArray;
l.Element = [d1 d2];
l.ElementSpacing = range;

% Visualize the array
show(l);
view(-80, 4);

% Define the number of orientation steps
numpos = 101;

% Check if numpos is a positive integer
if numpos <= 0 || rem(numpos, 1) ~= 0
    error('numpos must be a positive integer.');
end

% Define the range of tilt angles from 0 to 90 degrees
orientation = linspace(0, 90, numpos);

% Initialize arrays to store S21 and correlation values
S21_TiltdB = nan(1, numel(orientation));
Corr_TiltdB = nan(1, numel(orientation));

% Set the initial tilt angle
current_tilt = 0;
feedback_step = 1; % Define the feedback step

% Create a figure for feedback iteration analysis
fig1 = figure;

% Loop through each orientation angle
for i = 1:numel(orientation)
    % Set the tilt of the second dipole
    d2.Tilt = current_tilt;
    l.Element(2) = d2;
    
    % Calculate the scattering parameters and correlation
    S = sparameters(l, freq);
    Corr = correlation(l, freq, 1, 2);
    
    % Store the S21 and correlation values in dB
    S21_TiltdB(i) = 20 * log10(abs(S.Parameters(2, 1, 1)));
    Corr_TiltdB(i) = 20 * log10(Corr);
    
    % Adjust tilt based on feedback
    current_tilt = adjust_tilt_based_on_feedback(current_tilt, S21_TiltdB(i), feedback_step);
    
    % Plot the results
    figure(fig1);
    plot(orientation, S21_TiltdB, orientation, Corr_TiltdB, 'LineWidth', 2);
    grid on;
    axis([min(orientation) max(orientation) -65 -20]);
    xlabel('Tilt Variation on 2nd Dipole (deg.)');
    ylabel('Magnitude (dB)');
    title('Correlation, S_{21} Variation with Polarization');
    drawnow;
end

% Add a legend to the plot
legend('S_{21}', 'Correlation');

% Define the number of spacing steps and the range of distances
Nrange = 201;
Rmin = 0.001 * lambda;
Rmax = 2.5 * lambda;
range = linspace(Rmin, Rmax, Nrange);

% Initialize arrays to store S21 and correlation values
S21_RangedB = nan(1, Nrange);
Corr_RangedB = nan(1, Nrange);

% Create a figure for range analysis
fig2 = figure;

% Loop through each spacing distance
for i = 1:Nrange
    % Set the spacing between the elements
    l.ElementSpacing = range(i);
    
    % Calculate the scattering parameters and correlation
    S = sparameters(l, freq);
    Corr = correlation(l, freq, 1, 2);
    
    % Store the S21 and correlation values in dB
    S21_RangedB(i) = 20 * log10(abs(S.Parameters(2, 1, 1)));
    Corr_RangedB(i) = 20 * log10(Corr);
    
    % Plot the results
    figure(fig2);
    plot(range ./ lambda, S21_RangedB, range ./ lambda, Corr_RangedB, '--', 'LineWidth', 2);
    grid on;
    axis([min(range ./ lambda) max(range ./ lambda) -50 0]);
    xlabel('Distance of Separation, d/\lambda');
    ylabel('Magnitude (dB)');
    title('Correlation, S_{21} Variation with Range');
    drawnow;
end

% Add a legend to the plot
legend('S_{21}', 'Correlation');

% Pick a specific separation distance (e.g., 1.25 wavelengths)
Rpick = 1.25 * lambda;

% Define the frequency range for analysis
Numfreq = 101;
f = linspace(fmin, fmax, Numfreq);
l.ElementSpacing = Rpick;

% Calculate the correlation values over the frequency range
Corr_PickdB = nan(1, Numfreq);
for i = 1:Numfreq
    S = sparameters(l, f(i));
    Corr_PickdB(i) = 20 * log10(correlation(l, f(i), 1, 2));
end

% Plot the correlation variation with frequency
fig3 = figure;
plot(f ./ 1e9, Corr_PickdB, 'LineWidth', 2);
grid on;
axis([min(f ./ 1e9) max(f ./ 1e9) -65 0]);
xlabel('Frequency (GHz)');
ylabel('Magnitude (dB)');
title('Correlation Variation with Frequency');

% Additional analyses

% Feedback Iteration Analysis
Tilt_Angles = nan(1, numel(orientation));
current_tilt = 0;
fig4 = figure;
for i = 1:numel(orientation)
    d2.Tilt = current_tilt;
    l.Element(2) = d2;
    
    S = sparameters(l, freq);
    Corr = correlation(l, freq, 1, 2);
    
    Tilt_Angles(i) = current_tilt;
    current_tilt = adjust_tilt_based_on_feedback(current_tilt, S21_TiltdB(i), feedback_step); % Default feedback step
    
    plot(orientation, Tilt_Angles, 'LineWidth', 2);
    grid on;
    xlabel('Orientation Angle (deg.)');
    ylabel('Tilt Angle (deg.)');
    title('Tilt Angle Adjustment Over Feedback Iterations');
    drawnow;
end

% Feedback Sensitivity Analysis
feedback_steps = [0.5, 1, 2];
fig5 = figure;
for j = 1:numel(feedback_steps)
    S21_FeedbackdB = nan(1, numel(orientation));
    Corr_FeedbackdB = nan(1, numel(orientation));
    current_tilt = 0;
    
    for i = 1:numel(orientation)
        d2.Tilt = current_tilt;
        l.Element(2) = d2;
        
        S = sparameters(l, freq);
        Corr = correlation(l, freq, 1, 2);
        
        S21_FeedbackdB(i) = 20 * log10(abs(S.Parameters(2, 1, 1)));
        Corr_FeedbackdB(i) = 20 * log10(Corr);
        
        current_tilt = adjust_tilt_based_on_feedback(current_tilt, S21_FeedbackdB(i), feedback_steps(j));
    end
    
    plot(orientation, S21_FeedbackdB, 'LineWidth', 2);
    hold on;
    plot(orientation, Corr_FeedbackdB, '--', 'LineWidth', 2);
end
grid on;
xlabel('Tilt Variation on 2nd Dipole (deg.)');
ylabel('Magnitude (dB)');
title('S_{21} and Correlation with Different Feedback Adjustment Steps');
legend(arrayfun(@(x) sprintf('Feedback Step = %.1f', x), feedback_steps, 'UniformOutput', false));

% Comparison of Feedback Strategies
feedback_strategies = {@strategy1, @strategy2}; % Define different strategies
fig6 = figure;
for k = 1:numel(feedback_strategies)
    S21_Strategy = nan(1, numel(orientation));
    Corr_Strategy = nan(1, numel(orientation));
    current_tilt = 0;
    
    for i = 1:numel(orientation)
        d2.Tilt = current_tilt;
        l.Element(2) = d2;
        
        S = sparameters(l, freq);
        Corr = correlation(l, freq, 1, 2);
        
        S21_Strategy(i) = 20 * log10(abs(S.Parameters(2, 1, 1)));
        Corr_Strategy(i) = 20 * log10(Corr);
        
        current_tilt = feedback_strategies{k}(current_tilt, S21_Strategy(i));
    end
    
    plot(orientation, S21_Strategy, 'LineWidth', 2);
    hold on;
    plot(orientation, Corr_Strategy, '--', 'LineWidth', 2);
end
grid on;
xlabel('Tilt Variation on 2nd Dipole (deg.)');
ylabel('Magnitude (dB)');
title('Performance Metrics for Different Feedback Strategies');
legend(arrayfun(@(x) sprintf('Strategy %d', x), 1:numel(feedback_strategies), 'UniformOutput', false));

% Correlation vs. Range for Various Tilt Angles
tilt_angles = [0, 10, 20, 30];
fig7 = figure;
for m = 1:numel(tilt_angles)
    d2.Tilt = tilt_angles(m);
    l.Element(2) = d2;
    
    Corr_Range = nan(1, Nrange);
    
    for i = 1:Nrange
        l.ElementSpacing = range(i);
        Corr = correlation(l, freq, 1, 2);
        Corr_Range(i) = 20 * log10(Corr);
    end
    
    plot(range ./ lambda, Corr_Range, 'LineWidth', 2);
    hold on;
end
grid on;
xlabel('Distance of Separation, d/\lambda');
ylabel('Correlation (dB)');
title('Correlation Variation with Separation Distance for Various Tilt Angles');
legend(arrayfun(@(x) sprintf('Tilt Angle = %d', x), tilt_angles, 'UniformOutput', false));

% Function Definitions
function tilt = adjust_tilt_based_on_feedback(current_tilt, S21, feedback_step)
    % Simple feedback adjustment example (you can replace this with your own logic)
    % If the S21 value indicates poor signal strength, increase the tilt angle
    if S21 < -30
        tilt = current_tilt + feedback_step; % Increase tilt angle
    else
        tilt = current_tilt; % Maintain current tilt angle
    end
end

function tilt = strategy1(current_tilt, S21)
    % Strategy 1: Increase tilt if S21 is below -30 dB
    if S21 < -30
        tilt = current_tilt + 1; % Increase tilt by 1 degree
    else
        tilt = current_tilt;
    end
end

function tilt = strategy2(current_tilt, S21)
    % Strategy 2: Decrease tilt if S21 is above -20 dB
    if S21 > -20
        tilt = current_tilt - 1; % Decrease tilt by 1 degree
    else
        tilt = current_tilt;
    end
end
