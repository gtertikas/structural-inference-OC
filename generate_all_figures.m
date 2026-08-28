%% generate_all_figures.m
% Generates all paper figures for the OC structural inference paper.
% Figures formatted to Nature Human Behaviour specifications:
%   - Single column: 88 mm wide
%   - 1.5 column:   120 mm wide
%   - Double column: 180 mm wide
%   - Font: Arial, 7 pt (axis labels/ticks); 8 pt (axis titles)
%   - Line weight: 0.75 pt data lines, 0.5 pt reference lines
%   - Output: vector PDF (print quality independent of DPI)
%
% PREREQUISITES: run '/tmp/run_full_stats4.m' first so the full pipeline
% (readdat -> anadesc -> chgidx -> extract_all_stats -> strPE_inf_LMM)
% has executed and all variables are in the workspace.

cd('/Users/georgetertikas/Documents/Nadescha_code');
addpath(genpath('/Users/georgetertikas/Documents/Nadescha_code'));

outdir = '/Users/georgetertikas/Documents/Nadescha_code/figures';
if ~exist(outdir,'dir'), mkdir(outdir); end

% ── SHARED VARIABLES ──────────────────────────────────────────────────────
fa   = s.fa_sub.mat(:,3);            % raw OC factor scores
faN  = normalise(s.fa_sub.mat(:,3)); % normalised OC

swNr = NaN(1,length(s.subID));
for isub = 1:length(s.subID)
    swNr(isub) = s.sub{isub}.info.nrswitch(end);
    tmpFB = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');
    tmpFB(tmpFB==-1)=0;
    stimidx_tmp = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'stimidx');
    FBsub(isub)   = mean(tmpFB(stimidx_tmp==1));
    noFBsub(isub) = mean(tmpFB(stimidx_tmp==0));
end

% Pre/post MB performance (FB and noFB)
pre_s  = cell(length(s.subID),1);
post_s = cell(length(s.subID),1);
post2_s= cell(length(s.subID),1);
sim_s  = cell(length(s.subID),1);
for isub = 1:length(s.subID)
    showFB = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'allFB');
    swTr   = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
    nTr    = length(swTr);
    hididx=[]; a1=17; a2=20;
    while a2<nTr+5
        hididx=[hididx;a1 a2]; a1=a1+20; a2=a2+20;
    end
    if ~isempty(hididx), hididx(end,:)=[]; end
    dsc=sort(1:size(hididx,1),'descend');
    for i=1:length(dsc)
        showFB(hididx(dsc(i),1):min(hididx(dsc(i),2),nTr))=2;
    end
    swidx=find(swTr==1); swidx(1)=[]; swidx=swidx-1;
    MBl=20;
    prevec=NaN(nTr,1); postvec=NaN(nTr,1); post2vec=NaN(nTr,1);
    for i=1:length(swidx)
        lo=max(1,swidx(i)-MBl); hi1=min(nTr,swidx(i));
        prevec(lo:hi1)=i;
        hi2=min(nTr,swidx(i)+MBl);
        postvec(swidx(i):hi2)=i;
        lo2=min(nTr,swidx(i)+MBl); hi3=min(nTr,swidx(i)+MBl*2);
        post2vec(lo2:hi3)=i;
    end
    pre_s{isub}=prevec; post_s{isub}=postvec; post2_s{isub}=post2vec;
    sim_s{isub}=showFB(1:nTr);
end

FB3_sub=NaN(length(s.subID),3); noFB3_sub=NaN(length(s.subID),3);
for isub=1:length(s.subID)
    FB_raw=get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');
    FB_raw(FB_raw==-1)=0;
    curstim=sim_s{isub};
    preidx=find(~isnan(pre_s{isub})); postidx=find(~isnan(post_s{isub})); p2idx=find(~isnan(post2_s{isub}));
    FBidx=find(curstim==1); noFBidx=find(curstim==0);
    FB3_sub(isub,1)=nanmean(FB_raw(FBidx(ismember(FBidx,preidx))));
    FB3_sub(isub,2)=nanmean(FB_raw(FBidx(ismember(FBidx,postidx))));
    FB3_sub(isub,3)=nanmean(FB_raw(FBidx(ismember(FBidx,p2idx))));
    noFB3_sub(isub,1)=nanmean(FB_raw(noFBidx(ismember(noFBidx,preidx))));
    noFB3_sub(isub,2)=nanmean(FB_raw(noFBidx(ismember(noFBidx,postidx))));
    noFB3_sub(isub,3)=nanmean(FB_raw(noFBidx(ismember(noFBidx,p2idx))));
end

