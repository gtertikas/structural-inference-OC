%% missing_analyses.m
% Adds all statistical analyses missing from the results text.
% Run after setup_env.m (s struct must be in workspace).
% For section 4 (paired t-test), run prepostMB.m first.

fa   = s.fa_sub.mat(:,3);           % OC dimension scores (raw, as used in prepostMB)
faN  = normalise(s.fa_sub.mat(:,3)); % OC scores normalised across participants

for isub = 1:length(s.subID)
    swNr(isub) = s.sub{isub}.info.nrswitch(end);
    tmpFB      = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');
    tmpFB(tmpFB == -1) = 0;
    stimidx    = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'stimidx');
    FBsub(isub)   = mean(tmpFB(stimidx == 1));
    noFBsub(isub) = mean(tmpFB(stimidx == 0));
end


%% =========================================================================
%% 1. ABOVE-CHANCE PERFORMANCE TEST (Figure 2a)
%% =========================================================================

[~, p_chance, ci_chance, stats_chance] = ttest(FBsub', 0.5);

fprintf('\n=== Figure 2a: Above-chance performance ===\n');
fprintf('Median = %.3f, Mean = %.3f (SD = %.3f)\n', ...
    median(FBsub), mean(FBsub), std(FBsub));
fprintf('One-sample t-test vs 0.5: t(%d) = %.3f, p = %.4f\n', ...
    stats_chance.df, stats_chance.tstat, p_chance);
fprintf('95%% CI: [%.3f, %.3f]\n', ci_chance(1), ci_chance(2));


%% =========================================================================
%% 2. LINEAR TREND: STRUCTURAL CHANGES -> NO-FB INFERENCE (Figure 2d)
%% =========================================================================

[r_trend, p_trend] = corr(swNr', noFBsub', 'Type','Spearman','rows','complete');

fprintf('\n=== Figure 2d: Linear trend structural changes -> noFB performance ===\n');
fprintf('Spearman r = %.3f, p = %.4f\n', r_trend, p_trend);

figure
scatterhist(swNr', noFBsub', 'Location','SouthEast','Direction','out', ...
    'Color','kbr','LineStyle',{'-'},'LineWidth',[2],'Marker','+od','MarkerSize',[4]);
set_default_fig_properties(gca, gcf); hold all;
xlabel('Number of structural changes');
ylabel('no-FB performance');
title(['Spearman r = ' num2str(round(r_trend,3)) ', p = ' num2str(round(p_trend,3))]);


%% =========================================================================
%% 3. LINEAR RANDOM INTERCEPT MODEL: noFBperf ~ FBperf (Figure 2e)
%% =========================================================================
% Simpler model (intercept + FB effect only) matching the text description.
% Restricted to participants with >2 structural changes, consistent with
% basicBehaviour.m.

subidx2e = find(swNr > 2);
FBperf2e   = FBsub(subidx2e)';
noFBperf2e = noFBsub(subidx2e)';
subID2e    = (1:length(subidx2e))';

tbl2e = table(subID2e, FBperf2e, noFBperf2e);
lme_simple = fitlme(tbl2e, 'noFBperf2e ~ FBperf2e + (1|subID2e)');

fprintf('\n=== Figure 2e: Linear random intercept model noFBperf ~ FBperf ===\n');
fprintf('Intercept: beta = %.3f, SE = %.3f, t(%d) = %.3f, p = %.4f\n', ...
    lme_simple.Coefficients.Estimate(1), lme_simple.Coefficients.SE(1), ...
    lme_simple.Coefficients.DF(1),       lme_simple.Coefficients.tStat(1), ...
    lme_simple.Coefficients.pValue(1));
fprintf('FB effect: beta = %.3f, SE = %.3f, t(%d) = %.3f, p = %.4f\n', ...
    lme_simple.Coefficients.Estimate(2), lme_simple.Coefficients.SE(2), ...
    lme_simple.Coefficients.DF(2),       lme_simple.Coefficients.tStat(2), ...
    lme_simple.Coefficients.pValue(2));


%% =========================================================================
%% 4. PAIRED T-TEST: MB t vs MB t+1 (Figure 5b)
%% =========================================================================
% Requires FB_sub to be in the workspace.
% Run prepostMB.m first, then execute this section.
%   FB_sub(:,2) = MB t  (immediately post-switch)
%   FB_sub(:,3) = MB t+1 (subsequent MB)

if exist('FB_sub','var')
    [~, p_mb, ci_mb, stats_mb] = ttest(FB_sub(:,2), FB_sub(:,3));
    fprintf('\n=== Figure 5b: Paired t-test MB t vs MB t+1 (FB trials) ===\n');
    fprintf('Mean MB t = %.3f (SD = %.3f)\n',   nanmean(FB_sub(:,2)), nanstd(FB_sub(:,2)));
    fprintf('Mean MB t+1 = %.3f (SD = %.3f)\n', nanmean(FB_sub(:,3)), nanstd(FB_sub(:,3)));
    fprintf('t(%d) = %.3f, p = %.4f\n', stats_mb.df, stats_mb.tstat, p_mb);
    fprintf('95%% CI of difference: [%.3f, %.3f]\n', ci_mb(1), ci_mb(2));
else
    fprintf('\n=== Figure 5b: Run prepostMB.m first to compute FB_sub ===\n');
end


%% =========================================================================
%% 5. OC vs INITIAL PERFORMANCE — SPEARMAN (Figure 4a)
%% =========================================================================
% Initial performance = practice phases (prac1=4, prac2=5) +
%                       experiment (phase 6) before first structural change.
% NOTE: if phase numbering differs in your setup, update [4 5] below.

initPerf = NaN(length(s.subID), 1);

for isub = 1:length(s.subID)
    perfAll = [];

    % Practice phases
    for iphase = [4 5]
        try
            tmpFB = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat, 'FB_optchoice');
            tmpFB(tmpFB == -1) = 0;
            perfAll = [perfAll; tmpFB];
        catch
            % phase does not exist for this subject, skip
        end
    end

    % Experiment phase — trials before first structural change only
    FB6  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat, 'FB_optchoice');
    FB6(FB6 == -1) = 0;
    swTr = get_from_mat(s.sub{isub}.phase{6}.opt.pmat, 'trueSwitch');
    firstSw = find(swTr == 1, 1);
    if ~isempty(firstSw) && firstSw > 1
        perfAll = [perfAll; FB6(1:firstSw-1)];
    else
        perfAll = [perfAll; FB6];
    end

    if ~isempty(perfAll)
        initPerf(isub) = mean(perfAll);
    end
