% Multirate Signal Processing System: Polyphase Filtering & Fixed-Point Conversion
clear; clc; close all;

%% 1. Generate Test Signal & Fixed-Point Input Conversion
Fs = 1000; % Arbitrary sampling frequency
t = 0:1/Fs:1-1/Fs; % 1 second of data

% Create a composite signal with frequencies residing in all 3 target bands:
% Band 1: 0 to 0.2*pi 
% Band 2: 0.2*pi to 0.5*pi 
% Band 3: 0.5*pi to 0.9*pi 
f1 = 0.1 * (Fs/2);
f2 = 0.35 * (Fs/2);
f3 = 0.7 * (Fs/2);

x_real = 0.3*sin(2*pi*f1*t) + 0.3*sin(2*pi*f2*t) + 0.3*sin(2*pi*f3*t);

% Convert input to Fixed-Point: 8-bit real with 6 fractional bits (Signed)
% Syntax: fi(data, signed_boolean, word_length, fraction_length)
x_fi = fi(x_real, 1, 8, 6);
x_double = double(x_fi); % Compute in double for the intermediate DSP steps

%% 2. Filter Design (Length > 20, Polyphase Depth = 3)
% We choose N = 29 (Length 30) because it is > 20 and perfectly divisible 
% by our polyphase depth of 3.
N = 23; 

% Design the FIR filters
h_lpf  = fir1(N, 0.2, 'low');               % LPF: [0, 0.2*pi]
h_bpf1 = fir1(N, [0.2 0.5], 'bandpass');    % BPF1: [0.2*pi, 0.5*pi]
h_bpf2 = fir1(N, [0.5 0.9], 'bandpass');    % BPF2: [0.5*pi, 0.9*pi]

%% 3. Polyphase Filter Implementation (Depth 3)
% To downsample by 3 efficiently, we decompose the filters into 3 phases.
% Phase 0: h(1), h(4), h(7)...
% Phase 1: h(2), h(5), h(8)...
% Phase 2: h(3), h(6), h(9)...

% Extract Polyphase Components for LPF
E0_lpf = h_lpf(1:3:end); E1_lpf = h_lpf(2:3:end); E2_lpf = h_lpf(3:3:end);

% Extract Polyphase Components for BPF1
E0_bpf1 = h_bpf1(1:3:end); E1_bpf1 = h_bpf1(2:3:end); E2_bpf1 = h_bpf1(3:3:end);

% Extract Polyphase Components for BPF2
E0_bpf2 = h_bpf2(1:3:end); E1_bpf2 = h_bpf2(2:3:end); E2_bpf2 = h_bpf2(3:3:end);

% Prepare delayed inputs for the commutator/polyphase branches
x_delayed_0 = x_double;
x_delayed_1 = [0, x_double(1:end-1)];
x_delayed_2 = [0, 0, x_double(1:end-2)];

% Down-sample the inputs by 3 (saving memory/computation)
x_ds_0 = x_delayed_0(1:3:end);
x_ds_1 = x_delayed_1(1:3:end);
x_ds_2 = x_delayed_2(1:3:end);

% Filter and sum the branches for each respective band
y_lpf_raw = filter(E0_lpf, 1, x_ds_0) + filter(E1_lpf, 1, x_ds_1) + filter(E2_lpf, 1, x_ds_2);
y_bpf1_raw = filter(E0_bpf1, 1, x_ds_0) + filter(E1_bpf1, 1, x_ds_1) + filter(E2_bpf1, 1, x_ds_2);
y_bpf2_raw = filter(E0_bpf2, 1, x_ds_0) + filter(E1_bpf2, 1, x_ds_1) + filter(E2_bpf2, 1, x_ds_2);

%% 4. Amplitude Enhancement (dB Adjustments)
% LPF enhanced by +1 dB, BPFs enhanced by -1 dB
gain_lpf  = 10^(1/20);  
gain_bpf1 = 10^(-1/20); 
gain_bpf2 = 10^(-1/20); 

y_lpf  = y_lpf_raw  * gain_lpf;
y_bpf1 = y_bpf1_raw * gain_bpf1;
y_bpf2 = y_bpf2_raw * gain_bpf2;

%% 5. Combine Data & Final Fixed-Point Conversion
% Combine the down-sampled, filtered, and scaled signals
y_combined = y_lpf + y_bpf1 + y_bpf2;

% Convert Output to Fixed-Point: 10-bit real with 8 fractional bits (Signed)
y_fi = fi(y_combined, 1, 10, 8);

%% 6. Prepare Data for SIMULINK Verification
% Format input data so SIMULINK can ingest it via the "From Workspace" block
sim_time = (0:(length(x_double)-1))';
sim_input = timeseries(x_double', sim_time);

% Save coefficients for Simulink FIR blocks
assignin('base', 'sim_input', sim_input);
assignin('base', 'h_lpf', h_lpf);
assignin('base', 'h_bpf1', h_bpf1);
assignin('base', 'h_bpf2', h_bpf2);

disp('DSP processing complete. Filtered output generated.');
disp(['Input Fixed-Point Type: ', x_fi.DataType]);
disp(['Output Fixed-Point Type: ', y_fi.DataType]);
disp('Data (sim_input) is now ready in the workspace for SIMULINK import.');