% Colours
col_FB   = [0.20 0.60 0.80];
col_noFB = [0.85 0.40 0.15];
col_low  = [0.40 0.65 0.90];
col_high = [0.85 0.25 0.25];
col_gen  = [0.55 0.35 0.15];   % brown  – general task effects
col_oc   = [0.20 0.60 0.25];   % green  – OC-related effects

% ══════════════════════════════════════════════════════════════════════════
%% FIGURE 2  –  Performance overview
% ══════════════════════════════════════════════════════════════════════════

%% Fig 2a  –  Overall performance (boxplot)
nhb_fig(88, 90);
FB_both = [FBsub' noFBsub'];
bxh = boxplot(FB_both,'Labels',{'FB','no-FB'},'Colors',[col_FB;col_noFB]);
set(bxh,'LineWidth',0.75);
yline(0.5,'--k','LineWidth',0.5);
ylim([0 1]);
ylabel('Performance (prop. correct)');
nhb_axes(gca);
savef('Fig2a_performance_boxplot', outdir);

%% Fig 2b  –  Histogram of structural changes
nhb_fig(88, 80);
histogram(swNr,1:7,'FaceColor',[0.5 0.5 0.5],'EdgeColor','w','FaceAlpha',0.85);
xlabel('Number of structural changes');
ylabel('Frequency');
nhb_axes(gca);
savef('Fig2b_switch_histogram', outdir);

%% Fig 2c  –  FB performance by # structural changes
nhb_fig(120, 90);
curFB=FBsub';
FB_bySwNr=NaN(length(curFB),6);
for i=1:6
    idx=find(swNr==i);
    FB_bySwNr(1:length(idx),i)=curFB(idx);
end
names={'SW1';'SW2';'SW3';'SW4';'SW5';'SW6'};
boxhist(FB_bySwNr, names, {'FB: performance'});
yline(0.5,'--k','LineWidth',0.5);
ylim([0 1]);
nhb_axes(gca);
savef('Fig2c_FB_by_switch', outdir);

%% Fig 2d  –  noFB performance by # structural changes
nhb_fig(120, 90);
curNoFB=noFBsub';
noFB_bySwNr=NaN(length(curNoFB),6);
for i=1:6
    idx=find(swNr==i);
    noFB_bySwNr(1:length(idx),i)=curNoFB(idx);
end
noFB_bySwNr(:,1)=NaN;
boxhist(noFB_bySwNr, names, {'no-FB: performance'});
yline(0.5,'--k','LineWidth',0.5);
ylim([0 1]);
nhb_axes(gca);
savef('Fig2d_noFB_by_switch', outdir);

%% Fig 2e  –  LME bar: noFBperf ~ FBperf (mean-centred, proportion)
subidx2e      = find(swNr>2);
FBp_cent      = FBsub(subidx2e)' - mean(FBsub(subidx2e));
noFBp_prop    = noFBsub(subidx2e)';
subID2e       = (1:length(subidx2e))';
tbl2e         = table(subID2e, FBp_cent, noFBp_prop);
lme_2e_fig    = fitlme(tbl2e,'noFBp_prop ~ FBp_cent + (1|subID2e)');

nhb_fig(88, 95);
fixE  = lme_2e_fig.fixedEffects;
SE    = lme_2e_fig.Coefficients.SE;
bh    = bar(1:2, fixE, 'FaceColor','flat','EdgeColor','none');
bh.CData(1,:) = [0.7 0.7 0.7];
bh.CData(2,:) = col_FB;
hold on;
errorbar(1:2, fixE, SE, SE, 'k.', 'LineWidth', 0.75, 'CapSize', 3);
yline(0,'k','LineWidth',0.4);
ylim([0 0.85]);
set(gca,'XTick',1:2,'XTickLabel',{'Intercept','FB trials: % correct'});
ylabel('no-FB trials performance effect size');
xtickangle(20);
nhb_axes(gca);
savef('Fig2e_LME_noFB_bar', outdir);

