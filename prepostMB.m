% calculates pre/post MB performance 
fa   = (s.fa_sub.mat(:,3));

for isub = 1:length(s.subID)
    swNr(isub) = s.sub{isub}.info.nrswitch(end);
end
subidx = find(swNr>1);

%% pre/post 1,2 indices:
timesub=[];post_sub=[];pre_sub=[];
for isub = 1:length(s.subID)
    FB = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');FB(find(FB==-1))=0;
    showFB = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'allFB');
    swTr = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
    
    
    % mark hidden trials with = 2 to differentiate later
    hididx=[];a1=17;a2=20;
    while a2<length(FB)+5
        
        hididx=[hididx; a1 a2];
        a1=a1+20;a2=a2+20;
    end
    hididx(end,:)=[];
    descidx = 1:length(hididx);descidx=sort(descidx,'descend');
    for i =1:length(hididx)
        showFB(hididx(descidx(i),1):hididx(descidx(i),2))=2;
    end
    
    % dont' use the first switch
    swidx=[];
    swidx = find(swTr==1);  swidx(1)=[];swidx=swidx-1;
    
    prevec  = NaN(length(showFB), 1);
    postvec = NaN(length(showFB),1);
    post2vec = NaN(length(showFB),1);
    
    if length(swidx)>0
        % now, look at different MBs
        MBl = 20; % here can change which one to use
        
        for i = 1:length(swidx)
            prevec(swidx(i)-MBl:swidx(i)) = i;
            postvec(swidx(i):swidx(i)+MBl) = i;  
            post2vec(swidx(i)+MBl:swidx(i)+MBl*2) = i;  
        end
        prevec   = prevec(1:length(swTr));
        postvec  = postvec(1:length(swTr));
        post2vec = post2vec(1:length(swTr));
        
        
    end
    
    % pre/post/post2 MB indices
    pre_sub(:,isub)  = prevec;
    post_sub(:,isub) = postvec;
    post2_sub(:,isub) = post2vec;
    
    % stimidx 
    simidx_sub(:,isub) = showFB;
    
end

disp('is it RT or FB')

%% get performance according to different conditions
alltr_sub = [];FB_sub = NaN(length(s.subID),3); alltr_sub = NaN(length(s.subID),3); noFB_sub = NaN(length(s.subID),3);
noFB_psw=[];FB_psw=[];alltr_psw=[];
for isub = 1:length(s.subID)
    swTr = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
    FB = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');FB(find(FB==-1))=0;
    RT = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'choice_resp_2_rt');
    curstim = simidx_sub(:,isub);
    % ~-~-~-~-~-~
    
    swidx=[];
    swidx = find(swTr==1);  swidx(1)=[];swidx=swidx-1;
    
    %
    
    
    % all switches
    preidx = find(isnan(pre_sub(:,isub))==0);
    postidx = find(isnan(post_sub(:,isub))==0);
    post2idx = find(isnan(post2_sub(:,isub))==0);
    
    
    % all trials:
    alltr_sub(isub,1) = mean(FB(preidx));
    alltr_sub(isub,2) = mean(FB(postidx));
    alltr_sub(isub,3) = mean(FB(post2idx));
    
    % FB trials
    FBidx=[];
    FBidx    = find(curstim==1);
    fb_pre   = FBidx(ismember(FBidx,preidx));
    fb_post  = FBidx(ismember(FBidx,postidx));
    fb_post2 = FBidx(ismember(FBidx,post2idx));
    
    FB_sub(isub,1) = mean(FB(fb_pre));
    FB_sub(isub,2) = mean(FB(fb_post));
    FB_sub(isub,3) = mean(FB(fb_post2));
    
    % no FB trials:
    noFBidx=[];
    noFBidx = find(curstim==0);
    % exclude until first two swaps:
    
    nofb_pre   = noFBidx(ismember(noFBidx,preidx));
    nofb_post  = noFBidx(ismember(noFBidx,postidx));
    nofb_post2 = noFBidx(ismember(noFBidx,post2idx));
    
    noFB_sub(isub,1) = mean(FB(nofb_pre));
    noFB_sub(isub,2) = mean(FB(nofb_post));
    noFB_sub(isub,3) = mean(FB(nofb_post2));
    
    
    % --- for each switch specifically:
    %
    if length(swidx)>0
        for isw =1:length(swidx)
            preidx=[];postidx=[];post2idx=[];
            
            preidx   = find(pre_sub(:,isub)==isw);
            postidx  = find(post_sub(:,isub)==isw);
            post2idx = find(post2_sub(:,isub)==isw);
            
            % all trials:
            alltr_psw{isub}(isw,1) = mean(FB(preidx));
            alltr_psw{isub}(isw,2) = mean(FB(postidx));
            alltr_psw{isub}(isw,3) = mean(FB(post2idx));
            
            % FB trials
            FBidx=[];
            FBidx    = find(curstim==1);
            fb_pre=[];fb_post=[];fb_post2=[];
            fb_pre   = FBidx(ismember(FBidx,preidx));
            fb_post  = FBidx(ismember(FBidx,postidx));
            fb_post2 = FBidx(ismember(FBidx,post2idx));
            
            FB_psw{isub}(isw,1) = mean(FB(fb_pre));
            FB_psw{isub}(isw,2) = mean(FB(fb_post));
            FB_psw{isub}(isw,3) = mean(FB(fb_post2));
            
            % no FB trials:
            noFBidx=[];
            noFBidx = find(curstim==0);
            nofb_pre=[];nofb_post=[];nofb_post2=[];
            nofb_pre   = noFBidx(ismember(noFBidx,preidx));
            nofb_post  = noFBidx(ismember(noFBidx,postidx));
            nofb_post2 = noFBidx(ismember(noFBidx,post2idx));
            
            noFB_psw{isub}(isw,1) = mean(FB(nofb_pre));
            noFB_psw{isub}(isw,2) = mean(FB(nofb_post));
            noFB_psw{isub}(isw,3) = mean(FB(nofb_post2));
            
        end
    else
        noFB_psw{isub}  = NaN;
        FB_psw{isub}    = NaN;
        alltr_psw{isub} = NaN;
    end
    
