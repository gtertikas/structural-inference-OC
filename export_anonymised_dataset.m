%% export_anonymised_dataset.m
% Builds a de-identified, shareable dataset for public data repository upload
% (OSF). Subject identifiers are replaced with a sequential integer
% (1..N, assigned in the order subjects were loaded) — the Prolific ID
% string (s.subID) that qualtrics-matching depends on internally is NEVER
% written to any output file.
%
% Outputs (written to outdir):
%   trial_data.csv     — long format, one row per subject x trial (main phase)
%   subject_summary.csv — one row per subject: factor scores, questionnaire
%                          totals, number of structural changes
%   README.md          — data dictionary
%
% Excludes: Prolific ID, IP address, timestamps, free-text responses,
% demographic fields (age/sex) — kept out entirely rather than risk
% quasi-identifying combinations.

clc;
base   = '/Users/georgetertikas/Documents/Nadescha_code';
outdir = '/Users/georgetertikas/Documents/Nadescha_anonymised_dataset';
if ~exist(outdir,'dir'), mkdir(outdir); end
cd(base); addpath(genpath(base));

fprintf('=== Loading raw data (readdat) ===\n');
s = [];
pilotID = 7;
choice4 = 0;
s = readdat(s, pilotID);
N = length(s.subID);
fprintf('  N=%d subjects loaded\n', N);

fprintf('=== setrelev / formatdat / checkdat ===\n');
s = setrelev(s);
for is = 1:N, s = formatdat(s, is, choice4); end
for is = 1:N, s = checkdat(s, is, choice4); end

fprintf('=== getpmat / loadQuest / factana / anadesc ===\n');
s = getpmat(s);
s = loadQuest(s, 0);
s = factana(s);
s = anadesc(s, [0 0 0]);   % adds trueSwitch to pmat

% ------------------------------------------------------------------------
% Anonymous subject key: sequential integer, NOT s.subID (Prolific ID)
% ------------------------------------------------------------------------
subject_id = (1:N)';

% ------------------------------------------------------------------------
% TRIAL-LEVEL DATA (phase 6 = main experiment)
% ------------------------------------------------------------------------
fprintf('=== Building trial_data.csv ===\n');
allrows = [];
iphase  = 6;
for isub = 1:N
    pmat = s.sub{isub}.phase{iphase}.opt.pmat;

    stimidx    = get_from_mat(pmat, 'stimidx');       % 1=FB, 0=noFB
    pred_ID    = get_from_mat(pmat, 'pred_ID');
    opt_ID     = get_from_mat(pmat, 'opt_ID');
    accept     = get_from_mat(pmat, 'accept');
    corrAns    = get_from_mat(pmat, 'corrAns');
    FB_choice  = get_from_mat(pmat, 'FB_optchoice');  % -1 if no feedback shown
    trueSwitch = get_from_mat(pmat, 'trueSwitch');    % 1 = structural-change trial

    nTr = length(stimidx);
    trial = (1:nTr)';

    allrows = [allrows; repmat(subject_id(isub),nTr,1), trial, stimidx, ...
               pred_ID, opt_ID, accept, corrAns, FB_choice, trueSwitch];
end

Ttrial = array2table(allrows, 'VariableNames', ...
    {'subject_id','trial','condition_FB','predictor_id','option_id', ...
     'choice_accept','correct_answer','feedback_outcome','structural_change'});
writetable(Ttrial, fullfile(outdir,'trial_data.csv'));
fprintf('  wrote trial_data.csv (%d rows)\n', size(Ttrial,1));

% ------------------------------------------------------------------------
% SUBJECT-LEVEL SUMMARY
% ------------------------------------------------------------------------
fprintf('=== Building subject_summary.csv ===\n');
n_switches = NaN(N,1);
for isub = 1:N
    n_switches(isub) = s.sub{isub}.info.nrswitch(end);
end

fa   = s.fa_sub.mat;          % columns: AD, SU, OC (see Methods: factor order)
quest_tot  = s.quest.tot;     % columns: s.quest.name
quest_name = s.quest.name;    % {'OCIR';'ICAA';'LSAS_fear';'LSAS_avoid';'AMI';'BIS';'DASS';'SSMS';'RSS'}

Tsummary = table(subject_id, n_switches, fa(:,1), fa(:,2), fa(:,3), ...
    'VariableNames', {'subject_id','n_structural_changes','factor_AD','factor_SU','factor_OC'});
for iq = 1:length(quest_name)
    Tsummary.(['quest_' quest_name{iq}]) = quest_tot(:,iq);
end
writetable(Tsummary, fullfile(outdir,'subject_summary.csv'));
fprintf('  wrote subject_summary.csv (%d rows)\n', size(Tsummary,1));

fprintf('=== DONE. Output in %s ===\n', outdir);