% ══════════════════════════════════════════════════════════════════════════
%% FIGURE 3  –  Transdiagnostic factor analysis
% ══════════════════════════════════════════════════════════════════════════
% Note: Fig 3a (loadings per factor) uses R output (see Rscripts/FAoutput/).
% Fig 3b (factor score distributions) also uses R output — see
% Rscripts/generate_fig3b_scores.R, output in figures/Fig3b_score_distributions.*
% MATLAB generates 3c (factor correlations).
%
% Fig 3b used to be a raw PCA scree plot (eigenvalues on 9 quest. totals,
% code kept below for reference). Reviewer flagged it: the bar chart on its
% own visually reads as "1 factor" (dominant PC1, gradual decline) with no
% statistic shown to justify the xline(3.5) cutoff. The actual justification
% for k=3 is the CNG (Zwick & Velicer) test, run separately in R on both the
% 209-item and the 22-subscale datasets — both select k=3. Report that as a
% Methods sentence instead of relying on the eyeball-scree read:
%   "A CNG test (Zwick & Velicer, 1986) confirmed 3 factors for both the
%    item-level and subscale-level solutions."
% Replaced the figure with the participant factor-score distributions
% (descriptive: shows real individual-differences spread on AD/OC/SU, not a
% statistical justification for k=3 — that's the CNG line above + Fig3c's
% factor intercorrelations, which show the 3 factors are separable).
%
% %% Fig 3b (OLD) – Scree plot (eigenvalues from PCA on quest. subscale totals)
% questmat = s.quest.tot;
% questmat = questmat - nanmean(questmat);
% questmat = questmat ./ nanstd(questmat);
% questmat(isnan(questmat)) = 0;
% C   = corr(questmat,'rows','complete');
% ev  = sort(eig(C),'descend');
%
% nhb_fig(88, 80);
% bar(1:length(ev), ev, 'FaceColor',[0.6 0.6 0.6],'EdgeColor','none');
% hold on; xline(3.5,'--k','LineWidth',0.5);
% xlabel('Factor number');
% ylabel('Eigenvalue');
% xlim([0.4 length(ev)+0.6]);
% nhb_axes(gca);
% savef('Fig3b_scree_plot', outdir);

%% Fig 3c  –  Spearman correlations between the 3 factors
nhb_fig(88, 80);
[hcor,~] = corr(s.fa_sub.mat,'Type','Spearman');
imagesc(hcor,[0 1]);
cb = colorbar; cb.FontSize = 7; cb.FontName = 'Arial';
set(gca,'XTick',1:3,'XTickLabel',{'AD';'SU';'OC score'});
set(gca,'YTick',1:3,'YTickLabel',{'AD';'SU';'OC score'});
nhb_axes(gca);
savef('Fig3c_factor_correlations', outdir);

% ══════════════════════════════════════════════════════════════════════════
%% FIGURE 4  –  Initial learning and comprehension
% ══════════════════════════════════════════════════════════════════════════

%% Fig 4a  –  OC vs initial (pre-change) performance
initPerf = NaN(length(s.subID),1);
for isub=1:length(s.subID)
    perfAll=[];
    for iphase=[4 5]
        try
            tmp=get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'FB_optchoice');
            tmp(tmp==-1)=0; perfAll=[perfAll;tmp];
        catch; end
    end
    FB6  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice'); FB6(FB6==-1)=0;
    swTr6= get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
    fsw  = find(swTr6==1,1);
    if ~isempty(fsw)&&fsw>1, perfAll=[perfAll;FB6(1:fsw-1)]; else, perfAll=[perfAll;FB6]; end
    if ~isempty(perfAll), initPerf(isub)=mean(perfAll); end
end

nhb_fig(88, 95);
x=fa; y=initPerf;
hax4a=scatterhist(x,y,'Location','NorthEast','Direction','out','Color','k','LineStyle',{'-'},'LineWidth',[0.75],'Marker','o','MarkerSize',[3]);
hold(hax4a(1),'on');
p_lin=polyfit(x(~isnan(y)),y(~isnan(y)),1);
xfit=linspace(min(x),max(x),100);
plot(hax4a(1),xfit,polyval(p_lin,xfit),'k-','LineWidth',0.75);
yline(hax4a(1),0.5,'--k','LineWidth',0.5);
nhb_axes(hax4a(1));
xlabel(hax4a(1),'OC score'); ylabel(hax4a(1),{'Performance before 1st change','(prop. correct)'});
[r4a,p4a]=corr(x,y,'Type','Spearman','rows','complete');
title(hax4a(1),sprintf('\\rho=%.3f, p=%.3f',r4a,p4a));
savef('Fig4a_OC_vs_initial_perf', outdir);

%% Fig 4b  –  OC vs comprehension question repetitions
nMC=8;
mc_reps=NaN(length(s.subID),1);
for isub=1:length(s.subID)
    mc_reps(isub)=numel(get_from_mat(s.sub{isub}.phase{2}.pmat,{'answer_correct'}))/nMC;
end

