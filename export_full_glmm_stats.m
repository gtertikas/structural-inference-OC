% Full GLMM/LME stats for all models reported in figures
% Prints intercept + all coefficients with exact p-values
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

for isub = 1:length(s.subID)
    swNr(isub) = s.sub{isub}.info.nrswitch(end);
end
faN = normalise(s.fa_sub.mat(:,3));

fprintf('\n========================================================\n');
fprintf('MODEL 1: Fig4d – GLMM: abPE switch ~ ab-PE * OC\n');
fprintf('========================================================\n');
subidx4 = find(swNr > 1);
vars4 = [];
for is = 1:length(subidx4)
    isub4 = subidx4(is);
    abPE4 = get_from_mat(s.sub{isub4}.phase{6}.opt.pmat, 'FB_absPE');
    sw4   = get_from_mat(s.sub{isub4}.phase{6}.opt.pmat, 'trueSwitch');
    acc4  = get_from_mat(s.sub{isub4}.phase{6}.opt.pmat, 'accept');
    nTr4  = length(sw4);
    for it = 2:nTr4
        vars4 = [vars4; double(acc4(it) ~= acc4(it-1)) ...
                 nannormalise(abPE4(it)) ...
                 repmat(is, 1, 1) ...
                 repmat(faN(isub4), 1, 1)];
    end
end
valid4 = ~any(isnan(vars4), 2);
vars4  = vars4(valid4, :);
sw4v   = vars4(:,1); abPE4v = vars4(:,2);
sub4v  = vars4(:,3); fa4v   = vars4(:,4);
tbl4d  = table(sw4v, abPE4v, sub4v, fa4v);
lme4d  = fitglme(tbl4d, 'sw4v ~ abPE4v*fa4v + (1|sub4v)', ...
                 'Distribution','binomial','Link','logit');
fprintf('  Model: switch ~ ab-PE * OC + (1|subject)\n');
for ic = 1:height(lme4d.Coefficients)
    fprintf('  %-35s  coef=%9.5f  SE=%8.5f  p=%10.6f\n', ...
        lme4d.CoefficientNames{ic}, lme4d.Coefficients.Estimate(ic), ...
        lme4d.Coefficients.SE(ic), lme4d.Coefficients.pValue(ic));
end

fprintf('\n========================================================\n');
fprintf('MODEL 2: Fig5e – GLMM: sPE switch ~ FB-sPE * OC\n');
fprintf('========================================================\n');
% Run strPE_inf_LMM to get lme_full
s = plotrev(s, [0 0 0]);
try
    run('strPE_inf_LMM.m');
catch ME
    fprintf('  (strPE_inf_LMM error at end, model already fitted: %s)\n', ME.message);
end
fprintf('  Model: switch ~ FB-sPE * OC + (1|subject)\n');
for ic = 1:height(lme_full.Coefficients)
    fprintf('  %-35s  coef=%9.5f  SE=%8.5f  p=%10.6f\n', ...
        lme_full.CoefficientNames{ic}, lme_full.Coefficients.Estimate(ic), ...
        lme_full.Coefficients.SE(ic), lme_full.Coefficients.pValue(ic));
end

fprintf('\n========================================================\n');
fprintf('MODEL 3: Fig5f – GLMM: sPE-change switch ~ FB-sPE_changed * OC\n');
fprintf('========================================================\n');
fprintf('  Model: switch ~ FB-sPE_changed * OC + (1|subject)\n');
for ic = 1:height(lme_test.Coefficients)
    fprintf('  %-35s  coef=%9.5f  SE=%8.5f  p=%10.6f\n', ...
        lme_test.CoefficientNames{ic}, lme_test.Coefficients.Estimate(ic), ...
        lme_test.Coefficients.SE(ic), lme_test.Coefficients.pValue(ic));
end

fprintf('\n========================================================\n');
fprintf('MODEL 4: Fig5a – LME: noFB perf ~ OC * MBsinceSW\n');
fprintf('========================================================\n');
subidx6 = find(swNr > 1);
vars_m6 = [];
for is = 1:length(subidx6)
    isub6 = subidx6(is);
    FB6a  = get_from_mat(s.sub{isub6}.phase{6}.opt.pmat, 'FB_optchoice');
    FB6a(FB6a == -1) = 0;
    SWopt = get_from_mat(s.sub{isub6}.phase{6}.opt.pmat, 'confirmSwitch');
    a1 = 9; a2 = 16; prefMB = []; tmp_MBsw = NaN(14,1); icount = 1;
    while a2 < length(FB6a) + 5
        if a2 == 280, a2 = 276; end
        prefMB = [prefMB; mean(FB6a(a1:min(a2,end)))];
        if sum(SWopt(a1:min(a2,end))) > 1, tmp_MBsw(icount+1) = 1; end
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
        repmat(is, length(prefMB), 1) repmat(faN(isub6), length(prefMB), 1)];
