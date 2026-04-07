% Automated Generation of the Complete 3-Filter Polyphase System
clear modelName;
modelName = 'Full_Polyphase_System';

% 1. Create and open a new blank Simulink model
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
new_system(modelName);
open_system(modelName);

%% --- BLOCK PLACEMENT ---

% Input & Initial 8-bit Data Type Conversion
add_block('simulink/Sources/From Workspace', [modelName, '/Input'], ...
    'Position', [20, 300, 80, 340], 'VariableName', 'sim_input');
add_block('simulink/Signal Attributes/Data Type Conversion', [modelName, '/DTC_In'], ...
    'Position', [120, 300, 180, 340], 'OutDataTypeStr', 'fixdt(1,8,6)');

% Shared Delay Chain (z^-1)
add_block('simulink/Discrete/Delay', [modelName, '/Delay1'], ...
    'Position', [220, 400, 260, 440], 'DelayLength', '1');
add_block('simulink/Discrete/Delay', [modelName, '/Delay2'], ...
    'Position', [220, 500, 260, 540], 'DelayLength', '1');

% Shared Downsamplers (Factor of 3)
add_block('dspsigops/Downsample', [modelName, '/DS0'], 'Position', [320, 300, 360, 340], 'N', '3');
add_block('dspsigops/Downsample', [modelName, '/DS1'], 'Position', [320, 400, 360, 440], 'N', '3');
add_block('dspsigops/Downsample', [modelName, '/DS2'], 'Position', [320, 500, 360, 540], 'N', '3');

% --- LPF BANK (Top Row) ---
add_block('simulink/Discrete/Discrete FIR Filter', [modelName, '/LPF_E0'], 'Position', [450, 100, 530, 140], 'Coefficients', 'E0_lpf');
add_block('simulink/Discrete/Discrete FIR Filter', [modelName, '/LPF_E1'], 'Position', [450, 150, 530, 190], 'Coefficients', 'E1_lpf');
add_block('simulink/Discrete/Discrete FIR Filter', [modelName, '/LPF_E2'], 'Position', [450, 200, 530, 240], 'Coefficients', 'E2_lpf');
add_block('simulink/Math Operations/Add', [modelName, '/Sum_LPF'], 'Position', [580, 150, 610, 200], 'Inputs', '+++');
add_block('simulink/Math Operations/Gain', [modelName, '/Gain_LPF'], 'Position', [650, 155, 710, 195], 'Gain', '10^(1/20)'); % +1 dB

% --- BPF1 BANK (Middle Row) ---
add_block('simulink/Discrete/Discrete FIR Filter', [modelName, '/BPF1_E0'], 'Position', [450, 300, 530, 340], 'Coefficients', 'E0_bpf1');
add_block('simulink/Discrete/Discrete FIR Filter', [modelName, '/BPF1_E1'], 'Position', [450, 350, 530, 390], 'Coefficients', 'E1_bpf1');
add_block('simulink/Discrete/Discrete FIR Filter', [modelName, '/BPF1_E2'], 'Position', [450, 400, 530, 440], 'Coefficients', 'E2_bpf1');
add_block('simulink/Math Operations/Add', [modelName, '/Sum_BPF1'], 'Position', [580, 350, 610, 400], 'Inputs', '+++');
add_block('simulink/Math Operations/Gain', [modelName, '/Gain_BPF1'], 'Position', [650, 355, 710, 395], 'Gain', '10^(-1/20)'); % -1 dB

% --- BPF2 BANK (Bottom Row) ---
add_block('simulink/Discrete/Discrete FIR Filter', [modelName, '/BPF2_E0'], 'Position', [450, 500, 530, 540], 'Coefficients', 'E0_bpf2');
add_block('simulink/Discrete/Discrete FIR Filter', [modelName, '/BPF2_E1'], 'Position', [450, 550, 530, 590], 'Coefficients', 'E1_bpf2');
add_block('simulink/Discrete/Discrete FIR Filter', [modelName, '/BPF2_E2'], 'Position', [450, 600, 530, 640], 'Coefficients', 'E2_bpf2');
add_block('simulink/Math Operations/Add', [modelName, '/Sum_BPF2'], 'Position', [580, 550, 610, 600], 'Inputs', '+++');
add_block('simulink/Math Operations/Gain', [modelName, '/Gain_BPF2'], 'Position', [650, 555, 710, 595], 'Gain', '10^(-1/20)'); % -1 dB

