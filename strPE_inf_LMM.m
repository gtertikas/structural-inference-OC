%% integration of structural PE on inference trials
% LMM to predict switch/stay on noFB trials given 
% structural PE on FB trials 
% chg/ no chg on noFB trials 
% interaction
% and specific to FA

fa   = normalise(s.fa_sub.mat(:,3));
icar = normalise(s.quest.tot(:,2));


for isub = 1:length(s.subID)
    swNr(isub) = s.sub{isub}.info.nrswitch(end);
    tmpFB= get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');tmpFB(find(tmpFB==-1))=0;
    FBsub(isub) = mean(tmpFB);

end
% only for those subs
subidx = find(swNr>1);
    swst_noFB= NaN(4,length(subidx));
saveall=[];
%%
allvars=[];sPE_sub=[];beta=[];
for is = 1:length(subidx)
    
    isub = subidx(is);
    
    % get structural PE = PE on all FB trials in the MB
    accept  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'accept');
    FB      = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');FB(find(FB==-1))=0;
    chgidx  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'chgidx');
    stimidx = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'stimidx');
    order   = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,{'opt_ID';'pred_ID'});
    swTr = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');

    % --- structure PE:
    MBidx = 1:20:length(stimidx);
    MBidx(end+1) = length(stimidx);
    sPE=[];sPE_change=[];sPE_NOchange=[];FB_chgcomb=[];save_FBchgidx=[];
    i=1;
    while i<length(MBidx)
        curidx = MBidx(i):MBidx(i+1)-1;
        FBidx = curidx(find(stimidx(curidx)==1)); % FB only
       
        % only for chg/ nochg trials: 
        FBchgidx   = FBidx(find(chgidx(FBidx)==1));
        FBnochgidx = FBidx(find(chgidx(FBidx)==0));
        
        sPE = [sPE; 1- mean(FB(FBidx))]; % !!!! it is 1 minus because we want to look at the PE ! so the higher the value, the higher the PE otherwise it would be reward 
        sPE_change = [sPE_change; 1- mean(FB(FBchgidx))];
        sPE_NOchange = [sPE_NOchange; 1- mean(FB(FBnochgidx))];
        i=i+1;
        
        save_FBchgidx = [save_FBchgidx; FBchgidx' ]; % save index to check later whether they were switches or not
    end
      sPE_sub(:,is) = sPE;
    % adjust the length:
    chnr = 4*2; % to fit length of noFB
    FB_sPE=[];FB_sPE_NOchange=[];FB_sPE_change=[];
    for i =1:length(sPE)
        FB_sPE = [FB_sPE; repmat(sPE(i), chnr,1)];
        FB_sPE_change = [FB_sPE_change; repmat(sPE_change(i), chnr,1)];
        FB_sPE_NOchange = [FB_sPE_NOchange; repmat(sPE_NOchange(i), chnr,1)];
    end
        
    stdCHG(is) = nanstd(FB_sPE_change);
    stdnoCHG(is) = nanstd(FB_sPE_NOchange);
    
    
    
    
    % --- noFB trials:
    % chg/nochg
    % switch: yes/no
    
    
    % switch variable:
    % find previous pair
    stayswitch = NaN(length(accept),1);prevFB_pair= NaN(length(accept),1);
    startsw=find(swTr); 
    
    for io = startsw(1):length(order) % start after first MB/// start after 2nd switch
        curor = order(io,:);
        curch = accept(io);
        
        idx = find(sum(ismember(order,curor)')==2);
        
        prevtr = idx(find(idx<io));
        if prevtr>0
            picktr = prevtr(end); % most recent trial
            
            prevch = accept(picktr);
            
            if prevch == curch % stay
                stayswitch(io) = 0;
            else % switch
                stayswitch(io) = 1;
            end
            
            prevFB_pair(io) = FB(picktr);
            
        end
        
    end
    
       
    % --- switch/ stay per sPE 
        
    % quick divergence ////
    noFB_stayswitch=[];
    noFB_stayswitch = stayswitch(find(stimidx==0));
    unnr = [0 0.125 0.25 0.375 0.5 0.625 0.75 0.875 1];
    
    cats = [0 0.125;
        0.25 0.375;
        0.5 0.625;
        0.75 1];
    
    
    for ic = 1:length(cats)
        curidx = [];
        curcat = cats(ic,:);
        for icheck = 1:length(FB_sPE)
            
            if FB_sPE(icheck)>=curcat(1) && FB_sPE(icheck)<=curcat(2)
                
                curidx = [curidx; icheck];
                
            end
            
            
        end
        if length(curidx)>0
            swst_noFB(ic,is) = nanmean(noFB_stayswitch(curidx));
        else
            swst_noFB(ic,is) = NaN;
        end
    end
    
    
    % MB count    
        
    
    
    
    
    
    
    
    % --- variables
    stayswitch_sub(:,is) = stayswitch;
    curnoFB(is) = nanmean(FB(stimidx==0));
    curFB(is) = nanmean(FB(stimidx==1));
    curFBhid(is) = nanmean(FB(stimidx==2));
    curfa(is) = fa(isub);
    
    
    
    
    % onky for no FB
    noFBsw_ch = stayswitch(stimidx==0); % choice specific to previous, whether change response
    noFBchgstim = chgidx(stimidx==0); % choice specific whether something has changed
    noFB_pair = 1- prevFB_pair(stimidx==0); % this is technically not shown to them
    % normalise regressors:
    norm_FB_sPE = nannormalise(FB_sPE);
    norm_noFBchgstim = nannormalise(noFBchgstim);
    norm_noFB_pair   = nannormalise(noFB_pair);
    
    FAsub = repmat(fa(isub),length(noFBsw_ch),1);
    subID = repmat(isub,length(noFBsw_ch),1);
    
    icarsub =repmat(icar(isub),length(noFBsw_ch),1); 
    
    norm_FB_sPE_change      = nannormalise(FB_sPE_change);
    norm_FB_sPE_NOchange    = nannormalise(FB_sPE_NOchange);
    
    % logistic regression
    
    beta(is,:)= glmfit([norm_FB_sPE],noFBsw_ch, 'binomial','link','logit');
    
    
    allvars = [allvars; noFBsw_ch norm_FB_sPE norm_noFBchgstim FAsub subID norm_noFB_pair icarsub norm_FB_sPE_change norm_FB_sPE_NOchange];
    
end



%% set up linear mixed model


im = 1;

noFBsw_ch           = allvars(:,im); im = im+1;
norm_FB_sPE         = allvars(:,im); im = im+1;
norm_noFBchgstim    = allvars(:,im); im = im+1;
FAsub               = allvars(:,im); im = im+1;
subID               = allvars(:,im); im = im+1;
norm_noFB_pair      = allvars(:,im); im = im+1;
icarsub             = allvars(:,im); im = im+1;
norm_FB_sPE_change     = allvars(:,im); im = im+1;
norm_FB_sPE_NOchange   = allvars(:,im); im = im+1;

tbl = table(noFBsw_ch,norm_FB_sPE,norm_noFBchgstim,FAsub,subID,norm_noFB_pair,icarsub,norm_FB_sPE_change,norm_FB_sPE_NOchange);

lmeMlog   = fitglme(tbl,  'noFBsw_ch~norm_FB_sPE*norm_noFBchgstim*FAsub+(1|subID)', 'Distribution', 'binomial','Link','logit');
lmeMlog_icar   = fitglme(tbl,  'noFBsw_ch~norm_FB_sPE*norm_noFBchgstim*FAsub+icarsub+(1|subID)', 'Distribution', 'binomial','Link','logit');
lmeMlogM3 = fitglme(tbl,  'noFBsw_ch~norm_FB_sPE*norm_noFBchgstim*FAsub+norm_noFB_pair+(1|subID)', 'Distribution', 'binomial','Link','logit');
compare(lmeMlogM3,lmeMlogM3)
    
figure

orderidx = [1 2 3 5 4 6 7 8];
SE      = lmeMlog.Coefficients.SE; SE=[SE -SE]; SE = SE(orderidx,:);
fixE    = lmeMlog.fixedEffects;fixE=fixE(orderidx);
names   =  {'constant';'FB_sPE';'noFBchgstim';'FAsub';'FB_sPE:noFBchgstim';'FB_sPE:FAsub';'noFBchgstim:FAsub';...
     'FB_sPE:noFBchgstim:FAsub'};
names = names(orderidx);
bar(1:length(fixE),fixE );hold all;
for i = 1:length(orderidx)
errorbar(i,fixE(i), SE(i,1), SE(i,2),'k' );hold all;
end
set_default_fig_properties(gca,gcf);hold all;
ylabel('log(switch) ')
set(gca,'XTick',1:length(fixE));
set(gca,'XTickLabel',  names,'FontSize',14);
xtickangle(30)


% plot only the FA related thing
figure

%orderidx = [ 4 6 7 8]; % FA
orderidx = [1 2 4]; % others
SE      = lmeMlog.Coefficients.SE; SE=[SE -SE]; SE = SE(orderidx,:);
fixE    = lmeMlog.fixedEffects;fixE=fixE(orderidx);
names   =  lmeMlog.CoefficientNames;names (1)=[];

%names = names(orderidx);
bar(1:length(fixE),fixE );hold all;
for i = 1:length(orderidx)
errorbar(i,fixE(i), SE(i,1), SE(i,2),'k' );hold all;
end
set_default_fig_properties(gca,gcf);hold all;
ylabel('log(switch) ')
set(gca,'XTick',1:length(fixE));
set(gca,'XTickLabel',  names(orderidx),'FontSize',14);
xtickangle(30)



% other analysis:
lme_test1   = fitglme(tbl,  'noFBsw_ch~norm_FB_sPE*FAsub+(1|subID)', 'Distribution', 'binomial','Link','logit');

lme_test   = fitglme(tbl,  'noFBsw_ch~norm_FB_sPE_change*FAsub +(1|subID)', 'Distribution', 'binomial','Link','logit');




% without fa
lme_wFA   = fitglme(tbl,  'noFBsw_ch~norm_FB_sPE+(norm_FB_sPE|subID)', 'Distribution', 'binomial','Link','logit');
randomef = lme_wFA.randomEffects;
FBsPE_rand = randomef(2:2:end);

figure
SE      = lme_test1.Coefficients.SE; SE=[SE -SE]; 
fixE    = lme_test1.fixedEffects;
names   =   lme_test1.CoefficientNames;
bar(1:length(fixE),fixE );hold all;
for i = 1:length(names)
errorbar(i,fixE(i), SE(i,1), SE(i,2),'k' );hold all;
end
set_default_fig_properties(gca,gcf);hold all;
ylabel('log(switch) ')
set(gca,'XTick',1:length(fixE));
set(gca,'XTickLabel',  names,'FontSize',14);
xtickangle(30)


figure

SE      = lme_test.Coefficients.SE; SE=[SE -SE]; 
fixE    = lme_test.fixedEffects;
names   =   lme_test.CoefficientNames;
orderidx = 3:length(names);

bar(1:length(fixE(orderidx)),fixE(orderidx) );hold all;
for i = 1:length(orderidx)
errorbar(i,fixE(orderidx(i)), SE(orderidx(i),1), SE(orderidx(i),2),'k' );hold all;
end
set_default_fig_properties(gca,gcf);hold all;
ylabel('log(switch) ')
set(gca,'XTick',1:length(orderidx));
set(gca,'XTickLabel',  names(orderidx),'FontSize',14);
xtickangle(30)











% descriptive display:

noFb_cat = [nanmean(swst_noFB(1:2,:))' nanmean(swst_noFB(3:4,:))' nanmean(swst_noFB(5:6,:))' nanmean(swst_noFB(7:8,:))'];











%%
%%
%% integration of structural PE on switch/stay on FB trials 
% 


% need structural PE from previous MB 
% choice-specific changes
% chg/nochg idx



subidx_FB = find(swNr>1); % here might want to take all subs
FBallvars=[];sPE_sub=[];FBallvars_adj=[];
pairPE_cat = NaN(8,length(subidx_FB));
swst_cat= NaN(8,length(subidx_FB));
for is = 1:length(subidx_FB)
    
    isub = subidx_FB(is);
    
   
    % 
    accept  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'accept');
    FB      = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');FB(find(FB==-1))=0;
    chgidx  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'chgidx');
    stimidx = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'stimidx');
    order   = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,{'opt_ID';'pred_ID'});
    swTr = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
    tmpMBcount = 1:20:length(swTr);
    
    newMBcount=[];
    for i = 1:length(tmpMBcount)
        newMBcount = [newMBcount; repmat(i,20,1)];
        
        
    end
    newMBcount= newMBcount(1:length(swTr));
    
    
    
    % ---> switch variable:
    % find previous pair
    stayswitch = NaN(length(accept),1); FB_prevch = NaN(length(accept),1);
    startsw=find(swTr); 
    
    for io = startsw(1):length(order) % start after first MB/// start after 2nd switch
        curor = order(io,:);
        curch = accept(io);
        
        idx = find(sum(ismember(order,curor)')==2);
        
        prevtr = idx(find(idx<io));
        
        
        
        if prevtr>0
            
            %
            picktr = prevtr(end); % most recent trial
            
            prevch = accept(picktr);
            
            if prevch == curch % stay
                stayswitch(io) = 0;
            else % switch
                stayswitch(io) = 1;
            end
            
             % win/loss at previous trial = MF trial
            FB_prevch(io) = FB(picktr);
            
            
        end
        
    end
    
    % index FB trials but just the first 4 within a MB:
    fbidx = find(stimidx==1);
    %a1=5; a2=8;
    a1=1; a2=4;
    fbidx_new=[];
    while a2 < length(fbidx)
        newidx = (a1:a2);
        fbidx_new = [fbidx_new; newidx'];
        a1=a1+8;
        a2=a2+8;
    end
    
    
    % ---> stayswitch on FB
    FB_stayswitch = stayswitch(stimidx==1);
    FBchgstim     = chgidx(stimidx==1);
    FB_prevch_ex  = FB_prevch(stimidx==1);
    
    % sPE for FB trials
    MBidx = 1:20:length(stimidx);
    MBidx(end+1) = length(stimidx);
    sPE=[];
    i=1;
    FBidx=[];
    while i<length(MBidx)
        curidx = MBidx(i):MBidx(i+1)-1;
        %taking all the FB trials
        FBidx = curidx(find(stimidx(curidx)==1)); 
        
        noFBidx = curidx(find(stimidx(curidx)==0)); % taking the NO FB Trials
        sPE = [sPE; 1- mean(FB(FBidx))]; % !!!! it is 1 minus because we want to look at the PE ! so the higher the value, the higher the PE otherwise it would be reward 
      
        i=i+1;
    end
    sPE_sub(:,is) = sPE;
    % take the previous sPE and not the current MB (this is a difference to the previous analysis for noFB trials):
    sPE_FB=[];
    sPE_FB = sPE; sPE_FB(end)=[]; sPE_FB = [NaN; sPE_FB];

    % adjust the length:
    chnr = 4*2; % to fit length of noFB
    FB_sPE=[];
    for i =1:length(sPE_FB)
        FB_sPE = [FB_sPE; repmat(sPE_FB(i), chnr,1)];
        
    end
    
    % adjust vars:
     % normalise regressors:
     FB_stayswitch_adj = FB_stayswitch(fbidx_new);
    norm_FB_t1_sPE_adj = nannormalise(FB_sPE(fbidx_new));

    
    
    % pair PE: first reverse
    FB_prevch_ex = 1-FB_prevch_ex;
  
    r = corrcoef(FB_sPE(fbidx_new), FB_prevch_ex(fbidx_new),'rows','complete');
    rsub(isub) = r(2);
    
    
    
    
    
    
    % quick divergence ////
    newvar1=[];newvar2=[];
    newvar1 = FB_sPE(fbidx_new);
    newvar2 = FB_prevch_ex(fbidx_new);
    newvar3 = FB_stayswitch(fbidx_new);
    unnr = [0 0.125 0.25 0.5 0.625 0.75 0.875 1];
    
    
    for iu = 1:length(unnr)
        curidx = [];
        curidx = find(newvar1==unnr(iu));
        if length(curidx)>0
        pairPE_cat(iu,is) = nanmean(newvar2(curidx));  
        swst_cat(iu,is) = nanmean(newvar3(curidx));  
        end
    end
    
    sw_noPE(is) = nanmean(FB_stayswitch(find(FB_prevch_ex==0)));
    sw_PE(is) = nanmean(FB_stayswitch(find(FB_prevch_ex==1)));
    
    
  % ////// 
    FB_prevch_ex_adj    = nannormalise(FB_prevch_ex(fbidx_new));
    newMBcount_adj = nannormalise(newMBcount(fbidx_new));
    FAsub_adj =[];subID_adj =[];
    FAsub_adj  = repmat(fa(isub),length((fbidx_new)),1);
    subID_adj  = repmat(isub,length((fbidx_new)),1);
    
     % normalise regressors:
    norm_FB_t1_sPE = nannormalise(FB_sPE);
    norm_FBchgstim = nannormalise(FBchgstim);
    norm_FB_prevch_ex = nannormalise(FB_prevch_ex);
    FAsub=[];subID=[];
    FAsub = repmat(fa(isub),length(norm_FB_t1_sPE),1);
    subID = repmat(isub,length(norm_FB_t1_sPE),1);
    
    icarsub = repmat(icar(isub),length(norm_FB_t1_sPE),1);
    icarsub_adj =repmat(icar(isub),length((fbidx_new)),1);
    
    % logistic regression
    
    %beta(isub,:)= glmfit([norm_FB_sPE,norm_noFBchgstim],noFBsw_ch, 'binomial','link','logit');
    
    
    FBallvars = [FBallvars; FB_stayswitch norm_FB_t1_sPE norm_FBchgstim FAsub subID norm_FB_prevch_ex];
    FBallvars_adj = [FBallvars_adj; FB_stayswitch_adj norm_FB_t1_sPE_adj  FAsub_adj ...
        subID_adj FB_prevch_ex_adj newMBcount_adj icarsub_adj ];
    
     % logistic regression
    
  %  FBbeta(is,:)= glmfit([norm_FB_t1_sPE_adj],noFBsw_ch, 'binomial','link','logit');
    
    
end


%% set up logistic mixed model

% -- all Fb trials:
% im = 1;
% FAsub=[];subID=[];
% FB_stayswitch       = FBallvars(:,im); im = im+1;
% norm_FB_t1_sPE      = FBallvars(:,im); im = im+1;
% norm_FBchgstim      = FBallvars(:,im); im = im+1;
% FAsub               = FBallvars(:,im); im = im+1;
% subID               = FBallvars(:,im); im = im+1;
% 
% tbl_FB = table(FB_stayswitch,norm_FB_t1_sPE,norm_FBchgstim,FAsub,subID);
% 
% FB_lmeM = fitlme(tbl_FB,'FB_stayswitch~norm_FB_t1_sPE*norm_FBchgstim*FAsub+(1|subID)')


% -- adjusted: only predict first FB MB 
im = 1;
FAsub=[];subID=[];
FB_stayswitch       = FBallvars_adj(:,im); im = im+1;   
norm_FB_t1_sPE      = FBallvars_adj(:,im); im = im+1;
FAsub               = FBallvars_adj(:,im); im = im+1;
subID               = FBallvars_adj(:,im); im = im+1;
norm_FB_t1_pairPE   = FBallvars_adj(:,im); im = im+1;
norm_MBcount        = FBallvars_adj(:,im); im = im+1;
icar                = FBallvars_adj(:,im); im = im+1;


tbl_FB_adj=[];
tbl_FB_adj = table(FB_stayswitch,norm_FB_t1_sPE,norm_FB_t1_pairPE,FAsub,subID,norm_MBcount,icar);


% log function:
% PE

FBm1logM2 = fitglme(tbl_FB_adj,  'FB_stayswitch~norm_FB_t1_pairPE*FAsub+(1|subID)', 'Distribution', 'binomial','Link','logit');
FBm1logM2_icar = fitglme(tbl_FB_adj,  'FB_stayswitch~norm_FB_t1_pairPE*FAsub+icar+(1|subID)', 'Distribution', 'binomial','Link','logit');

FBm1logM2 = fitglme(tbl_FB_adj,  'FB_stayswitch~norm_FB_t1_pairPE*FAsub+norm_FB_t1_sPE*FAsub+(1|subID)', 'Distribution', 'binomial','Link','logit');


% make sure that the effect does not come about because of possible
% correlation between PE and sPE
FBm1logM3 = fitglme(tbl_FB_adj,  'FB_stayswitch~norm_FB_t1_pairPE*FAsub+(1|subID)', 'Distribution', 'binomial','Link','logit');
% chg/no chg
FBm2log = fitglme(tbl_FB_adj,  'FB_stayswitch~norm_FBchgstim*norm_FB_t1_sPE*FAsub+(1|subID)', 'Distribution', 'binomial','Link','logit');


%% figure 


figure

%orderidx = 4:6; % FA
%orderidx = [1 3 2]; % no FA info
SE=[];fixE=[];names=[];
SE      = FBm1logM2.Coefficients.SE; SE=[SE -SE];
fixE    = FBm1logM2.fixedEffects;
names   =   FBm1logM2.CoefficientNames;

bar(1:length(names),fixE );hold all;
for i = 1:length(names)
errorbar(i,fixE(i), SE(i,1), SE(i,2),'k' );hold all;
end
set_default_fig_properties(gca,gcf);hold all;
ylabel('log(switch) ')
set(gca,'XTick',1:length(names));
set(gca,'XTickLabel',  names,'FontSize',14);
xtickangle(30)





























%% descriptive analyses


FB_sw=[];
noFB_sw=[];
for isub = 1:length(s.subID)
    
    stimidx = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'stimidx');
    accept  = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'accept');
    RT= get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'choice_resp_2_rt');
    
    % find previous pair
    stayswitch = NaN(length(accept),1);
    startsw=find(swTr);
    
    for io = startsw(1):length(order) % start after first MB/// start after 2nd switch
        curor = order(io,:);
        curch = accept(io);
        
        idx = find(sum(ismember(order,curor)')==2);
        
        prevtr = idx(find(idx<io));
        if prevtr>0
            picktr = prevtr(end); % most recent trial
            
            prevch = accept(picktr);
            
            if prevch == curch % stay
                stayswitch(io) = 0;
            else % switch
                stayswitch(io) = 1;
            end
        end
        
    end
    mean_RT(isub) = nanmean(RT);
    RT_FB(isub,:) = nanmean(RT(find(stimidx==0)));
    RT_noFB(isub,:) = nanmean(RT(find(stimidx==1)));
    noFB_sw(isub,:) = nanmean(stayswitch(find(stimidx==0)));
    FB_sw(isub,:) = nanmean(stayswitch(find(stimidx==1)));
    
end




%% plot pairPE per sPE

newfa  =fa(subidx_FB);
upfa= find(newfa>median(newfa));
lowfa= find(newfa<median(newfa));


    
% 
newpairPE_cat = [nanmean(pairPE_cat(1:2,:))' nanmean(pairPE_cat(3:4,:))' nanmean(pairPE_cat(5:6,:))' nanmean(pairPE_cat(7:8,:))'];
newswst_cat = [nanmean(swst_cat(1:2,:))' nanmean(swst_cat(3:4,:))' nanmean(swst_cat(5:6,:))' nanmean(swst_cat(7:8,:))'];


figure

plot(1:4, nanmean(newpairPE_cat),'k','LineWidth',2); hold all;
errorbar(1:4, nanmean(newpairPE_cat), getnanSE(newpairPE_cat),'k')

plot(1:4, nanmean(newswst_cat),'r','LineWidth',2); hold all;
errorbar(1:4, nanmean(newswst_cat), getnanSE(newswst_cat),'r');

set_default_fig_properties(gca,gcf);hold all;
ylabel('pair PE payoff')
xlabel('sPE')


figure
plot(unnr, nanmean(swst_cat'),'k','LineWidth',2); hold all;

plt{1}=plot(unnr, nanmean(swst_cat(:,upfa)'),'--r','LineWidth',2); hold all;
plt{2}=plot(unnr, nanmean(swst_cat(:,lowfa)'),'--g','LineWidth',2); hold all;
legend([plt{:}],{'highFA';'lowFA'})
%errorbar(unnr, nanmean(swst_cat'), getnanSE(swst_cat'),'r')
set_default_fig_properties(gca,gcf);hold all;
ylabel('switch.stay ')
xlabel('sPE')

figure
plot(unnr, nanmean(pairPE_cat'),'k','LineWidth',2); hold all;

plt{1}=plot(unnr, nanmean(pairPE_cat(:,upfa)'),'--r','LineWidth',2); hold all;
plt{2}=plot(unnr, nanmean(pairPE_cat(:,lowfa)'),'--g','LineWidth',2); hold all;
legend([plt{:}],{'highFA';'lowFA'})
%errorbar(unnr, nanmean(swst_cat'), getnanSE(swst_cat'),'r')
set_default_fig_properties(gca,gcf);hold all;
ylabel('switch.stay ')
xlabel('sPE')






% adjut by making categories:
newcat = [nanmean(swst_cat(1:2,:))' nanmean(swst_cat(3:4,:))' nanmean(swst_cat(5:6,:))' nanmean(swst_cat(7:8,:))'];
figure
%plot(1:4, nanmean(newcat),'k','LineWidth',2); hold all;

plt{1}=plot(1:4, nanmean(newcat(upfa,:)),'--r','LineWidth',2); hold all;
errorbar(1:4, nanmean(newcat(upfa,:)),getnanSE(newcat(upfa,:)),'r','LineWidth',2); hold all;

plt{2}=plot(1:4, nanmean(newcat(lowfa,:)),'--g','LineWidth',2); hold all;
errorbar(1:4, nanmean(newcat(lowfa,:)),getnanSE(newcat(lowfa,:)),'g','LineWidth',2); hold all;

legend([plt{:}],{'highFA';'lowFA'})
%errorbar(unnr, nanmean(swst_cat'), getnanSE(swst_cat'),'r')
set_default_fig_properties(gca,gcf);hold all;
ylabel('switch.stay ')
xlabel('sPE')
set(gca,'XTick',1:4);
set(gca,'XTickLabel', {'0-1.25';'0.25-0.5';'0.625-075';'0.875-1'},'FontSize',14);


%% PE -> swtich/stay for all Fb choices (not just the first 4)


figure;
title('FB trials');hold all;
bar(1:2, mean([sw_noPE' sw_PE']));hold all;
errbar(1:2, mean([sw_noPE' sw_PE']),getSE([sw_noPE' sw_PE']),'k');
set_default_fig_properties(gca,gcf);hold all;
ylabel('% switch ')
set(gca,'XTick',1:2);
set(gca,'XTickLabel', {'noPE_pair_t-1';'PE_pair_t-1'},'FontSize',14);


newfa=fa(subidx_FB);

figure
title('noPE');hold all;
plot(newfa, sw_noPE,'ko')
xlabel('FA')
ylabel('%switch')
set_default_fig_properties(gca,gcf);hold all;

figure
title('PE');hold all;
plot(newfa, sw_PE,'ko')
xlabel('FA')
ylabel('%switch')
set_default_fig_properties(gca,gcf);hold all;



figure
diff = sw_PE-sw_noPE;
title('PE-noPE');hold all;
plot(newfa, diff,'ko')
xlabel('FA')
ylabel('%switch')
set_default_fig_properties(gca,gcf);hold all;




figure
diff = sw_PE-sw_noPE;
title('PE-noPE');hold all;
plot(newfa, diff,'ko')
xlabel('FA')
ylabel('%switch')
set_default_fig_properties(gca,gcf);hold all;






plt=[];
figure
plt{1}=plot(1:2, [mean(sw_noPE(newfa>median(newfa))) mean(sw_PE(newfa>median(newfa))) ],'r','LineWidth',2);hold all;
errbar(1:2, [mean(sw_noPE(newfa>median(newfa))) mean(sw_PE(newfa>median(newfa))) ],[getSE(sw_noPE(newfa>median(newfa))') getSE(sw_PE(newfa>median(newfa))') ],'r');hold all;

plt{2}=plot(1:2, [mean(sw_noPE(newfa<median(newfa))) mean(sw_PE(newfa<median(newfa))) ],'b','LineWidth',2);hold all;
errbar(1:2, [mean(sw_noPE(newfa<median(newfa))) mean(sw_PE(newfa<median(newfa))) ],[getSE(sw_noPE(newfa<median(newfa))') getSE(sw_PE(newfa<median(newfa))') ],'b');hold all;
set_default_fig_properties(gca,gcf);hold all;
xlabel('PE')
legend([plt{:}],{'highFA';'lowFA'})
ylabel('%switch')
xlim([0.8 2.2])
set(gca,'XTick',1:2);
set(gca,'XTickLabel', {'No';'Yes'},'FontSize',14);





