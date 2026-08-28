%% extract_all_stats.m
% Runs ALL missing statistical analyses and prints formatted results for
% OCD_paper_draft_22_04_2026.docx.
%
% REQUIREMENTS: run setup_env.m first so that the 's' struct is in workspace.
% For Figure 6e, also run strPE_inf_LMM.m first so lmeMlog is available.
%
% OUTPUT: formatted fprintf output — copy values directly into manuscript.

fprintf('\n========================================================\n');
fprintf('OC Structural Inference — All Missing Statistics\n');
fprintf('Generated: %s\n', datestr(now));
fprintf('========================================================\n');

%% =========================================================================
%% SHARED SETUP
%% =========================================================================

fa   = s.fa_sub.mat(:,3);            % raw OC factor scores (for Spearman)
faN  = normalise(s.fa_sub.mat(:,3)); % normalised OC scores  (for LME/GLME)
icar = normalise(s.quest.tot(:,2));

swNr    = NaN(1, length(s.subID));
FBsub   = NaN(1, length(s.subID));
noFBsub = NaN(1, length(s.subID));

for isub = 1:length(s.subID)
    swNr(isub)    = s.sub{isub}.info.nrswitch(end);
    tmpFB         = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');
    tmpFB(tmpFB == -1) = 0;
    stimidx       = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'stimidx');
    FBsub(isub)   = mean(tmpFB(stimidx == 1));
    noFBsub(isub) = mean(tmpFB(stimidx == 0));
end


%% =========================================================================
%% FIGURE 2a — Above-chance FB performance (one-sample t-test vs 0.5)
%% =========================================================================

[~, p_2a, ci_2a, st_2a] = ttest(FBsub', 0.5);

fprintf('\n--- Figure 2a: Above-chance FB performance ---\n');
fprintf('  N = %d\n', length(s.subID));
fprintf('  Mean = %.3f, SD = %.3f, Median = %.3f\n', ...
    mean(FBsub), std(FBsub), median(FBsub));
fprintf('  t(%d) = %.3f, p = %.4f\n', st_2a.df, st_2a.tstat, p_2a);
fprintf('  95%% CI: [%.3f, %.3f]\n', ci_2a(1), ci_2a(2));
fprintf('  [%% with >1 switch: %.1f%%]\n', 100*mean(swNr > 1));


%% =========================================================================
%% FIGURE 2d — Linear trend: structural changes → noFB performance (Spearman)
%% =========================================================================

[r_2d, p_2d] = corr(swNr', noFBsub', 'Type','Spearman','rows','complete');

fprintf('\n--- Figure 2d: Linear trend structural changes vs noFB performance ---\n');
fprintf('  Spearman rho = %.3f, p = %.4f\n', r_2d, p_2d);


%% =========================================================================
%% FIGURE 2e — LME: noFBperf ~ FBperf  (participants with >2 switches)
%% =========================================================================

% FBperf in % and mean-centred so intercept = mean noFB perf at avg FB perf
subidx2e       = find(swNr > 2);
FBperf2e_pct   = FBsub(subidx2e)' * 100;
noFBperf2e_pct = noFBsub(subidx2e)' * 100;
FBperf2e_cent  = FBperf2e_pct - mean(FBperf2e_pct, 'omitnan');
subID2e        = (1:length(subidx2e))';

tbl2e  = table(subID2e, FBperf2e_cent, noFBperf2e_pct);
lme_2e = fitlme(tbl2e, 'noFBperf2e_pct ~ FBperf2e_cent + (1|subID2e)');

fprintf('\n--- Figure 2e: LME noFBperf ~ FBperf_centred (%%, swNr>2, N=%d) ---\n', ...
    length(subidx2e));
fprintf('  Intercept (= mean noFB perf at avg FB perf): beta = %.2f%%, SE = %.3f, t(%d) = %.3f, p = %.4f\n', ...
    lme_2e.Coefficients.Estimate(1), lme_2e.Coefficients.SE(1), ...
    lme_2e.Coefficients.DF(1),       lme_2e.Coefficients.tStat(1), ...
    lme_2e.Coefficients.pValue(1));
fprintf('  FB effect (slope, %%/%%):                    beta = %.3f, SE = %.3f, t(%d) = %.3f, p = %.4f\n', ...
    lme_2e.Coefficients.Estimate(2), lme_2e.Coefficients.SE(2), ...
    lme_2e.Coefficients.DF(2),       lme_2e.Coefficients.tStat(2), ...
    lme_2e.Coefficients.pValue(2));


%% =========================================================================
%% FIGURE 4a — OC vs initial (pre-change) performance (Spearman)
%% =========================================================================

initPerf = NaN(length(s.subID), 1);

for isub = 1:length(s.subID)
    perfAll = [];
    % Practice phases
    for iphase = [4 5]
        try
            tmpFB = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'FB_optchoice');
            tmpFB(tmpFB == -1) = 0;
            perfAll = [perfAll; tmpFB];
        catch
        end
    end
    % Phase 6 trials before first structural change
    FB6  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');
    FB6(FB6 == -1) = 0;
    swTr = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
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

