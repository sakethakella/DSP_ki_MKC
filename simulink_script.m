% Automated Generation of an Explicit Polyphase Decimator Structure
clear modelName;
modelName = 'Explicit_Polyphase_Model';

% 1. Create and open a new blank Simulink model
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
new_system(modelName);
open_system(modelName);

% 2. Setup block dimensions
w = 60; h = 40; 

% 3. Add Input & Initial Data Type Conversion (8-bit, 6 fractional)
add_block('simulink/Sources/From Workspace', [modelName, '/Input'], ...
    'Position', [20, 200, 80, 230], 'VariableName', 'sim_input');
add_block('simulink/Signal Attributes/Data Type Conversion', [modelName, '/DTC_In'], ...
    'Position', [120, 195, 180, 235], 'OutDataTypeStr', 'fixdt(1,8,6)');

% 4. Build the Delay Chain (z^-1)
add_block('simulink/Discrete/Delay', [modelName, '/Delay1'], ...
    'Position', [220, 295, 260, 335], 'DelayLength', '1');
add_block('simulink/Discrete/Delay', [modelName, '/Delay2'], ...
    'Position', [220, 395, 260, 435], 'DelayLength', '1');

% 5. Add Downsample Blocks (Factor of 3) for each branch
add_block('dspsigops/Downsample', [modelName, '/DS0'], 'Position', [320, 195, 360, 235], 'N', '3');
add_block('dspsigops/Downsample', [modelName, '/DS1'], 'Position', [320, 295, 360, 335], 'N', '3');
add_block('dspsigops/Downsample', [modelName, '/DS2'], 'Position', [320, 395, 360, 435], 'N', '3');

% 6. Add the Polyphase Filter Branches
% E0 branch (No delay)
add_block('simulink/Discrete/Discrete FIR Filter', [modelName, '/Filter_E0'], ...
    'Position', [420, 195, 500, 235], 'Coefficients', 'E0_lpf');
% E1 branch (1 delay)
add_block('simulink/Discrete/Discrete FIR Filter', [modelName, '/Filter_E1'], ...
    'Position', [420, 295, 500, 335], 'Coefficients', 'E1_lpf');
% E2 branch (2 delays)
add_block('simulink/Discrete/Discrete FIR Filter', [modelName, '/Filter_E2'], ...
    'Position', [420, 395, 500, 435], 'Coefficients', 'E2_lpf');

% 7. Add the Summation Block (3 inputs: +++)
add_block('simulink/Math Operations/Add', [modelName, '/Sum_Polyphase'], ...
    'Position', [580, 280, 610, 350], 'Inputs', '+++');

% 8. Add Gain (+1 dB for LPF) and Final Data Type Conversion (10-bit, 8 fractional)
add_block('simulink/Math Operations/Gain', [modelName, '/Gain (1dB)'], ...
    'Position', [660, 295, 720, 335], 'Gain', '10^(1/20)');
add_block('simulink/Signal Attributes/Data Type Conversion', [modelName, '/DTC_Out'], ...
    'Position', [770, 295, 830, 335], 'OutDataTypeStr', 'fixdt(1,10,8)');
add_block('simulink/Sinks/To Workspace', [modelName, '/Output_RAM'], ...
    'Position', [880, 295, 950, 335], 'VariableName', 'sim_output', 'SaveFormat', 'Timeseries');

% 9. Wire the blocks together
add_line(modelName, 'Input/1', 'DTC_In/1', 'autorouting','on');

% Delay Chain Wiring
add_line(modelName, 'DTC_In/1', 'Delay1/1', 'autorouting','on');
add_line(modelName, 'Delay1/1', 'Delay2/1', 'autorouting','on');

% Branch 0 (Top)
add_line(modelName, 'DTC_In/1', 'DS0/1', 'autorouting','on');
add_line(modelName, 'DS0/1', 'Filter_E0/1', 'autorouting','on');
add_line(modelName, 'Filter_E0/1', 'Sum_Polyphase/1', 'autorouting','on');

% Branch 1 (Middle)
add_line(modelName, 'Delay1/1', 'DS1/1', 'autorouting','on');
add_line(modelName, 'DS1/1', 'Filter_E1/1', 'autorouting','on');
add_line(modelName, 'Filter_E1/1', 'Sum_Polyphase/2', 'autorouting','on');

% Branch 2 (Bottom)
add_line(modelName, 'Delay2/1', 'DS2/1', 'autorouting','on');
add_line(modelName, 'DS2/1', 'Filter_E2/1', 'autorouting','on');
add_line(modelName, 'Filter_E2/1', 'Sum_Polyphase/3', 'autorouting','on');

% Final Output Wiring
add_line(modelName, 'Sum_Polyphase/1', 'Gain (1dB)/1', 'autorouting','on');
add_line(modelName, 'Gain (1dB)/1', 'DTC_Out/1', 'autorouting','on');
add_line(modelName, 'DTC_Out/1', 'Output_RAM/1', 'autorouting','on');

disp('Explicit polyphase model generated!');