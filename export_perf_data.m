%% export_perf_data.m
% Loads full N=313 dataset from raw Pavlovia files and exports:
%   FBsub_export.csv    – (N×1) overall FB performance per subject
%   FB_sub_export.csv   – (N×3) FB performance pre/during/post structural change
%   noFB_sub_export.csv – (N×3) no-FB performance pre/during/post structural change
%   swNr_export.csv     – (N×1) number of structural changes per subject

clc;
base = '/Users/georgetertikas/Documents/Nadescha_code';
cd(base);
addpath(genpath(base));

fprintf('Loading raw data...\n');
s = [];
pilotID = 7;
choice4 = 0;
s = readdat(s, pilotID);
fprintf('  N=%d subjects loaded\n', length(s.subID));

fprintf('Setting up data...\n');
s = setrelev(s);
for is = 1:length(s.subID)
    s = formatdat(s, is, choice4);
end
for is = 1:length(s.subID)
    s = checkdat(s, is, choice4);
end
s = getpmat(s);
s = loadQuest(s, 0);
s = anadesc(s, [0 0 0]);   % adds trueSwitch to pmat

fprintf('Computing FBsub (overall FB performance)...\n');
FBsub = NaN(length(s.subID), 1);
swNr  = NaN(length(s.subID), 1);
for isub = 1:length(s.subID)
    swNr(isub) = s.sub{isub}.info.nrswitch(end);
    tmpFB = get_from_mat(s.sub{isub}.phase{6}.opt.pmat, 'FB_optchoice');
    tmpFB(tmpFB == -1) = 0;
    FBsub(isub) = mean(tmpFB);
end

fprintf('Computing FB_sub / noFB_sub (pre/post switch performance)...\n');
pre_sub   = [];
post_sub  = [];
post2_sub = [];
simidx_sub = [];

for isub = 1:length(s.subID)
    FB     = get_from_mat(s.sub{isub}.phase{6}.opt.pmat, 'FB_optchoice'); FB(FB==-1)=0;
    showFB = get_from_mat(s.sub{isub}.phase{6}.opt.pmat, 'allFB');
    swTr   = get_from_mat(s.sub{isub}.phase{6}.opt.pmat, 'trueSwitch');

    hididx=[]; a1=17; a2=20;
    while a2 < length(FB)+5
        hididx=[hididx; a1 a2];
        a1=a1+20; a2=a2+20;
    end
    hididx(end,:)=[];
    descidx = sort(1:length(hididx),'descend');
    for i=1:length(hididx)
        showFB(hididx(descidx(i),1):hididx(descidx(i),2))=2;
    end

    swidx = find(swTr==1); swidx(1)=[]; swidx=swidx-1;

    prevec   = NaN(length(showFB),1);
    postvec  = NaN(length(showFB),1);
    post2vec = NaN(length(showFB),1);

    if length(swidx)>0
        MBl=20;
        for i=1:length(swidx)
            prevec(swidx(i)-MBl:swidx(i))       = i;
            postvec(swidx(i):swidx(i)+MBl)       = i;
            post2vec(swidx(i)+MBl:swidx(i)+MBl*2)= i;
        end
        prevec   = prevec(1:length(swTr));
        postvec  = postvec(1:length(swTr));
        post2vec = post2vec(1:length(swTr));
    end

    pre_sub(:,isub)    = prevec;
    post_sub(:,isub)   = postvec;
    post2_sub(:,isub)  = post2vec;
    simidx_sub(:,isub) = showFB;
end

FB_sub   = NaN(length(s.subID),3);
noFB_sub = NaN(length(s.subID),3);