[r_4a, p_4a] = corr(initPerf, fa, 'Type','Spearman','rows','complete');

fprintf('\n--- Figure 4a: OC vs initial (pre-change) performance ---\n');
fprintf('  Mean initial perf = %.3f (SD = %.3f)\n', nanmean(initPerf), nanstd(initPerf));
fprintf('  Spearman rho = %.3f, p = %.4f\n', r_4a, p_4a);


%% =========================================================================
%% FIGURE 4b — OC vs comprehension question repetitions (Spearman)
%% =========================================================================

nMC      = 8;
mc_reps  = NaN(length(s.subID), 1);

for isub = 1:length(s.subID)
    mc_reps(isub) = ...
        numel(get_from_mat(s.sub{isub}.phase{2}.pmat, {'answer_correct'})) / nMC;
end

[r_4b, p_4b] = corr(mc_reps, fa, 'Type','Spearman','rows','complete');

fprintf('\n--- Figure 4b: OC vs MC question repetitions ---\n');
fprintf('  Median reps = %.1f (range: %.0f-%.0f)\n', ...
    median(mc_reps,'omitnan'), min(mc_reps), max(mc_reps));
fprintf('  Spearman rho = %.3f, p = %.4f\n', r_4b, p_4b);


%% =========================================================================
%% FIGURES 5a / 5b / 5c / 6c — prepostMB correlations + paired t-test
%%   Recomputes FB_sub and noFB_sub (pre = MB t-1, post = MB t, post2 = MB t+1)
%% =========================================================================

pre_sub3   = cell(length(s.subID), 1);
post_sub3  = cell(length(s.subID), 1);
post2_sub3 = cell(length(s.subID), 1);
simidx_sub3= cell(length(s.subID), 1);

for isub = 1:length(s.subID)
    showFB = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'allFB');
    swTr   = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
    nTr    = length(swTr);

    % Mark hidden trials (positions 17-20 of each MB) with value 2
    hididx = []; a1 = 17; a2 = 20;
    while a2 < nTr + 5
        hididx = [hididx; a1 a2]; a1 = a1+20; a2 = a2+20;
    end
    if ~isempty(hididx), hididx(end,:) = []; end
    dsc = sort(1:size(hididx,1), 'descend');
    for i = 1:length(dsc)
        showFB(hididx(dsc(i),1):min(hididx(dsc(i),2), length(showFB))) = 2;
    end

    % Find switches (skip first)
    swidx = find(swTr == 1); swidx(1) = []; swidx = swidx - 1;

    MBl = 20;
    prevec  = NaN(nTr, 1);
    postvec = NaN(nTr, 1);
    post2vec= NaN(nTr, 1);

    for i = 1:length(swidx)
        lo = max(1, swidx(i) - MBl); hi1 = min(nTr, swidx(i));
        prevec(lo:hi1) = i;
        hi2 = min(nTr, swidx(i) + MBl);
        postvec(swidx(i):hi2) = i;
        lo2 = min(nTr, swidx(i) + MBl);
        hi3 = min(nTr, swidx(i) + MBl*2);
        post2vec(lo2:hi3) = i;
    end

    pre_sub3{isub}   = prevec;
    post_sub3{isub}  = postvec;
    post2_sub3{isub} = post2vec;
    simidx_sub3{isub}= showFB(1:nTr);
