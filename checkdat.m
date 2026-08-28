function [s] = checkdat(s,isub,choice4)
%%
% 1. tree: a) checks whether the correct answers are rewarded
%          b) compares with the schedule, whether the correct structure is
%          loaded in




%% 1. tree:
% read in all different files for the tree:

treevars = get_from_mat(s.sub{isub}.phase{1}.pmat, {'out_corrAns';'selected_picID';'tr_accuracy'});
input  = treevars(:,1);
answer = treevars(:,2);
FB     = treevars(:,3); FB = 1-FB;
diff   = input-answer; %if isub <4 compvecs = find(diff~=0)-find(FB~=0); if isempty(find(compvecs~=0)) == 0 disp('mismatch:tree answers'), end,end

% additionally: can compare with the schedule
treeidx  = s.sub{isub}.sched.data.block{1}.idx;
deftree1 = [treeidx{1}(1:2) treeidx{2}(1) treeidx{3}(1:2)];
deftree2 = [treeidx{1}(3:4) treeidx{2}(2) treeidx{3}(3:4)];

treeidx     = s.sub{isub}.sched.data.block{2}.idx;
changetree1 = [treeidx{1}(1:2) treeidx{2}(1) treeidx{3}(1:2)];
changetree2 =  [treeidx{1}(3:4) treeidx{2}(2) treeidx{3}(3:4)];

treeidx     = s.sub{isub}.sched.data.block{3}.idx;
finaltree1a = [treeidx{1}(1:2) treeidx{2}(1) treeidx{3}(1:2)];
finaltree1b = [treeidx{1}(3:4) treeidx{2}(2) treeidx{3}(3:4)];

treeidx     = s.sub{isub}.sched.data.block{4}.idx;
finaltree2a = [treeidx{1}(1:2) treeidx{2}(1) treeidx{3}(1:2)];
finaltree2b = [treeidx{1}(3:4) treeidx{2}(2) treeidx{3}(3:4)];

sched_tree=[deftree1;deftree2;changetree1;changetree2;finaltree1a;finaltree1b;finaltree2a;finaltree2b ];


compareidx = s.sub{isub}.phase{1}.index;
tnames = {'pic7';'pic8';'pic9';'pic10';'pic11'};
tmat   = get_from_mat(s.sub{isub}.phase{1}.pmat,tnames);

tridx = [1 12 23 24 29 30 31 32];
dat_tree  = tmat(tridx,:);

dat_tree(find(dat_tree==98)) = input(24); % just need toa djust for the number that is not shown to the participant
diff_tree = dat_tree-sched_tree;
if isempty(find(diff_tree~=0)) == 0 disp('mismatch: tree structure'), end


%% 2. All choice blocks

% to do: check whether the correct predID and optID are shown
% whether the right ones are implicit and hidden
% whether they update to the right predID and optID when there was a change

curtab   = s.sub{isub}.instr.table;
names    = s.sub{isub}.instr.tablenames;
buttonP  = curtab.randNR(1);
if buttonP == 0
    checkcross = [1 0]; % left, right
    
else
    checkcross = [0 1];
end
s.sub{isub}.info.butpress =buttonP;
s.sub{isub}.info.butpress_name ={'0:check left (1); cross right (0)'};




for iphase = 3:length(s.sub{isub}.phase)
    
    % --------------------------------------------------------------------------------
    %% whether FB corresponds to what they should have seen
    
    % need to check what is left/right button
    curvar=[];
    
    
    curvar = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,{'opt_ID';'corrAns';'choice_resp_2_keys';'FB_optchoice'});
  
    
    % choice_resp_2_keys = 1
    butdir=[];
    butdir = curvar(:,3);
    accept=[];
    for it = 1:length(curvar)
        
        if butdir(it) == 1 % pressed left
            accept(it) = checkcross(1);
        elseif butdir(it) == 0 % pressed right
            accept(it) = checkcross(2);
        end
    end
    accept=accept';
    % add variable to pmat:
    s.sub{isub}.phase{iphase}.opt.pmat.mat(:,end+1)=accept;
    s.sub{isub}.phase{iphase}.opt.pmat.names{end+1}='accept';
    
    
    
    %if isempty(find(accept - get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'choice_resp_2_keys')~=0)) == 0, keyboard,disp([num2str(iphase) 'check left/right button']),end
    
    % compare whether they have seen the correct feedback
    % compare the choice with the correct answer in schedule
    % and accordingly, whether they saw the right feedback
    datFB=[];schedACC=[];diff=[];compareFB=[];
    
    datFB       = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'FB_optchoice');
    schedACC    = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'corrAns');
    diff        = find(schedACC-accept~=0);
    
    
   % compareFB   = diff-find(datFB==-1); if isempty(find(compareFB ~= 0))==0, disp([num2str(iphase) 'check whether FB they saw is correct']),end
    
    
    % --------------------------------------------------------------------------------
    %% pID and optID correct?
    
    optvar  = [];
    predvar = [];
    %optvar = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,{'opt_ID';});
    
    % ----------- predID:
    blockidx = get_from_mat(s.sub{isub}.phase{iphase}.pred.pmat,'register_orderidx');
    blockidx = blockidx(isnan(blockidx)==0);
    % --- schedule:
    buniq=[];
    buniq = unique(blockidx);
    nrch  = 4;
    optidx=[];
    for io = 1:length(buniq)
        optidx = [optidx; repmat(buniq(io),length(find(blockidx==buniq(io)))*nrch,1) ];
    end
    
    for iq = 1:length(buniq)
        schedpredID=[];datpredID=[];getbidx=[];diffpred=[];
        
        % opts:
        schedopttab = s.sub{isub}.sched.data.sched{buniq(iq)}.opt;
        schedoptID  = schedopttab.opt_ID;
        datoptID    = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,{'opt_ID';});
        getidx      = find(optidx==buniq(iq));
        diffopt     = schedoptID(1:length(getidx)) - datoptID(getidx);
        
        
        % preds:
        schedtab    = s.sub{isub}.sched.data.sched{buniq(iq)}.pred;
        schedpredID = schedtab.pred_ID;
        datpredID   = get_from_mat(s.sub{isub}.phase{iphase}.pred.pmat,'pred_ID');
        
        % compare:
        getbidx = find(blockidx==buniq(iq));
        
        diffpred = schedpredID(1:length(getbidx)) - datpredID(getbidx);
        
        
        % check
        if isempty(find(diffpred ~= 0))==0, disp([num2str(iphase) 'predID sched and dat mismatch']),end
        if isempty(find(diffopt ~= 0))==0, disp([num2str(iphase) 'optID sched and dat mismatch']),end
        
    end