nhb_fig(88, 95);
x=fa; y=mc_reps;
hax4b=scatterhist(x,y,'Location','NorthEast','Direction','out','Color','k','LineStyle',{'-'},'LineWidth',[0.75],'Marker','o','MarkerSize',[3]);
hold(hax4b(1),'on');
p_lin=polyfit(x(~isnan(y)),y(~isnan(y)),1);
plot(hax4b(1),xfit,polyval(p_lin,xfit),'k-','LineWidth',0.75);
nhb_axes(hax4b(1));
xlabel(hax4b(1),'OC score'); ylabel(hax4b(1),'# comprehension repetitions');
[r4b,p4b]=corr(x,y,'Type','Spearman','rows','complete');
title(hax4b(1),sprintf('\\rho=%.3f, p=%.3f',r4b,p4b));
savef('Fig4b_OC_vs_MC_reps', outdir);

% ══════════════════════════════════════════════════════════════════════════
%% FIGURE 5  –  FB performance and ab-PE model
% ══════════════════════════════════════════════════════════════════════════

%% Fig 5a  –  OC vs # structural changes
nhb_fig(88, 88);
x=fa; y=swNr';
scatterhist(x,y,'Location','SouthEast','Direction','out','Color','k','LineStyle',{'-'},'LineWidth',[0.75],'Marker','o','MarkerSize',[3]);
hold on;
p_lin=polyfit(x,y,1); xfit=linspace(min(x),max(x),100);
plot(xfit,polyval(p_lin,xfit),'k-','LineWidth',0.75);
nhb_axes(gca);
xlabel('OC score'); ylabel('# structural changes');
[r5a,p5a]=corr(x,y,'Type','Spearman','rows','complete');
title(sprintf('\\rho=%.3f, p=%.3f',r5a,p5a));
savef('Fig5a_OC_vs_switches', outdir);

%% Fig 5b  –  FB performance pre/during/post change
nhb_fig(88, 88);
means_fb = nanmean(FB3_sub);
se_fb    = getnanSE(FB3_sub);
bar(1:3, means_fb, 'FaceColor', col_FB, 'EdgeColor','none'); hold on;
errbar(1:3, means_fb, se_fb, 'k');
yline(0.5,'--k','LineWidth',0.5);
ylim([0.4 1]);
set(gca,'XTick',1:3,'XTickLabel',{'MB t-1','MB t','MB t+1'});
ylabel('FB performance (prop. correct)');
nhb_axes(gca);
savef('Fig5b_FB_prepost_MB', outdir);

%% Fig 5c  –  OC vs FB performance at MB t+1
nhb_fig(88, 88);
x=fa; y=FB3_sub(:,3);
scatterhist(x,y,'Location','SouthEast','Direction','out','Color','k','LineStyle',{'-'},'LineWidth',[0.75],'Marker','o','MarkerSize',[3]);
hold on;
validIdx=~isnan(y);
p_lin=polyfit(x(validIdx),y(validIdx),1); xfit=linspace(min(x),max(x),100);
plot(xfit,polyval(p_lin,xfit),'k-','LineWidth',0.75);
yline(0.5,'--k','LineWidth',0.5);
nhb_axes(gca);
xlabel('OC score'); ylabel('FB performance MB t+1');
[r5c,p5c]=corr(x,y,'Type','Spearman','rows','complete');
title(sprintf('\\rho=%.3f, p=%.3f',r5c,p5c));
savef('Fig5c_OC_vs_FB_MBt1', outdir);