end

FB3_sub   = NaN(length(s.subID), 3);
noFB3_sub = NaN(length(s.subID), 3);

for isub = 1:length(s.subID)
    FB_raw  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');
    FB_raw(FB_raw == -1) = 0;
    curstim = simidx_sub3{isub};
    preidx  = find(~isnan(pre_sub3{isub}));
    postidx = find(~isnan(post_sub3{isub}));
    p2idx   = find(~isnan(post2_sub3{isub}));

    FBidx   = find(curstim == 1);
    noFBidx = find(curstim == 0);

    FB3_sub(isub,1) = mean(FB_raw(FBidx(ismember(FBidx,   preidx))));
    FB3_sub(isub,2) = mean(FB_raw(FBidx(ismember(FBidx,  postidx))));
    FB3_sub(isub,3) = mean(FB_raw(FBidx(ismember(FBidx,   p2idx))));

    noFB3_sub(isub,1) = mean(FB_raw(noFBidx(ismember(noFBidx,  preidx))));
    noFB3_sub(isub,2) = mean(FB_raw(noFBidx(ismember(noFBidx, postidx))));
    noFB3_sub(isub,3) = mean(FB_raw(noFBidx(ismember(noFBidx,  p2idx))));
end

% Figure 5a: structural changes vs OC
[r_5a, p_5a] = corr(swNr', fa, 'Type','Spearman','rows','complete');
fprintf('\n--- Figure 5a: Spearman structural changes vs OC ---\n');
fprintf('  rho = %.3f, p = %.4f\n', r_5a, p_5a);

% Figure 5b: paired t-test MB t vs MB t+1 (FB trials)
[~, p_5b, ci_5b, st_5b] = ttest(FB3_sub(:,2), FB3_sub(:,3));
fprintf('\n--- Figure 5b: Paired t-test MB t vs MB t+1 (FB trials) ---\n');
fprintf('  Mean MB t   = %.3f (SD = %.3f)\n', nanmean(FB3_sub(:,2)), nanstd(FB3_sub(:,2)));
fprintf('  Mean MB t+1 = %.3f (SD = %.3f)\n', nanmean(FB3_sub(:,3)), nanstd(FB3_sub(:,3)));
fprintf('  t(%d) = %.3f, p = %.4f\n', st_5b.df, st_5b.tstat, p_5b);
fprintf('  95%% CI of difference: [%.3f, %.3f]\n', ci_5b(1), ci_5b(2));

% Figure 5c: MB t-1, MB t, MB t+1 vs OC (FB trials)
[r_5c_1, p_5c_1] = corr(fa, FB3_sub(:,1), 'Type','Spearman','rows','complete');
[r_5c_2, p_5c_2] = corr(fa, FB3_sub(:,2), 'Type','Spearman','rows','complete');
[r_5c_3, p_5c_3] = corr(fa, FB3_sub(:,3), 'Type','Spearman','rows','complete');
fprintf('\n--- Figure 5c: Spearman FB performance vs OC across MBs ---\n');
fprintf('  MB t-1 vs OC: rho = %.3f, p = %.4f\n', r_5c_1, p_5c_1);
fprintf('  MB t   vs OC: rho = %.3f, p = %.4f\n', r_5c_2, p_5c_2);
fprintf('  MB t+1 vs OC: rho = %.3f, p = %.4f\n', r_5c_3, p_5c_3);

% Figure 6c: noFB MB t+1 vs OC
[r_6c, p_6c] = corr(fa, noFB3_sub(:,3), 'Type','Spearman','rows','complete');
fprintf('\n--- Figure 6c: Spearman noFB MB t+1 vs OC ---\n');
fprintf('  rho = %.3f, p = %.4f\n', r_6c, p_6c);


%% =========================================================================
%% FIGURE 5d/e — GLMM ab-PE model
%%   switch/stay on first predictor of MB t+1 ~ prevPE * OC
%% =========================================================================

subidxAB = find(swNr > 1);
newvarsAB = [];

for is = 1:length(subidxAB)
    isub   = subidxAB(is);
    swTr   = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
    accept = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'accept');
    pairs  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,{'opt_ID';'pred_ID'});
    FB_ab  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');
    FB_ab(FB_ab == -1) = 0;
    swidx  = find(swTr == 1);

    % Label MB t (=1) and MB t+1 (=2) around each switch
    newMB = NaN(1, length(swTr));
    for i = 1:length(swidx)
        hi1 = min(swidx(i)+19, length(swTr));
        hi2 = min(swidx(i)+39, length(swTr));
        newMB(swidx(i):hi1) = 1;
        newMB(swidx(i)+20:hi2) = 2;
    end
    if length(newMB) > length(swTr), newMB = newMB(1:length(swTr)); end

    MBt1 = find(newMB == 2);
    % Only take first predictor (positions 1-4 within each 20-trial MB)
    newidx = []; ia = 1:4;
    while max(ia) < length(MBt1)
        newidx = [newidx ia]; ia = ia + 20;
    end
    if isempty(newidx), continue; end
    MBt1_idx = MBt1(newidx);
    curch    = accept(MBt1_idx);

    swstay = NaN(1, length(MBt1_idx));
    prevPE = NaN(1, length(MBt1_idx));
    for i = 1:length(MBt1_idx)
        cidx    = MBt1_idx(i);
        pr      = pairs(cidx,:);
        previdx = find(sum(ismember(pairs, pr)') == 2);
        prtr_v  = previdx(previdx < cidx);
        if isempty(prtr_v), continue; end
        prtr       = prtr_v(end);
        swstay(i)  = double(accept(prtr) ~= curch(i));
        prevPE(i)  = 1 - FB_ab(prtr);
    end

    swstay = swstay'; prevPE = prevPE';
    newvarsAB = [newvarsAB; ...
        swstay nannormalise(prevPE) repmat(is, length(prevPE),1) ...
        repmat(faN(isub), length(prevPE),1)];
end

switchvarAB = newvarsAB(:,1);
prevPEvarAB = newvarsAB(:,2);
subvarAB    = newvarsAB(:,3);
favarAB     = newvarsAB(:,4);

tblAB    = table(switchvarAB, prevPEvarAB, subvarAB, favarAB);
lmelog_5 = fitglme(tblAB, ...
    'switchvarAB ~ prevPEvarAB*favarAB + (1|subvarAB)', ...
    'Distribution','binomial','Link','logit');

fprintf('\n--- Figure 5d/e: GLMM ab-PE model (switch ~ prevPE*OC) ---\n');
cnames5 = lmelog_5.CoefficientNames;
coefs5  = lmelog_5.Coefficients;
for ic = 1:height(coefs5)
    fprintf('  %-35s  beta = %7.4f, SE = %.4f, z = %6.3f, p = %.4f\n', ...
        cnames5{ic}, coefs5.Estimate(ic), coefs5.SE(ic), ...
        coefs5.tStat(ic), coefs5.pValue(ic));
end


%% =========================================================================
%% FIGURE 6a — LME: noFB performance ~ OC * MBsinceSW
%% =========================================================================

subidx6 = find(swNr > 1);
vars_m6 = [];

for is = 1:length(subidx6)
    isub6  = subidx6(is);
    FB6a   = get_from_mat(s.sub{isub6}.phase{6}.opt.pmat,'FB_optchoice');
    FB6a(FB6a == -1) = 0;
    SWopt  = get_from_mat(s.sub{isub6}.phase{6}.opt.pmat,'confirmSwitch');

    a1 = 9; a2 = 16; % noFB trial window within each MB
    prefMB = []; tmp_MBsw = NaN(14,1); icount = 1;
    while a2 < length(FB6a) + 5
        if a2 == 280, a2 = 276; end
        prefMB = [prefMB; mean(FB6a(a1:min(a2,end)))];
        if sum(SWopt(a1:min(a2,end))) > 1
            tmp_MBsw(icount+1) = 1;
        end
        a1 = a1+20; a2 = a2+20; icount = icount+1;
    end
    tmp_MBsw(isnan(tmp_MBsw)) = 0;

    mbi = 0; MBsinceSW6 = [];
    for i = 1:length(tmp_MBsw)
        if tmp_MBsw(i) == 1, mbi = 1; else, mbi = mbi + 1; end
        MBsinceSW6(i) = mbi;
    end
    MBsinceSW6(1) = []; prefMB(1) = [];
    MBcnt = (1:length(prefMB))';

    vars_m6 = [vars_m6; nannormalise(MBcnt) nannormalise(MBsinceSW6') prefMB ...
        repmat(is, length(prefMB),1) repmat(faN(isub6), length(prefMB),1)];
end

MBsw6  = vars_m6(:,2);
MBperf6= vars_m6(:,3);
subID6 = vars_m6(:,4);
FA6    = vars_m6(:,5);

tbl6a  = table(MBsw6, MBperf6, subID6, FA6);
lme_6a = fitlme(tbl6a, 'MBperf6 ~ FA6*MBsw6 + (1|subID6)');

fprintf('\n--- Figure 6a: LME noFB perf ~ OC*MBsinceSW ---\n');
cnames6 = lme_6a.CoefficientNames;
coefs6  = lme_6a.Coefficients;
for ic = 1:height(coefs6)
    fprintf('  %-30s  beta = %7.4f, SE = %.4f, t(%d) = %6.3f, p = %.4f\n', ...
        cnames6{ic}, coefs6.Estimate(ic), coefs6.SE(ic), ...
        coefs6.DF(ic), coefs6.tStat(ic), coefs6.pValue(ic));
end


%% =========================================================================
%% SUPPLEMENTARY FIGURE 1 — GLMM ab-PE across ALL MBs (not just MB t+1)
%%   switch/stay on first predictor of EVERY MB ~ ab-PE * OC
%% =========================================================================

subidxS1 = find(swNr > 1);
newvarsS1 = [];

for is = 1:length(subidxS1)
    isub   = subidxS1(is);
    swTr   = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
    accept = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'accept');
    pairs  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,{'opt_ID';'pred_ID'});
    FB_s1  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');
    FB_s1(FB_s1 == -1) = 0;
    nTr    = length(swTr);

    % First predictor indices across ALL MBs (positions 1-4 of every 20-trial MB)
    allMB_first = [];
    ia = 1:4;
    while max(ia) <= nTr
        allMB_first = [allMB_first ia];
        ia = ia + 20;
    end
    allMB_first = allMB_first(allMB_first <= nTr);

    swstay_s1 = NaN(1, length(allMB_first));
    prevPE_s1 = NaN(1, length(allMB_first));
    curch_s1  = accept(allMB_first);

    for i = 1:length(allMB_first)
        cidx    = allMB_first(i);
        pr      = pairs(cidx,:);
        previdx = find(sum(ismember(pairs, pr)') == 2);
        prtr_v  = previdx(previdx < cidx);
        if isempty(prtr_v), continue; end
        prtr          = prtr_v(end);
        swstay_s1(i)  = double(accept(prtr) ~= curch_s1(i));
        prevPE_s1(i)  = 1 - FB_s1(prtr);
    end

    swstay_s1 = swstay_s1'; prevPE_s1 = prevPE_s1';
    % store raw prevPE (binary 0/1) alongside normalised version for panel c
    newvarsS1 = [newvarsS1; ...
        swstay_s1 nannormalise(prevPE_s1) prevPE_s1 ...
        repmat(is, length(prevPE_s1), 1) ...
        repmat(faN(isub), length(prevPE_s1), 1)];
end

% Remove rows with NaN
validS1   = ~any(isnan(newvarsS1), 2);
newvarsS1 = newvarsS1(validS1, :);
switchS1  = newvarsS1(:,1);   % switch/stay
prevPE_S1 = newvarsS1(:,2);   % normalised prevPE
prevPEraw = newvarsS1(:,3);   % raw binary prevPE (0=win, 1=loss)
subS1     = newvarsS1(:,4);
faS1      = newvarsS1(:,5);

tblS1     = table(switchS1, prevPE_S1, subS1, faS1);
lmelog_S1 = fitglme(tblS1, ...
    'switchS1 ~ prevPE_S1*faS1 + (1|subS1)', ...
    'Distribution','binomial','Link','logit');

fprintf('\n--- Supplementary Figure 1b: GLMM ab-PE ALL MBs — log(switch) y-axis ---\n');
fprintf('  Intercept = baseline log-odds of switching at mean prevPE and mean OC\n');
fprintf('  logistic(intercept) = P(switch) at average conditions = %.1f%%\n', ...
    100 * (1 / (1 + exp(-lmelog_S1.Coefficients.Estimate(1)))));
cnamesS1 = lmelog_S1.CoefficientNames;
coefsS1  = lmelog_S1.Coefficients;
for ic = 1:height(coefsS1)
    fprintf('  %-35s  beta = %7.4f, SE = %.4f, z = %6.3f, p = %.4f\n', ...
        cnamesS1{ic}, coefsS1.Estimate(ic), coefsS1.SE(ic), ...
        coefsS1.tStat(ic), coefsS1.pValue(ic));
end

%% --- Supplementary Figure 1c: % switching vs OC, split by win/loss ---
% win = prevPE=0 (previous encounter correct); loss = prevPE=1 (incorrect)
subList_S1 = unique(subS1);
sw_win_S1  = NaN(length(subList_S1), 1);
sw_loss_S1 = NaN(length(subList_S1), 1);
fa_S1c     = NaN(length(subList_S1), 1);

for is = 1:length(subList_S1)
    sidx = subS1 == subList_S1(is);
    sw_win_S1(is)  = 100 * nanmean(switchS1(sidx & prevPEraw == 0));
    sw_loss_S1(is) = 100 * nanmean(switchS1(sidx & prevPEraw == 1));
    fa_S1c(is)     = nanmean(faS1(sidx));
end

[r_win,  p_win]  = corr(fa_S1c, sw_win_S1,  'Type','Spearman','rows','complete');
[r_loss, p_loss] = corr(fa_S1c, sw_loss_S1, 'Type','Spearman','rows','complete');

fprintf('\n--- Supplementary Figure 1c: %% switch vs OC, split by prev outcome ---\n');
fprintf('  Win  condition (prev correct): Spearman rho = %.3f, p = %.4f\n', r_win,  p_win);
fprintf('  Loss condition (prev wrong):   Spearman rho = %.3f, p = %.4f\n', r_loss, p_loss);
fprintf('  Mean switch%% win  = %.1f%% (SD=%.1f)\n', nanmean(sw_win_S1),  nanstd(sw_win_S1));
fprintf('  Mean switch%% loss = %.1f%% (SD=%.1f)\n', nanmean(sw_loss_S1), nanstd(sw_loss_S1));


%% =========================================================================
%% FIGURE 6e — GLMM s-PE model (from strPE_inf_LMM.m)
%%   Use model 'lme_test1': noFBsw_ch ~ norm_FB_sPE * FAsub + (1|subID)
%% =========================================================================

if exist('lmeMlog','var')
    fprintf('\n--- Figure 6e: GLMM s-PE model (lmeMlog from strPE_inf_LMM.m) ---\n');
    cnames6e = lmeMlog.CoefficientNames;
    coefs6e  = lmeMlog.Coefficients;
    for ic = 1:height(coefs6e)
        fprintf('  %-50s  beta = %7.4f, SE = %.4f, z = %6.3f, p = %.4f\n', ...
            cnames6e{ic}, coefs6e.Estimate(ic), coefs6e.SE(ic), ...
            coefs6e.tStat(ic), coefs6e.pValue(ic));
    end
elseif exist('lme_test1','var')
    fprintf('\n--- Figure 6e: GLMM s-PE model (lme_test1 from strPE_inf_LMM.m) ---\n');
    cnames6e = lme_test1.CoefficientNames;
    coefs6e  = lme_test1.Coefficients;
    for ic = 1:height(coefs6e)
        fprintf('  %-50s  beta = %7.4f, SE = %.4f, z = %6.3f, p = %.4f\n', ...
            cnames6e{ic}, coefs6e.Estimate(ic), coefs6e.SE(ic), ...
            coefs6e.tStat(ic), coefs6e.pValue(ic));
    end
else
    fprintf('\n--- Figure 6e: Run strPE_inf_LMM.m first to populate lmeMlog ---\n');
end

%% =========================================================================
%% FIGURE 6f — GLMM s-PE model refined: s-PE from CHANGED pairs only
%%   noFBsw_ch ~ norm_FB_sPE_change * FAsub + (1|subID)  (lme_test)
%% =========================================================================

if exist('lme_test','var')
    fprintf('\n--- Figure 6f: GLMM s-PE_change model (lme_test from strPE_inf_LMM.m) ---\n');
    cnames6f = lme_test.CoefficientNames;
    coefs6f  = lme_test.Coefficients;
    for ic = 1:height(coefs6f)
        fprintf('  %-50s  beta = %7.4f, SE = %.4f, z = %6.3f, p = %.4f\n', ...
            cnames6f{ic}, coefs6f.Estimate(ic), coefs6f.SE(ic), ...
            coefs6f.tStat(ic), coefs6f.pValue(ic));
    end
else
    fprintf('\n--- Figure 6f: Run strPE_inf_LMM.m first to populate lme_test ---\n');
end


%% =========================================================================
%% DEMOGRAPHICS
%% =========================================================================

n_noatt_many = length(s.quest.noatt.many);
n_noatt_any  = length(s.quest.noatt.all);

meanperf_all = NaN(length(s.subID), 1);
for isub = 1:length(s.subID)
    tmpFB = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');
    tmpFB(tmpFB == -1) = 0;
    meanperf_all(isub) = mean(tmpFB);
end
n_belowchance = sum(meanperf_all < 0.5);

fprintf('\n--- Demographics ---\n');
fprintf('  N final sample:                   %d\n', length(s.subID));
fprintf('  N excluded (2+ attention fails):  %d\n', n_noatt_many);
fprintf('  N excluded (1+ attention fail):   %d\n', n_noatt_any);
fprintf('  N excluded (below-chance perf):   %d\n', n_belowchance);
fprintf('  Median switches:                  %.0f\n', median(swNr));
fprintf('  %% with >1 switch:                %.1f%%\n', 100*mean(swNr > 1));

% Demographics from Prolific export (s.demo.table)
if isfield(s,'demo') && isfield(s.demo,'table')
    demo_varnames = s.demo.table.Properties.VariableNames;

    % Age — from Prolific CSV column "Age"
    age_candidates = {'Age','age','Q_age'};
    found_age = false;
    for ic = 1:length(age_candidates)
        if ismember(age_candidates{ic}, demo_varnames)
            age_vals = s.demo.table.(age_candidates{ic});
            if iscell(age_vals) || isstring(age_vals)
                age_vals = str2double(string(age_vals));
            end
            fprintf('  Age: mean = %.1f, SD = %.1f, range = %.0f-%.0f\n', ...
                nanmean(age_vals), nanstd(age_vals), nanmin(age_vals), nanmax(age_vals));
            found_age = true; break
        end
    end
    if ~found_age
        fprintf('  Age not found in s.demo.table. Available: %s\n', strjoin(demo_varnames,', '));
    end

    % Sex — from Prolific CSV column "Sex"
    sex_candidates = {'Sex','sex','Gender','gender'};
    found_sex = false;
    for ic = 1:length(sex_candidates)
        if ismember(sex_candidates{ic}, demo_varnames)
            sv = string(s.demo.table.(sex_candidates{ic}));
            n_female = sum(strcmpi(sv,'Female'));
            n_male   = sum(strcmpi(sv,'Male'));
            fprintf('  Sex: N female = %d, N male = %d, N other/missing = %d\n', ...
                n_female, n_male, length(s.subID)-n_female-n_male);
            found_sex = true; break
        end
    end
    if ~found_sex
        fprintf('  Sex not found in s.demo.table.\n');
    end
else
    fprintf('  s.demo not available — run readdat first.\n');
end


fprintf('\n========================================================\n');
fprintf('COMPLETE. Copy values above into manuscript placeholders.\n');
fprintf('========================================================\n');