end
MBsw6   = vars_m6(:,2); MBperf6 = vars_m6(:,3);
subID6  = vars_m6(:,4); FA6     = vars_m6(:,5);
tbl6a   = table(MBsw6, MBperf6, subID6, FA6);
lme_6a  = fitlme(tbl6a, 'MBperf6 ~ FA6*MBsw6 + (1|subID6)');
fprintf('  Model: noFBperf ~ OC * MBsinceSW + (1|subject)\n');
for ic = 1:height(lme_6a.Coefficients)
    fprintf('  %-35s  beta=%9.5f  SE=%8.5f  p=%10.6f\n', ...
        lme_6a.CoefficientNames{ic}, lme_6a.Coefficients.Estimate(ic), ...
        lme_6a.Coefficients.SE(ic), lme_6a.Coefficients.pValue(ic));
end

fprintf('\n========================================================\n');
fprintf('MODEL 5: SuppFig1b – GLMM: switch ~ prevPE * OC (all MBs, first trial)\n');
fprintf('========================================================\n');
subidxS1 = find(swNr > 1); newvarsS1 = [];
for is = 1:length(subidxS1)
    isub  = subidxS1(is);
    swTr  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat, 'trueSwitch');
    accept= get_from_mat(s.sub{isub}.phase{6}.opt.pmat, 'accept');
    pairs = get_from_mat(s.sub{isub}.phase{6}.opt.pmat, {'opt_ID';'pred_ID'});
    FB_s1 = get_from_mat(s.sub{isub}.phase{6}.opt.pmat, 'FB_optchoice'); FB_s1(FB_s1==-1)=0;
    nTr   = length(swTr);
    allMB_first = []; ia = 1:4;
    while max(ia) <= nTr, allMB_first = [allMB_first ia]; ia = ia+20; end
    allMB_first = allMB_first(allMB_first <= nTr);
    swstay_s1 = NaN(1,length(allMB_first)); prevPE_s1 = NaN(1,length(allMB_first));
    curch_s1  = accept(allMB_first);
    for i = 1:length(allMB_first)
        cidx = allMB_first(i); pr = pairs(cidx,:);
        previdx = find(sum(ismember(pairs,pr)')==2); prtr_v = previdx(previdx < cidx);
        if isempty(prtr_v), continue; end
        prtr = prtr_v(end);
        swstay_s1(i) = double(accept(prtr) ~= curch_s1(i)); prevPE_s1(i) = 1-FB_s1(prtr);
    end
    swstay_s1 = swstay_s1'; prevPE_s1_raw = prevPE_s1';
    newvarsS1 = [newvarsS1; swstay_s1 nannormalise(prevPE_s1') prevPE_s1_raw ...
                 repmat(is,length(prevPE_s1),1) repmat(faN(isub),length(prevPE_s1),1)];
end
validS1  = ~any(isnan(newvarsS1),2); newvarsS1 = newvarsS1(validS1,:);
switchS1 = newvarsS1(:,1); prevPE_S1 = newvarsS1(:,2); subS1 = newvarsS1(:,4); faS1 = newvarsS1(:,5);
tblS1    = table(switchS1, prevPE_S1, subS1, faS1);
lme_S1b  = fitglme(tblS1, 'switchS1~prevPE_S1*faS1+(1|subS1)', 'Distribution','binomial','Link','logit');
fprintf('  Model: switch ~ prevPE * OC + (1|subject)\n');
for ic = 1:height(lme_S1b.Coefficients)
    fprintf('  %-35s  coef=%9.5f  SE=%8.5f  p=%10.6f\n', ...
        lme_S1b.CoefficientNames{ic}, lme_S1b.Coefficients.Estimate(ic), ...
        lme_S1b.Coefficients.SE(ic), lme_S1b.Coefficients.pValue(ic));
end

fprintf('\n=== ALL MODELS DONE ===\n');