end


newall = (FB_sub+noFB_sub)/2;
figure;
%plt{1}=plot(nanmean(newall),'LineWidth',2);hold all;
%errbar(1:3,nanmean(newall),getnanSE(newall),'k');hold all;

plt{1}=plot(nanmean(FB_sub),'LineWidth',2);hold all;
errbar(1:3,nanmean(FB_sub),getnanSE(FB_sub),'k');hold all;

plt{2}=plot(nanmean(noFB_sub),'LineWidth',2);hold all;
errbar(1:3,nanmean(noFB_sub),getnanSE(noFB_sub),'k');hold all;

legend([plt{:}],{'FB';'noFB'})
set_default_fig_properties(gca,gcf);hold all;
set(gca,'box','off');
ylabel('performance')
ylabel('performance')
set(gca,'XTick',1:3);
set(gca,'XTickLabel', {'pre_SW';'post1_SW';'post2_SW'},'FontSize',14);
xlim([0.8 3])
%ylim([0.4 1])


%% this is plotted:
% the difference between post1 and post2, and baseline corrected with pre
[h p]=corr((FB_sub(:,1)-FB_sub(:,2)) - (FB_sub(:,1)-FB_sub(:,3)) ,fa,'rows','complete','Type','Spearman')
var = ((FB_sub(:,3) - FB_sub(:,2)));
figure
plot(fa, var ,'ko')
plot(fa(idx1),var(idx1),'go'); hold all;
plot(fa(idx2),var(idx2),'ro'); hold all;








figure
[h p]=corr((noFB_sub(:,1)-noFB_sub(:,2)) - (noFB_sub(:,1)-noFB_sub(:,3)) ,fa,'rows','complete')
var = (noFB_sub(:,1)-noFB_sub(:,2)) - (noFB_sub(:,1)-noFB_sub(:,3));
plot(fa, var ,'ko')



figure
x = fa; y = swNr';
scatterhist(x,y,'Location','SouthEast',...
    'Direction','out','Color','kbr','LineStyle',{'-'},...
    'LineWidth',[2],'Marker','+od','MarkerSize',[4]);