end

[r_init, p_init] = corr(initPerf, fa, 'Type','Spearman','rows','complete');

fprintf('\n=== Figure 4a: OC vs initial performance (pre-change) ===\n');
fprintf('Mean initial performance = %.3f (SD = %.3f)\n', ...
    nanmean(initPerf), nanstd(initPerf));
fprintf('Spearman r = %.3f, p = %.4f\n', r_init, p_init);

figure
scatterhist(fa, initPerf, 'Location','SouthEast','Direction','out', ...
    'Color','kbr','LineStyle',{'-'},'LineWidth',[2],'Marker','+od','MarkerSize',[4]);
set_default_fig_properties(gca, gcf); hold all;
xlabel('OC dimension score');
ylabel('Initial performance (pre-change)');
title(['Spearman r = ' num2str(round(r_init,3)) ', p = ' num2str(round(p_init,3))]);


%% =========================================================================
%% 6. OC vs MC QUESTION REPETITIONS — SPEARMAN (Figure 4c)
%% =========================================================================
% mc_reps = total answer_correct entries / 8 questions.
% = 1 if passed first time, 2 if repeated once, etc.

nMC = 8;
mc_reps = NaN(length(s.subID), 1);

for isub = 1:length(s.subID)
    mc_reps(isub) = numel(get_from_mat(s.sub{isub}.phase{2}.pmat, {'answer_correct'})) / nMC;
