% run_all_stats.m — loads data, runs strPE_inf_LMM, then extract_all_stats
base = '/Users/georgetertikas/Documents/Nadescha_code';
cd(base); addpath(genpath(base));

s = []; pilotID = 7; choice4 = 0;
s = readdat(s, pilotID);
s = setrelev(s);
for is = 1:length(s.subID), s = formatdat(s, is, choice4); end
for is = 1:length(s.subID), s = checkdat(s, is, choice4); end
s = getpmat(s);
s = loadQuest(s, 0);
s = factana(s);
s = anadesc(s, [0 0 0]);
s = addpmat(s);
s = plotrev(s, [0 0 0]);

% Run strPE_inf_LMM to populate lmeMlog, lme_test1, lme_test
try
    run('strPE_inf_LMM.m');
catch ME
    fprintf('strPE_inf_LMM error (expected, models already fitted): %s\n', ME.message);
end

% Print full stats for all figures
run('extract_all_stats.m');