set_default_fig_properties(gca,gcf);hold all;
xlabel('OC score');
ylabel('# structural changes')

[r, p ]= corr(x,y,'Type','Spearman');


figure
x = fa; y = var;
y = FB_sub(:,3); 
scatterhist(x,y,'Location','SouthEast',...
    'Direction','out','Color','kbr','LineStyle',{'-'},...
    'LineWidth',[2],'Marker','+od','MarkerSize',[4]);
set_default_fig_properties(gca,gcf);hold all;
xlabel('OC score');
ylabel('MB t+1')

[r, p ]= corr(x,y,'Type','Spearman','rows','complete');



figure
x = fa; 
y = FB_sub(:,1); 
scatterhist(x,y,'Location','SouthEast',...
    'Direction','out','Color','kbr','LineStyle',{'-'},...
    'LineWidth',[2],'Marker','+od','MarkerSize',[4]);
set_default_fig_properties(gca,gcf);hold all;
xlabel('OC score');
ylabel('MB t-1')

[r, p ]= corr(x,y,'Type','Spearman','rows','complete');



names = {'pre_SW';'post1_SW';'post2_SW'};
yname={'FB: performance'};
boxhist(FB_sub, names,yname)
ylim([0 1])


% no FB trials:
% need to exclude 

names = {'MB t-1';'MB t';'MB t+1'};
yname={'noFB: performance'};
boxhist(noFB_sub(subidx,:), names,yname)
ylim([0 1])


figure
x = fa; 
y = noFB_sub(:,3); 
scatterhist(x,y,'Location','SouthEast',...
    'Direction','out','Color','kbr','LineStyle',{'-'},...
    'LineWidth',[2],'Marker','+od','MarkerSize',[4]);
set_default_fig_properties(gca,gcf);hold all;
xlabel('OC score');
ylabel('noFB: MB t+1')

[r, p ]= corr(x,y,'Type','Spearman','rows','complete');












%%




figure
plot(alltr_sub(:,2)-alltr_sub(:,3),fa,'ko')

figure
plot(FB_sub(:,2)-FB_sub(:,3),fa,'ko')

figure
plot(noFB_sub(:,2)-noFB_sub(:,3),fa,'ko')


%% analysis adjusting for number of MBs
% this does not really work
allmat=[];FBmat=[];noFBmat=[];
fa   = normalise(s.fa_sub.mat(:,3));

for isub = 1:length(s.subID)
    curnoFB=[];
    time = 1:3;
    allmat = [allmat; alltr_sub(isub,:)' time' repmat(isub, 3,1) repmat(fa(isub), 3,1)];
    FBmat = [FBmat; FB_sub(isub,:)' time' repmat(isub, 3,1) repmat(fa(isub), 3,1)];
    noFBmat = [noFBmat; noFB_sub(isub,:)' time' repmat(isub, 3,1) repmat(fa(isub), 3,1)];

end

im=1;
perf = allmat(:,im); im=im+1;
time = allmat(:,im); im=im+1;
subID = allmat(:,im); im=im+1;
FA = allmat(:,im); im=im+1;

tbl = table(perf,time,subID,FA);
        
lmeF = fitlme(tbl,'perf~FA*time+(1|subID)');



        
        
        
%% peformance of noFB trials just prior to switch 
% exclude the first MB and second MB; 
% so only for those who have more than 2 switches

noFB_fMB= NaN(length(s.subID),1);
for isub = 1:length(s.subID)
    FB = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'FB_optchoice');FB(find(FB==-1))=0;
    showFB = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'allFB');
    swTr = get_from_mat(s.sub{isub}.phase{6}.opt.pmat,'trueSwitch');
    
    swidx = find(swTr==1);
    
    if numel(swidx)>2
        swidx(1:2)=[]; % only want to look at noFB when participants actually have to change on these trials too
        
        newidx=[];
        for i = 1:length(swidx)
        newidx(i,:) = swidx(i):swidx(i)+20;
        end
        newidx(find(newidx>length(FB)))=[];
        newidx = newidx(:);
        
        noFB_fMB(isub) = mean(FB(find(showFB(newidx)==0)));
        
    end
    
    
end


% not after the switch, but prior to the switch




        
        
        
        
        
        
        