end

[r_mc, p_mc] = corr(mc_reps, fa, 'Type','Spearman','rows','complete');

fprintf('\n=== Figure 4c: OC vs MC question repetitions ===\n');
fprintf('Median repetitions = %.1f (range: %.0f-%.0f)\n', ...
    median(mc_reps,'omitnan'), min(mc_reps), max(mc_reps));
fprintf('Spearman r = %.3f, p = %.4f\n', r_mc, p_mc);

figure
scatterhist(fa, mc_reps, 'Location','SouthEast','Direction','out', ...
    'Color','kbr','LineStyle',{'-'},'LineWidth',[2],'Marker','+od','MarkerSize',[4]);
set_default_fig_properties(gca, gcf); hold all;
xlabel('OC dimension score');
ylabel('Number of MC repetitions');
title(['Spearman r = ' num2str(round(r_mc,3)) ', p = ' num2str(round(p_mc,3))]);


%% =========================================================================
%% 7. SAMPLE DEMOGRAPHICS
%% =========================================================================

% --- Exclusion counts ---
n_noatt_any  = length(s.quest.noatt.all);   % failed >= 1 attention check
n_noatt_many = length(s.quest.noatt.many);  % failed >= 2 attention checks (used for exclusion)

meanperf_all = NaN(length(s.subID), 1);
for isub = 1:length(s.subID)
    tmpFB = get_from_mat(s.sub{isub}.phase{6}.opt.pmat, 'FB_optchoice');
    tmpFB(tmpFB == -1) = 0;
    meanperf_all(isub) = mean(tmpFB);
end
n_belowchance = sum(meanperf_all < 0.5);

fprintf('\n=== Sample demographics ===\n');
fprintf('N in final sample:                 %d\n', length(s.subID));
fprintf('N excluded (2+ attention fails):   %d\n', n_noatt_many);
fprintf('N excluded (below-chance perf):    %d\n', n_belowchance);

% --- Age and sex ---
% Qualtrics column names for age and sex need to be verified.
% Print all variable names if the expected ones are not found.
fprintf('\n--- Age and sex ---\n');
varnames = s.quest.tab.Properties.VariableNames;

% Try common Qualtrics age field names
age_candidates = {'Q_age','age','Age','Q_Age','Q2','Q3'};
found_age = false;
for ic = 1:length(age_candidates)
    if ismember(age_candidates{ic}, varnames)
        age = s.quest.tab.(age_candidates{ic});
        age = str2double(string(age));
        fprintf('Age: mean = %.1f, SD = %.1f, range = %.0f-%.0f\n', ...
            nanmean(age), nanstd(age), nanmin(age), nanmax(age));
        found_age = true;
        break
    end
end
if ~found_age
    fprintf('Age column not found. Available columns containing ''age'' or ''Age'':\n');
    disp(varnames(contains(lower(varnames),'age'))');
    fprintf('Update age_candidates above with the correct column name.\n');
end

% Try common Qualtrics sex/gender field names
sex_candidates = {'Q_sex','sex','Sex','gender','Gender','Q_gender','Q4','Q5'};
found_sex = false;
for ic = 1:length(sex_candidates)
    if ismember(sex_candidates{ic}, varnames)
        sex = s.quest.tab.(sex_candidates{ic});
        sex = string(sex);
        n_female = sum(lower(sex) == "female" | sex == "2" | sex == "F" | sex == "f");
        fprintf('N female: %d / %d\n', n_female, length(s.subID));
        found_sex = true;
        break
    end
end
if ~found_sex
    fprintf('Sex column not found. Available columns containing ''sex'' or ''gender'':\n');
    disp(varnames(contains(lower(varnames),'sex') | contains(lower(varnames),'gender'))');
    fprintf('Update sex_candidates above with the correct column name.\n');
end
