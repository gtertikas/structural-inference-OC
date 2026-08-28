%% run_figures_batch.m
% Batch launcher: rebuilds workspace from raw data, then generates all figures.
% Run with: /Applications/MATLAB_R2023b.app/bin/matlab -batch "run('run_figures_batch.m')"

clc;
base = '/Users/georgetertikas/Documents/Nadescha_code';
cd(base);
addpath(genpath(base));

fprintf('=== Step 1: Load raw data (readdat) ===\n');
s = [];
pilotID = 7;
choice4 = 0;
s = readdat(s, pilotID);
fprintf('  readdat done: N=%d subjects\n', length(s.subID));

fprintf('=== Step 2: setrelev / formatdat / checkdat ===\n');
s = setrelev(s);
for is = 1:length(s.subID)
    s = formatdat(s, is, choice4);
end
for is = 1:length(s.subID)
    s = checkdat(s, is, choice4);
end
fprintf('  formatdat/checkdat done\n');

fprintf('=== Step 3: getpmat ===\n');
s = getpmat(s);

fprintf('=== Step 4: loadQuest ===\n');
s = loadQuest(s, 0);

fprintf('=== Step 5: factana ===\n');
s = factana(s);
fprintf('  factana done: fa_sub exists=%d\n', isfield(s,'fa_sub'));

fprintf('=== Step 6: anadesc + addpmat ===\n');
s = anadesc(s, [0 0 0]);
s = addpmat(s);

fprintf('=== Step 7: strPE_inf_LMM (for Fig6e/f) ===\n');
try
    run('strPE_inf_LMM.m');
    fprintf('  strPE_inf_LMM done\n');
catch ME
    fprintf('  strPE_inf_LMM skipped: %s\n', ME.message);
end

fprintf('=== Step 8: generate_all_figures ===\n');
run('generate_all_figures.m');
fprintf('=== DONE ===\n');