%% Fig 5d/e  –  GLMM bar: switch ~ ab-PE * OC  (MB t+1 only)
% Recompute model (already in workspace as lmelog_5 if extract_all_stats ran)
subidxAB=find(swNr>1); newvarsAB=[];
for is=1:length(subidxAB)
    isub=subidxAB(is);
    swTr  =get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
    accept=get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'accept');
    pairs =get_from_mat(s.sub{isub}.phase{6}.opt.pmat,{'opt_ID';'pred_ID'});
    FB_ab =get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice'); FB_ab(FB_ab==-1)=0;
    swidx=find(swTr==1);
    newMB=NaN(1,length(swTr));
    for i=1:length(swidx)
        hi1=min(swidx(i)+19,length(swTr)); hi2=min(swidx(i)+39,length(swTr));
        newMB(swidx(i):hi1)=1; newMB(swidx(i)+20:hi2)=2;
    end
    if length(newMB)>length(swTr), newMB=newMB(1:length(swTr)); end
    MBt1=find(newMB==2);
    newidx=[]; ia=1:4;
    while max(ia)<length(MBt1), newidx=[newidx ia]; ia=ia+20; end
    if isempty(newidx), continue; end
    MBt1_idx=MBt1(newidx); curch=accept(MBt1_idx);
    swstay=NaN(1,length(MBt1_idx)); prevPE=NaN(1,length(MBt1_idx));
    for i=1:length(MBt1_idx)
        cidx=MBt1_idx(i); pr=pairs(cidx,:);
        previdx=find(sum(ismember(pairs,pr)')==2); prtr_v=previdx(previdx<cidx);
        if isempty(prtr_v), continue; end
        prtr=prtr_v(end);
        swstay(i)=double(accept(prtr)~=curch(i)); prevPE(i)=1-FB_ab(prtr);
    end
    swstay=swstay'; prevPE=prevPE';
    newvarsAB=[newvarsAB; swstay nannormalise(prevPE) repmat(is,length(prevPE),1) repmat(faN(isub),length(prevPE),1)];
end
switchvarAB=newvarsAB(:,1); prevPEvarAB=newvarsAB(:,2); subvarAB=newvarsAB(:,3); favarAB=newvarsAB(:,4);
tblAB=table(switchvarAB,prevPEvarAB,subvarAB,favarAB);
lmelog_5_fig=fitglme(tblAB,'switchvarAB~prevPEvarAB*favarAB+(1|subvarAB)','Distribution','binomial','Link','logit');

nhb_fig(88, 95);
fixE5 = lmelog_5_fig.fixedEffects;
SE5   = lmelog_5_fig.Coefficients.SE;
bcolors5 = [col_gen; col_gen; col_oc; col_oc];
bh5=bar(1:4, fixE5, 'FaceColor','flat','EdgeColor','none'); hold on;
for i=1:4, bh5.CData(i,:)=bcolors5(i,:); end
errorbar(1:4, fixE5, SE5, SE5, 'k.', 'LineWidth',0.75, 'CapSize',3);
yline(0,'k','LineWidth',0.4);
set(gca,'XTick',1:4,'XTickLabel',{'Intercept','ab-PE','OC','ab-PE × OC'});
ylabel('log(switch)');
xtickangle(25);
nhb_axes(gca);
savef('Fig5de_GLMM_abPE_bar', outdir);

% ══════════════════════════════════════════════════════════════════════════
%% FIGURE 6  –  noFB inference and s-PE model
% ══════════════════════════════════════════════════════════════════════════

%% Fig 6a  –  Interaction: noFB performance × MBsinceSW × OC
% Compute per-subject MB performance for noFB trials
subidx6=find(swNr>1);
rawMBperf6=cell(length(s.subID),1);
rawMBsw6  =cell(length(s.subID),1);
for is=1:length(subidx6)
    isub6=subidx6(is);
    FB6a=get_from_mat(s.sub{isub6}.phase{6}.opt.pmat,'FB_optchoice'); FB6a(FB6a==-1)=0;
    SWopt=get_from_mat(s.sub{isub6}.phase{6}.opt.pmat,'confirmSwitch');
    a1=9; a2=16; prefMB=[]; tmp_MBsw=NaN(20,1); icount=1;
    while a2<length(FB6a)+5
        if a2==280, a2=276; end
        prefMB=[prefMB; mean(FB6a(a1:min(a2,end)))];
        if sum(SWopt(a1:min(a2,end)))>1, tmp_MBsw(icount+1)=1; end
        a1=a1+20; a2=a2+20; icount=icount+1;
    end
    tmp_MBsw(isnan(tmp_MBsw))=0;
    mbi=0; MBsw=[];
    for i=1:length(tmp_MBsw)
        if tmp_MBsw(i)==1, mbi=1; else, mbi=mbi+1; end
        MBsw(i)=mbi;
    end
    if length(MBsw)>1 && length(prefMB)>1
        MBsw(1)=[]; prefMB(1)=[];
        rawMBperf6{isub6}=prefMB;
        rawMBsw6{isub6}=MBsw';
    end
end

% Median split on OC
fa_med=median(faN(subidx6));
lo_idx=subidx6(faN(subidx6)<=fa_med);
hi_idx=subidx6(faN(subidx6)> fa_med);

maxMB=10;
perf_lo=NaN(length(lo_idx),maxMB);
perf_hi=NaN(length(hi_idx),maxMB);
for i=1:length(lo_idx)
    isub=lo_idx(i);
    if isempty(rawMBperf6{isub}), continue; end
    for mb=1:maxMB
        idx_mb=find(rawMBsw6{isub}==mb);
        if ~isempty(idx_mb), perf_lo(i,mb)=mean(rawMBperf6{isub}(idx_mb)); end
    end
end
for i=1:length(hi_idx)
    isub=hi_idx(i);
    if isempty(rawMBperf6{isub}), continue; end
    for mb=1:maxMB
        idx_mb=find(rawMBsw6{isub}==mb);
        if ~isempty(idx_mb), perf_hi(i,mb)=mean(rawMBperf6{isub}(idx_mb)); end
    end
end

m_lo=nanmean(perf_lo); se_lo=getnanSE(perf_lo);
m_hi=nanmean(perf_hi); se_hi=getnanSE(perf_hi);
validMB=sum(~isnan(perf_lo))>5;   % show MBs with >5 data points

nhb_fig(120, 90);
mbx=1:maxMB; mbx=mbx(validMB);
plt_lo=plot(mbx,m_lo(validMB),'-o','Color',col_low,'LineWidth',0.75,'MarkerFaceColor',col_low,'MarkerSize',3); hold on;
jbfill(mbx,m_lo(validMB)+se_lo(validMB),m_lo(validMB)-se_lo(validMB),col_low,col_low,0,0.2);
plt_hi=plot(mbx,m_hi(validMB),'-o','Color',col_high,'LineWidth',0.75,'MarkerFaceColor',col_high,'MarkerSize',3);
jbfill(mbx,m_hi(validMB)+se_hi(validMB),m_hi(validMB)-se_hi(validMB),col_high,col_high,0,0.2);
yline(0.5,'--k','LineWidth',0.5);
legend([plt_lo plt_hi],{'Low OC','High OC'},'Location','SouthEast','FontSize',7,'Box','off');
xlabel('MBs since structural change');
ylabel('no-FB performance (prop. correct)');
nhb_axes(gca);
savef('Fig6a_interaction_noFB_MBsinceSW', outdir);

%% Fig 6b  –  noFB performance pre/during/post change
nhb_fig(88, 88);
means_nfb=nanmean(noFB3_sub);
se_nfb   =getnanSE(noFB3_sub);
bar(1:3,means_nfb,'FaceColor',col_noFB,'EdgeColor','none'); hold on;
errbar(1:3,means_nfb,se_nfb,'k');
yline(0.5,'--k','LineWidth',0.5);
ylim([0.4 1]);
set(gca,'XTick',1:3,'XTickLabel',{'MB t-1','MB t','MB t+1'});
ylabel('no-FB performance (prop. correct)');
nhb_axes(gca);
savef('Fig6b_noFB_prepost_MB', outdir);

%% Fig 6c  –  OC vs noFB MB t+1
nhb_fig(88, 88);
x=fa; y=noFB3_sub(:,3);
scatterhist(x,y,'Location','SouthEast','Direction','out','Color','k','LineStyle',{'-'},'LineWidth',[0.75],'Marker','o','MarkerSize',[3]);
hold on;
validIdx=~isnan(y);
p_lin=polyfit(x(validIdx),y(validIdx),1); xfit=linspace(min(x),max(x),100);
plot(xfit,polyval(p_lin,xfit),'k-','LineWidth',0.75);
yline(0.5,'--k','LineWidth',0.5);
nhb_axes(gca);
xlabel('OC score'); ylabel('no-FB performance MB t+1');
[r6c,p6c]=corr(x,y,'Type','Spearman','rows','complete');
title(sprintf('\\rho=%.3f, p=%.3f',r6c,p6c));
savef('Fig6c_OC_vs_noFB_MBt1', outdir);

%% Fig 6e  –  GLMM bar: s-PE × OC  (lme_test1 from strPE_inf_LMM.m)
if exist('lme_test1','var')
    nhb_fig(88, 95);
    fixE6e = lme_test1.fixedEffects;
    SE6e   = lme_test1.Coefficients.SE;
    bcolors6e = [col_gen; col_gen; col_oc; col_oc];
    bh6e=bar(1:4,fixE6e,'FaceColor','flat','EdgeColor','none'); hold on;
    for i=1:4, bh6e.CData(i,:)=bcolors6e(i,:); end
    errorbar(1:4,fixE6e,SE6e,SE6e,'k.','LineWidth',0.75,'CapSize',3);
    yline(0,'k','LineWidth',0.4);
    set(gca,'XTick',1:4,'XTickLabel',{'Intercept','s-PE','OC','s-PE × OC'});
    ylabel('log(switch)');
    xtickangle(25);
    nhb_axes(gca);
    savef('Fig6e_GLMM_sPE_bar', outdir);
end

%% Fig 6f  –  GLMM bar: s-PE_change × OC (lme_test from strPE_inf_LMM.m)
if exist('lme_test','var')
    nhb_fig(88, 95);
    fixE6f = lme_test.fixedEffects;
    SE6f   = lme_test.Coefficients.SE;
    bcolors6f = [col_gen; col_oc; col_gen; col_oc];
    bh6f=bar(1:4,fixE6f,'FaceColor','flat','EdgeColor','none'); hold on;
    for i=1:4, bh6f.CData(i,:)=bcolors6f(i,:); end
    errorbar(1:4,fixE6f,SE6f,SE6f,'k.','LineWidth',0.75,'CapSize',3);
    yline(0,'k','LineWidth',0.4);
    cnames6f=lme_test.CoefficientNames;
    set(gca,'XTick',1:4,'XTickLabel',strrep(cnames6f,'norm_FB_sPE_change','s-PE_chg'));
    ylabel('log(switch)');
    xtickangle(30);
    nhb_axes(gca);
    savef('Fig6f_GLMM_sPE_change_bar', outdir);
end

% ══════════════════════════════════════════════════════════════════════════
%% SUPPLEMENTARY FIGURE 1  –  ab-PE model across all MBs
% ══════════════════════════════════════════════════════════════════════════

%% Supp Fig 1b  –  GLMM bar: switch ~ ab-PE × OC (all MBs)
subidxS1=find(swNr>1); newvarsS1=[];
for is=1:length(subidxS1)
    isub=subidxS1(is);
    swTr  =get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
    accept=get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'accept');
    pairs =get_from_mat(s.sub{isub}.phase{6}.opt.pmat,{'opt_ID';'pred_ID'});
    FB_s1 =get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice'); FB_s1(FB_s1==-1)=0;
    nTr=length(swTr);
    allMB_first=[]; ia=1:4;
    while max(ia)<=nTr, allMB_first=[allMB_first ia]; ia=ia+20; end
    allMB_first=allMB_first(allMB_first<=nTr);
    swstay_s1=NaN(1,length(allMB_first)); prevPE_s1=NaN(1,length(allMB_first));
    curch_s1=accept(allMB_first);
    for i=1:length(allMB_first)
        cidx=allMB_first(i); pr=pairs(cidx,:);
        previdx=find(sum(ismember(pairs,pr)')==2); prtr_v=previdx(previdx<cidx);
        if isempty(prtr_v), continue; end
        prtr=prtr_v(end);
        swstay_s1(i)=double(accept(prtr)~=curch_s1(i)); prevPE_s1(i)=1-FB_s1(prtr);
    end
    swstay_s1=swstay_s1'; prevPE_s1_raw=prevPE_s1';
    newvarsS1=[newvarsS1; swstay_s1 nannormalise(prevPE_s1') prevPE_s1_raw repmat(is,length(prevPE_s1),1) repmat(faN(isub),length(prevPE_s1),1)];
end
validS1=~any(isnan(newvarsS1),2); newvarsS1=newvarsS1(validS1,:);
switchS1=newvarsS1(:,1); prevPE_S1=newvarsS1(:,2); prevPEraw=newvarsS1(:,3);
subS1=newvarsS1(:,4); faS1=newvarsS1(:,5);
tblS1=table(switchS1,prevPE_S1,subS1,faS1);
lmelog_S1_fig=fitglme(tblS1,'switchS1~prevPE_S1*faS1+(1|subS1)','Distribution','binomial','Link','logit');

nhb_fig(88, 95);
fixES1  = lmelog_S1_fig.fixedEffects;
SESS1   = lmelog_S1_fig.Coefficients.SE;
bcolorsS1=[col_gen; col_gen; col_oc; col_oc];
bhS1=bar(1:4,fixES1,'FaceColor','flat','EdgeColor','none'); hold on;
for i=1:4, bhS1.CData(i,:)=bcolorsS1(i,:); end
errorbar(1:4,fixES1,SESS1,SESS1,'k.','LineWidth',0.75,'CapSize',3);
yline(0,'k','LineWidth',0.4);
set(gca,'XTick',1:4,'XTickLabel',{'Intercept','ab-PE','OC','ab-PE × OC'});
ylabel('log(switch)');
xtickangle(25);
nhb_axes(gca);
savef('SuppFig1b_GLMM_abPE_allMBs', outdir);

%% Supp Fig 1c  –  % switching vs OC, split by win/loss
subList_S1=unique(subS1);
sw_win_fig =NaN(length(subList_S1),1);
sw_loss_fig=NaN(length(subList_S1),1);
fa_S1c_fig =NaN(length(subList_S1),1);
for is=1:length(subList_S1)
    sidx=subS1==subList_S1(is);
    sw_win_fig(is) =100*nanmean(switchS1(sidx & prevPEraw==0));
    sw_loss_fig(is)=100*nanmean(switchS1(sidx & prevPEraw==1));
    fa_S1c_fig(is) =nanmean(faS1(sidx));
end

% Two stacked panels (88mm wide)
nhb_fig(88, 160);
subplot(2,1,1);
scatter(fa_S1c_fig, sw_win_fig, 10, [0.4 0.7 0.4],'filled','MarkerFaceAlpha',0.7); hold on;
validW=~isnan(sw_win_fig);
p_w=polyfit(fa_S1c_fig(validW),sw_win_fig(validW),1); xfit=linspace(min(fa_S1c_fig),max(fa_S1c_fig),100);
plot(xfit,polyval(p_w,xfit),'Color',[0.2 0.6 0.2],'LineWidth',0.75);
[rw,pw]=corr(fa_S1c_fig,sw_win_fig,'Type','Spearman','rows','complete');
xlabel('OC score'); ylabel('% switch (win)');
title(sprintf('Win: \\rho=%.3f, p=%.3f',rw,pw));
nhb_axes(gca);

subplot(2,1,2);
scatter(fa_S1c_fig, sw_loss_fig, 10, [0.8 0.4 0.2],'filled','MarkerFaceAlpha',0.7); hold on;
validL=~isnan(sw_loss_fig);
p_l=polyfit(fa_S1c_fig(validL),sw_loss_fig(validL),1);
plot(xfit,polyval(p_l,xfit),'Color',[0.7 0.2 0.1],'LineWidth',0.75);
[rl,pl]=corr(fa_S1c_fig,sw_loss_fig,'Type','Spearman','rows','complete');
xlabel('OC score'); ylabel('% switch (loss)');
title(sprintf('Loss: \\rho=%.3f, p=%.3f',rl,pl));
nhb_axes(gca);

savef('SuppFig1c_switch_win_loss', outdir);

% ══════════════════════════════════════════════════════════════════════════
fprintf('\n=== All figures saved to: %s ===\n', outdir);
fprintf('Files generated:\n');
d=dir(fullfile(outdir,'*.png'));
for i=1:length(d), fprintf('  %s\n',d(i).name); end

% ── LOCAL FUNCTIONS (must be at end of script) ─────────────────────────────
% Font sizing rationale: draft figures are 159mm wide.
% Worst-case panel is ~53mm (3-column layout, e.g. Fig 6).
% Panels rendered at 88mm scale down by 53/88 = 0.60.
% To achieve ≥7pt at final size: render at 7/0.60 = 11.7pt → use 12pt labels.
% To achieve ≥5pt at final size (NHB minimum): render at 5/0.60 = 8.3pt.

function fh = nhb_fig(w_mm, h_mm)
    % Figure sized at NHB panel width. PNG at 300 DPI:
    %   88mm → 1039 px,  120mm → 1417 px,  180mm → 2126 px
    fh = figure('Units','centimeters', 'Position',[1 1 w_mm/10 h_mm/10], ...
                'PaperUnits','centimeters', 'PaperSize',[w_mm/10 h_mm/10], ...
                'PaperPosition',[0 0 w_mm/10 h_mm/10], ...
                'Color','w');
    % Store desired size so savef can restore it (plotting functions may resize)
    fh.UserData = [w_mm h_mm];
end

function nhb_axes(ax)
    % 12pt axis labels, 11pt tick labels → ≥7pt after scale-down to final panel size
    set(ax, 'FontName','Arial', 'FontSize',11, ...
            'LineWidth',0.75, 'TickDir','out', 'TickLength',[0.02 0.02], ...
            'Box','off');
    ax.XLabel.FontSize = 12;
    ax.YLabel.FontSize = 12;
    if ~isempty(ax.Title.String)
        ax.Title.FontSize = 10;
        ax.Title.FontWeight = 'normal';
    end
    % Scale legend font if present
    leg = ax.Legend;
    if ~isempty(leg)
        leg.FontSize = 10;
    end
end

function savef(name, outdir)
    fh = gcf;
    % Restore exact NHB dimensions (plotting functions may have resized the figure)
    dims = fh.UserData;
    if ~isempty(dims) && isnumeric(dims) && numel(dims) == 2
        set(fh, 'Units','centimeters', ...
                'Position', [fh.Position(1) fh.Position(2) dims(1)/10 dims(2)/10]);
        fh.PaperUnits    = 'centimeters';
        fh.PaperSize     = [dims(1)/10 dims(2)/10];
        fh.PaperPosition = [0 0 dims(1)/10 dims(2)/10];
    end
    % exportgraphics: reliable 300 DPI PNG
    exportgraphics(fh, fullfile(outdir, [name '.png']), ...
                   'Resolution', 300, 'BackgroundColor', 'white');
    close(fh);
end