% --- FINAL COMBINER & RAM OUTPUT ---
add_block('simulink/Math Operations/Add', [modelName, '/Final_Combine'], 'Position', [780, 350, 810, 400], 'Inputs', '+++');
add_block('simulink/Signal Attributes/Data Type Conversion', [modelName, '/DTC_Out'], ...
    'Position', [860, 355, 920, 395], 'OutDataTypeStr', 'fixdt(1,10,8)'); % 10-bit output
add_block('simulink/Sinks/To Workspace', [modelName, '/Output_RAM'], ...
    'Position', [960, 355, 1040, 395], 'VariableName', 'sim_output', 'SaveFormat', 'Timeseries');

%% --- SIGNAL WIRING ---

% Input to Splitter
add_line(modelName, 'Input/1', 'DTC_In/1', 'autorouting','on');
add_line(modelName, 'DTC_In/1', 'Delay1/1', 'autorouting','on');
add_line(modelName, 'Delay1/1', 'Delay2/1', 'autorouting','on');

% Connect Delays to Shared Downsamplers
add_line(modelName, 'DTC_In/1', 'DS0/1', 'autorouting','on');
add_line(modelName, 'Delay1/1', 'DS1/1', 'autorouting','on');
add_line(modelName, 'Delay2/1', 'DS2/1', 'autorouting','on');

% Route DS0 to all E0 filters
add_line(modelName, 'DS0/1', 'LPF_E0/1', 'autorouting','on');
add_line(modelName, 'DS0/1', 'BPF1_E0/1', 'autorouting','on');
add_line(modelName, 'DS0/1', 'BPF2_E0/1', 'autorouting','on');

% Route DS1 to all E1 filters
add_line(modelName, 'DS1/1', 'LPF_E1/1', 'autorouting','on');
add_line(modelName, 'DS1/1', 'BPF1_E1/1', 'autorouting','on');
add_line(modelName, 'DS1/1', 'BPF2_E1/1', 'autorouting','on');

% Route DS2 to all E2 filters
add_line(modelName, 'DS2/1', 'LPF_E2/1', 'autorouting','on');
add_line(modelName, 'DS2/1', 'BPF1_E2/1', 'autorouting','on');
add_line(modelName, 'DS2/1', 'BPF2_E2/1', 'autorouting','on');

% Sum and Gain LPF
add_line(modelName, 'LPF_E0/1', 'Sum_LPF/1', 'autorouting','on');
add_line(modelName, 'LPF_E1/1', 'Sum_LPF/2', 'autorouting','on');
add_line(modelName, 'LPF_E2/1', 'Sum_LPF/3', 'autorouting','on');
add_line(modelName, 'Sum_LPF/1', 'Gain_LPF/1', 'autorouting','on');

% Sum and Gain BPF1
add_line(modelName, 'BPF1_E0/1', 'Sum_BPF1/1', 'autorouting','on');
add_line(modelName, 'BPF1_E1/1', 'Sum_BPF1/2', 'autorouting','on');
add_line(modelName, 'BPF1_E2/1', 'Sum_BPF1/3', 'autorouting','on');
add_line(modelName, 'Sum_BPF1/1', 'Gain_BPF1/1', 'autorouting','on');

% Sum and Gain BPF2
add_line(modelName, 'BPF2_E0/1', 'Sum_BPF2/1', 'autorouting','on');
add_line(modelName, 'BPF2_E1/1', 'Sum_BPF2/2', 'autorouting','on');
add_line(modelName, 'BPF2_E2/1', 'Sum_BPF2/3', 'autorouting','on');
add_line(modelName, 'Sum_BPF2/1', 'Gain_BPF2/1', 'autorouting','on');

% Final Combiner & Output
add_line(modelName, 'Gain_LPF/1', 'Final_Combine/1', 'autorouting','on');
add_line(modelName, 'Gain_BPF1/1', 'Final_Combine/2', 'autorouting','on');
add_line(modelName, 'Gain_BPF2/1', 'Final_Combine/3', 'autorouting','on');
add_line(modelName, 'Final_Combine/1', 'DTC_Out/1', 'autorouting','on');
add_line(modelName, 'DTC_Out/1', 'Output_RAM/1', 'autorouting','on');

disp('Complete 3-Filter Polyphase Simulink Model Generated Successfully!');