% run_spe_twocomponent.m
% Tests pre-registered Analysis 3b: separate same-structure (sPE_NOchange)
% and different-structure (sPE_change) PEs as predictors of switching.
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

faN  = normalise(s.fa_sub.mat(:,3));

swNr = NaN(1,length(s.subID));
for isub = 1:length(s.subID)
    swNr(isub) = s.sub{isub}.info.nrswitch(end);
end

subidx = find(swNr > 1);
allvars = [];

for is = 1:length(subidx)
    isub = subidx(is);
    FB       = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');
    FB(FB==-1) = 0;
    chgidx   = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'chgidx');
    stimidx  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'stimidx');
    accept   = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'accept');

    swTr    = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
    order   = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,{'opt_ID';'pred_ID'});

    % MB indexing matching strPE_inf_LMM (exclusive end)
    MBidx = 1:20:length(stimidx);
    MBidx(end+1) = length(stimidx);

    sPE_change   = [];
    sPE_NOchange = [];

    i = 1;
    while i < length(MBidx)
        curidx = MBidx(i):MBidx(i+1)-1;
        FBidx      = curidx(stimidx(curidx)==1);
        FBchgidx   = FBidx(chgidx(FBidx)==1);
        FBnochgidx = FBidx(chgidx(FBidx)==0);

        if ~isempty(FBchgidx)
            sPE_change   = [sPE_change;   1 - mean(FB(FBchgidx))];
        else
            sPE_change   = [sPE_change;   NaN];
        end
        if ~isempty(FBnochgidx)
            sPE_NOchange = [sPE_NOchange; 1 - mean(FB(FBnochgidx))];
        else
            sPE_NOchange = [sPE_NOchange; NaN];
        end
        i = i + 1;
    end

    % Expand to trial level — 8 noFB trials per MB (matching strPE_inf_LMM)
    chnr = 8;
    FB_sPE_change   = [];
    FB_sPE_NOchange = [];
    for i = 1:length(sPE_change)
        FB_sPE_change   = [FB_sPE_change;   repmat(sPE_change(i),   chnr, 1)];
        FB_sPE_NOchange = [FB_sPE_NOchange; repmat(sPE_NOchange(i), chnr, 1)];
    end

    % Switch/stay: matching strPE_inf_LMM (start from first switch)
    stayswitch = NaN(length(accept),1);
    startsw = find(swTr);
    for io = startsw(1):length(order)
        curor = order(io,:);
        curch = accept(io);
        idx   = find(sum(ismember(order,curor)')==2);
        prevtr = idx(idx < io);
        if ~isempty(prevtr)
            picktr = prevtr(end);
            if accept(picktr) == curch
                stayswitch(io) = 0;
            else
                stayswitch(io) = 1;
            end
        end
    end
    noFBsw_ch = stayswitch(stimidx==0);

    % Trim to matched length
    n = min([length(noFBsw_ch), length(FB_sPE_change), length(FB_sPE_NOchange)]);
    noFBsw_ch       = noFBsw_ch(1:n);
    FB_sPE_change   = FB_sPE_change(1:n);
    FB_sPE_NOchange = FB_sPE_NOchange(1:n);

    allvars = [allvars; noFBsw_ch ...
        nannormalise(FB_sPE_change) nannormalise(FB_sPE_NOchange) ...
        repmat(is, n, 1) repmat(faN(isub), n, 1)];
end

% Remove rows with any NaN
allvars = allvars(~any(isnan(allvars),2), :);

noFBsw_ch    = allvars(:,1);
sPEchg_norm  = allvars(:,2);  % different-structure PE
sPEnoch_norm = allvars(:,3);  % same-structure PE
subID        = allvars(:,4);
FAsub        = allvars(:,5);

tbl = table(noFBsw_ch, sPEchg_norm, sPEnoch_norm, subID, FAsub);

fprintf('\n========================================================\n');
fprintf('Analysis 3b: Two-component s-PE GLMM\n');
fprintf('N trials = %d (after NaN removal)\n', height(tbl));
fprintf('N subjects = %d\n', length(unique(subID)));
fprintf('========================================================\n');

% Model 1: both PEs + OC (no interaction)
lme_3b_main = fitglme(tbl, ...
    'noFBsw_ch ~ sPEchg_norm + sPEnoch_norm + FAsub + (1|subID)', ...
    'Distribution','binomial','Link','logit');
fprintf('\n[Model 1] Both PEs + OC (additive)\n');
fprintf('Formula: noFBsw_ch ~ sPEchg_norm + sPEnoch_norm + FAsub + (1|subID)\n');
for ic = 1:height(lme_3b_main.Coefficients)
    fprintf('  %-35s  beta=%8.4f  SE=%.4f  z=%.3f  p=%.4f\n', ...
        lme_3b_main.CoefficientNames{ic}, ...
        lme_3b_main.Coefficients.Estimate(ic), ...
        lme_3b_main.Coefficients.SE(ic), ...
        lme_3b_main.Coefficients.tStat(ic), ...
        lme_3b_main.Coefficients.pValue(ic));
end

% Model 2: both PEs × OC interactions
lme_3b_int = fitglme(tbl, ...
    'noFBsw_ch ~ sPEchg_norm*FAsub + sPEnoch_norm*FAsub + (1|subID)', ...
    'Distribution','binomial','Link','logit');
fprintf('\n[Model 2] Both PEs × OC interactions\n');
fprintf('Formula: noFBsw_ch ~ sPEchg_norm*FAsub + sPEnoch_norm*FAsub + (1|subID)\n');
for ic = 1:height(lme_3b_int.Coefficients)
    fprintf('  %-40s  beta=%8.4f  SE=%.4f  z=%.3f  p=%.4f\n', ...
        lme_3b_int.CoefficientNames{ic}, ...
        lme_3b_int.Coefficients.Estimate(ic), ...
        lme_3b_int.Coefficients.SE(ic), ...
        lme_3b_int.Coefficients.tStat(ic), ...
        lme_3b_int.Coefficients.pValue(ic));
end

% Correlation between the two PEs (collinearity check)
r_pe = corr(sPEchg_norm, sPEnoch_norm, 'rows','complete','type','Pearson');
fprintf('\nCorrelation between sPE_change and sPE_NOchange: r = %.3f\n', r_pe);

fprintf('\n=== DONE ===\n');