end
% --------------------------------------------------------------------------------
%% did it switch correctly, ie after fulfilling accuracy threshold?

if isub ==1
    phaseidx = [ 6]; % there was a mistake for sub1 -> has been resolved
else
    phaseidx = [6];
end

for ip = 1:length(phaseidx)
    iphase=phaseidx(ip);
    
    % loop through each miniblock.
    
    confswitch = get_from_mat(s.sub{isub}.phase{iphase}.pred.pmat,{'confirmSwitch'});
    dat_MBacc  = get_from_mat(s.sub{isub}.phase{iphase}.pred.pmat,{'cmpAcc'});
    cirtACC    = get_from_mat(s.sub{isub}.phase{iphase}.pred.pmat,{'critAcc'});
    cirtACC    = cirtACC(1);
    
    
    % a. check whether accuracy is properly calculated according to the
    % feedback of the explicit choice
    
    if iphase == 3
        mblength = 16; % 4 predictors * 4 choices
        predcount = 4;
        
    elseif iphase >3
        mblength = 20; % 5 predictors * 4 choices
        predcount = 5;
        
    end
    
    
    
    allowSw = [];
    allowSw       = get_from_mat(s.sub{isub}.phase{iphase}.pred.pmat, 'allowSwitch');
    
    
    FB=[];
    FB       = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat, 'FB_optchoice');
    FB(find(FB==-1))=0;
    
    allFB=[];
    allFB    = get_from_mat(s.sub{isub}.phase{iphase}.pred.pmat, 'allFB');
    
    optallFB = [];optallowSw=[];
    for io = 1:length(allFB)
        optallFB = [optallFB; repmat(allFB(io),nrch,1)];
        optallowSw = [optallowSw; repmat(allowSw(io),nrch,1)];
    end
    
    mbcircles = length(FB)/mblength; newpred = predcount;
    ia = 1; ib = mblength;lastswitch=0; imb=1;
    while imb < round(mbcircles)
        MBaccuracy=[];
        curFB = FB(ia:ib); % the actual performance feedback
        curallFB = optallFB(ia:ib); % whether it is explicit or implicit
        allowsw  = optallowSw(ia:ib);
        if iphase>4, if length(find(curallFB==1)) ~=8, disp('too many or few implicit/explicit ratio in block'), end,end
        
        MBaccuracy = mean(curFB(curallFB==1));
        if (MBaccuracy - dat_MBacc(newpred)) ~=0, disp('accuracy calculation mismatch'),end
        
        % b. check whether according to the accuracy, there was a switch or not
        datswitch = confswitch(newpred);
        
        
        % -- only check when there was not a switch last MB
        % need to be at least 2 MBs in between before new switch
        if lastswitch ==0 && length(find(allowsw(end-3:end)==1))<1
            if MBaccuracy >= cirtACC
                % switch
                switchY = 1;
                lastswitch =1;
            else
                % no switch
                switchY = 0;
                lastswitch =0;
            end
            
        elseif lastswitch ==1 || length(find(allowsw(end-3:end)==1))>0 % either no switch because there was a switch in the last block or because of the criterion of 50-50% transition
            switchY = 0;
            lastswitch =0;
        end
        
        if (switchY - datswitch) ~=0, disp('switch mismatch according to accuracy'),end
        
        
        
        
        ia = ia+mblength; ib = ib+mblength; newpred = newpred+predcount;
        imb=imb+1;
    end
         
    
end



%disp('checked: switchNr all good; pred_opt_IDs')



end