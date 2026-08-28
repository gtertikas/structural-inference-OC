function [s] = addpmat(s)
%% variables for GLM -> add to pmat

% ---- only experimental data
% 1. across trials, variables for
% last trial seen same pair (layer 1, 3)
% last trial seen counterfactual pair
% last trial seens the same layer 3 stimuli

only_fullFB=1;

iphase = 6;
for isub = 1:length(s.subID)
    optID   = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'opt_ID');
    predID  = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'pred_ID');
    choice  = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'accept');
    corrAns = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'corrAns');
    allFB   = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'allFB');

    tmpblock = s.sub{isub}.phase{iphase}.pred.pmat.mat(:,2); % somehow cannot extract according to name 
    MBid = []; icount=1;
    while length(MBid)< length(allFB)
        MBid = [MBid; repmat(icount,20,1)]; % 4*5 - 20 = 1 MB
        icount = icount+1;
    end
    if length(MBid)~= length(allFB)==1, MBid= MBid(1:length(allFB));end
    %MBid(layidx==2)=[];
    
    % delete all hidden layer trials:
    stimidx = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'stimidx');
    optID(stimidx==2) = []; predID(stimidx==2) = [];choice(stimidx==2) = [];corrAns(stimidx==2) = [];
    MBid(stimidx==2) = [];
    
     
    % a. --------- find stim trial
    nrch = 4; 
    idx_stimt1 = NaN(length(optID),1); 
    for it =(nrch+1):length(optID) % start in the second MB
        curpred = predID(it);
        curop   = optID(it);
      
        % last time with the stim only (layer 3)
        lastop=[];idx=[];optidx=[];
        lastop = find(optID==curop);
        idx = sort(find(lastop<it),'descend');
        optidx = lastop(idx(1));
        
        
        % --- only take the trials where there was full feedback:
%         if only_fullFB ==1
%             
%             if allFB(optidx) == 1 % excplicit trial
%                 optidx = optidx;
%             elseif allFB(optidx) == 0 % implicit trial
%                 optidx = NaN;
%             end
%         end
        
        
        idx_stimt1(it) = optidx;
    end
    
    
    % ------ structural pairs
    % same structure,
    % different structure
    
    final_samepair_prevMB_idx = NaN(length(optID),1);
    final_samestruct_prevMB_diffpair_idx = NaN(length(optID),1);
    final_diffstruc_prevMB_recent_idx = NaN(length(optID),1);
   
    
    for it = 17:length(MBid)
       
       curop   = optID(it);
       curpred = predID(it);
       
       %% ----------- independent of MB order (whether last or current MB)
       % when was last time:
       optidx = sort(find(optID(1:it-1)==curop),'descend');
       % which ones are paired with ... 
       matchpre = predID(optidx);
       % - same pair
       samepair = find(matchpre==curpred); % first one is the most recent one because the idx before has been sorted
       samepair_idx = optidx(samepair(1));
       
       % - same structure (!) -> from previous or current miniblock (indep
       % of MB)
       % %@%@%@%@%@%@% might not be right -> same structure as current one;
       % does not mean it is correct 
       matchstr = corrAns(optidx);
       samestr  = find(matchstr==1); samestruct_idx = optidx(samestr(1));
       diffstr  = find(matchstr==0); diffstruct_idx = optidx(diffstr(1));
       
       % same or different miniblock:
       % ~ same MB:
       curbID = MBid(it);
       prevMB = find(MBid<curbID);
       
       % delete hidden layer: 
       %prevMB(find(layidx(prevMB)==2)) =[];
       %sameMB = find(MBid==curbID);sameMB(1); % only before this trial
       %sameMB(find(layidx(sameMB)==2)) =[];
       

       
       %% ----------- dependent of MB order -> current or previous
       % !!! previous MB, same pair:
       % 
       prevMBopt = optID(prevMB);prevMBpred = predID(prevMB);prevMBcorr = corrAns(prevMB);
       idxprevMB_opt  = find(prevMBopt==curop);
       idxprevMB_pred = find(prevMBpred==curpred);
       
    
       
       % same pair: 
       tmp_idx = prevMB(idxprevMB_opt(ismember(idxprevMB_opt,idxprevMB_pred)==1));
       samepair_prevMB_idx = tmp_idx(end); % most recent one
       
       % same structure as current pair, previous MB       
       stridx = prevMBcorr(prevMB(samepair_prevMB_idx));
       samestrucidx = find(prevMBcorr==stridx); sameopt = samestrucidx(ismember(samestrucidx,idxprevMB_opt));
       all_samestrucidx = sort(prevMB(sameopt),'descend'); 

       samestruc_prevMB_recent_idx = all_samestrucidx(1); % same structure, previous MB, most recent
       samestruct_prevMB_diffpair_idx = all_samestrucidx(ismember(all_samestrucidx,samepair_prevMB_idx)==0); % same structure, previous MB, different pair
       
       % different structure as current pair, previous MB 
       diffidx = 1-stridx;
       diffstrucidx = find(prevMBcorr==diffidx); diffopt = diffstrucidx(ismember(diffstrucidx,idxprevMB_opt));
       all_diffstrucidx = sort(prevMB(diffopt),'descend'); 

       diffstruc_prevMB_recent_idx = all_diffstrucidx(1); % 
       
       
       final_samepair_prevMB_idx(it) =samepair_prevMB_idx(1);
       final_samestruct_prevMB_diffpair_idx(it) = samestruct_prevMB_diffpair_idx(1);
       final_diffstruc_prevMB_recent_idx(it) = diffstruc_prevMB_recent_idx(1);
       
       
       
       
    end
    
    
    % b. -------find pair trials
    nrpred=4; % adjust for  hidden layer 
    idx_pairt1 = NaN(length(optID),1);switchvar= NaN(length(optID),1);
    start = (nrch*nrpred)+1;curpred=[];curop=[];
    
    ia=1;ib=4;count=1;
    while ia<length(predID)
        predcount(ia:ib) = count;
        ia = ia+4; ib = ib+4;
        count = count+1;
    end
    
    for ip = start:length(predID)
        curpred = predID(ip);
        curop   = optID(ip);
      
        % last time with the pair (layer 1+3); pair specific
        lastpred=[];idx=[];
        lastpred    = find(predID==curpred);
        idx         = sort(find(lastpred<ip),'descend');
        predidx     = lastpred(idx); % last time with this predictor 
        curpos      = predcount(ip); % need to create an index such that looks in the last miniblock, because the pred mat is x4, would look otherwise on the last trial within same miniblock
        nextpred    = find(predcount(predidx)~=curpos);
        finalidx    = predidx(nextpred(1:4));

        % find opt for these trials:
        
        optpred = find(optID(finalidx)==curop);
        idx_pairt1(ip) = finalidx(optpred);
        
        % pair of different structure
      %  sidx = 1- corrAns(ip);
        % 
        
        
        
        
        
        
        
        
        
        
        % determine switch:
        if choice(ip) ~= choice(finalidx(optpred))
            switchvar(ip)=1;
        elseif choice(ip) == choice(finalidx(optpred))
            switchvar(ip)=0;
        end
        
%           if only_fullFB ==1
%             if allFB(finalidx(optpred))==1
%                 idx_pairt1(ip) = finalidx(optpred);
%             elseif allFB(finalidx(optpred))==0
%                 idx_pairt1(ip) = NaN;
%             end
%         end
        
        

    end
        
    
    %% ------- all variables of interest:
        
    %idx_pairt1(isnan(idx_pairt1)) =[];idx_stimt1(isnan(idx_stimt1)) =[];switchvar(isnan(idx_stimt1)) =[];
    s.sub{isub}.phase{iphase}.glm.hididx      =  stimidx;
    s.sub{isub}.phase{iphase}.glm.pairidx     =  idx_pairt1;
    s.sub{isub}.phase{iphase}.glm.stimidx     =  idx_stimt1;
    s.sub{isub}.phase{iphase}.glm.switchvar   =  switchvar;
    
    
    
    % dependent of MB -> previous MB (but could still be the same
    % structural knowledge, not necessarily a switch has happened
    s.sub{isub}.phase{iphase}.glm.samepair_prevMB_idx                =  final_samepair_prevMB_idx; % same pair, prev MB
    s.sub{isub}.phase{iphase}.glm.samestruct_prevMB_diffpair_idx     =  final_samestruct_prevMB_diffpair_idx; % diff pair, same structure, prev MB
    s.sub{isub}.phase{iphase}.glm.diffstruc_prevMB_recent_idx        =  final_diffstruc_prevMB_recent_idx; % most recent pair, diff structure, prev MB
    
    % within same MB for not the same pair
    
    if nansum(idx_pairt1- final_samepair_prevMB_idx) ~=0
        keyboard
    end
end


end