for isub = 1:length(s.subID)
    FB     = get_from_mat(s.sub{isub}.phase{6}.opt.pmat, 'FB_optchoice'); FB(FB==-1)=0;
    curstim = simidx_sub(:,isub);

    preidx   = find(~isnan(pre_sub(:,isub)));
    postidx  = find(~isnan(post_sub(:,isub)));
    post2idx = find(~isnan(post2_sub(:,isub)));

    FBidx = find(curstim==1);
    FB_sub(isub,1) = mean(FB(FBidx(ismember(FBidx,preidx))));
    FB_sub(isub,2) = mean(FB(FBidx(ismember(FBidx,postidx))));
    FB_sub(isub,3) = mean(FB(FBidx(ismember(FBidx,post2idx))));

    noFBidx = find(curstim==0);
    noFB_sub(isub,1) = mean(FB(noFBidx(ismember(noFBidx,preidx))));
    noFB_sub(isub,2) = mean(FB(noFBidx(ismember(noFBidx,postidx))));
    noFB_sub(isub,3) = mean(FB(noFBidx(ismember(noFBidx,post2idx))));
end

% Also export per-subject FB-only and noFB-only performance (for LME in Fig1e)
FBperf_only   = NaN(length(s.subID), 1);
noFBperf_only = NaN(length(s.subID), 1);
for isub = 1:length(s.subID)
    tmpFB   = get_from_mat(s.sub{isub}.phase{6}.opt.pmat, 'FB_optchoice');
    tmpFB(tmpFB == -1) = 0;
    stimidx = get_from_mat(s.sub{isub}.phase{6}.opt.pmat, 'stimidx');
    FBperf_only(isub)   = mean(tmpFB(stimidx == 1));
    noFBperf_only(isub) = mean(tmpFB(stimidx == 0));
end

fprintf('Computing mc_reps (comprehension repetitions)...\n');
mc_reps = NaN(length(s.subID), 1);
nMC = 8;
for isub = 1:length(s.subID)
    try
        mc_reps(isub) = numel(get_from_mat(s.sub{isub}.phase{2}.pmat, {'answer_correct'})) / nMC;
    catch
    end
end

fprintf('Exporting CSVs...\n');
writematrix(FBsub,          fullfile(base, 'FBsub_export.csv'));
writematrix(FB_sub,         fullfile(base, 'FB_sub_export.csv'));
writematrix(noFB_sub,       fullfile(base, 'noFB_sub_export.csv'));
writematrix(swNr,           fullfile(base, 'swNr_export.csv'));
writematrix(FBperf_only,    fullfile(base, 'FBperf_export.csv'));
writematrix(noFBperf_only,  fullfile(base, 'noFBperf_export.csv'));
writematrix(mc_reps,        fullfile(base, 'mcreps_export.csv'));

fprintf('Done. N=%d subjects exported.\n', length(s.subID));
fprintf('  FBsub range:      [%.3f, %.3f]\n', min(FBsub), max(FBsub));
fprintf('  FB-only mean:     %.3f\n', nanmean(FBperf_only));
fprintf('  noFB-only mean:   %.3f\n', nanmean(noFBperf_only));
fprintf('  FB_sub cols:      pre=%.3f, post=%.3f, post2=%.3f\n', ...
    nanmean(FB_sub(:,1)), nanmean(FB_sub(:,2)), nanmean(FB_sub(:,3)));

% Export initial performance (practice phases + pre-first-switch in phase 6)
initPerf = NaN(length(s.subID), 1);
for isub = 1:length(s.subID)
    perfAll = [];
    for iphase = [4 5]
        try
            tmpFB = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'FB_optchoice');
            tmpFB(tmpFB == -1) = 0;
            perfAll = [perfAll; tmpFB];
        catch, end
    end
    FB6  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');
    FB6(FB6 == -1) = 0;
    swTr = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
    firstSw = find(swTr == 1, 1);
    if ~isempty(firstSw) && firstSw > 1
        perfAll = [perfAll; FB6(1:firstSw-1)];
    else
        perfAll = [perfAll; FB6];
    end
    if ~isempty(perfAll), initPerf(isub) = mean(perfAll); end
end
writematrix(initPerf, fullfile(base, 'initPerf_export.csv'));
fprintf('Exported initPerf_export.csv  (mean=%.3f, SD=%.3f)\n', nanmean(initPerf), nanstd(initPerf));
