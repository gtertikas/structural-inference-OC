function [s] = formatdat(s,isub,choice4)
%% formats dat file
% extracts the right trials for each phase:
% miniblock
% multiple choice 
% practice 1-2
% experiment


curtab   = s.sub{isub}.instr.table;
names    = s.sub{isub}.instr.tablenames;


% ------------------ instruction stuff:
%% tree:
treename = {'allpic_def1';'allpic_def2';'allpic_change';'allpic_final_1';'allpic_final_2'};
var      = {'out_corrAns';'pic1';'pic2';'pic3';'pic4';'pic5';'pic6';'pic7';'pic8';'pic9';'pic10';'pic11';...
    'selected_picID';'tr_accuracy'};

% get the indices:
curidx = [];
for ifile = 1:length(treename)
    newidx = []; fileidx =[];
    newidx  = find(ismember(curtab.index,treename{ifile})==1);
    fileidx = repmat(ifile,length(newidx),1);
    curidx  = [curidx; fileidx newidx]; % 1. which file; 2. index
end

newmat=[];
for ivar = 1:length(var)
    cuvar = curtab.(var{ivar});
    newmat(:,ivar) = cuvar(curidx(:,2));
end

s.sub{isub}.phase{1}.Pname       = 'tree_instruct';
s.sub{isub}.phase{1}.index       = curidx;
s.sub{isub}.phase{1}.pmat.mat    = newmat;
s.sub{isub}.phase{1}.pmat.names  = var;
s.sub{isub}.phase_name           = {'tree_instr';'mcquest_instr';'short_choiceMB';'pract_fullFB';'pract_partialFB';'exp'};


%% multipe choice questions:

var =[]; var = {'ReactionTime';'answer_correct';'accumulate_accuracy';'see_explanation'};
mcidx = find(ismember(curtab.type,'multiple_choice')==1);
newmat=[];
for ivar = 1:length(var)
    cuvar = curtab.(var{ivar});
    cuvar = cuvar(mcidx,:);
    
    newvar=[];
    if ivar == 2
        newvar  = ismember(cuvar,'correct');
        cuvar   = newvar;
    elseif ivar == 4
        newvar  = ismember(cuvar,'TRUE');
        cuvar   = newvar;
    end
    
    newmat(:,ivar) = cuvar;
end

s.sub{isub}.phase{2}.Pname       = 'mcquest_instr';
s.sub{isub}.phase{2}.index       = mcidx;
s.sub{isub}.phase{2}.pmat.mat    = newmat;
s.sub{isub}.phase{2}.pmat.names  = var;

%%
% ------------------ choice blocks:
% filter them according to: orderidx;
% counts up with every miniblock: 1x mini; 3x each practice; >X experiment

% how many exp blocks?


checkmb = find(isnan(curtab.blockID)==0);
maxmb   = curtab.blockID(checkmb(end));

blockidx{1} = 1;        % mini choice block
blockidx{2} = 2:3;      % practice block 1
blockidx{3} = 4:5;      % practice block 2
blockidx{4} = 6:maxmb+1;      % experiment



%% all choice block:
for ib = 1:length(blockidx)
    
    % - practice blocks:
    if ib < 4
        defopt  = 'choice_opt_prac_';
        defpred = 'choice_pred_prac_';
    else
        % experiment block
        defopt  = 'choice_opt_exp_';
        defpred = 'choice_pred_exp_';
    end
    
    
    
    % to do: such that it loops through the blocks in practice
    % merge mat files together and give blockidx
    
    predvar = {'pred_ID';'allFB';'blockID_pred';'orderidx';'FBdur';'register_orderidx';'AllTrials';...
        'probSwitch';'predcount';'critAcc';'cmpAcc';'switchNr';'confirmSwitch';...
        'allowSwitch';};
    
    optvar  = {'opt_ID';'corrAns';...
        'choice_resp_2_keys';'choice_resp_2_rt';'binarypayoff';...
        'FB_optchoice';'curpayoff'};
    
    if s.sub{isub}.choice4 ==1 
        optvar  = {'opt_ID';'corrAns';...
        'choice_resp_2_keys';'choice_resp_2_rt';'binarypayoff';...
        'FB_optchoice';'curpayoff';'confidence'};
    end
    
    
    alloptmat=[];allpredmat=[];allpredidx=[];
    for imb = 1:length(blockidx{ib})
  
        optname=[];predname=[];optidx=[];predidx=[];alloptidx=[];
       
        
        optname   = [defopt num2str(blockidx{ib}(imb))];
        predname  = [defpred num2str(blockidx{ib}(imb))];
        optidx  = find(ismember(curtab.index_opt,optname)==1);
        predidx = find(ismember(curtab.index_pred,predname)==1);
        nrch    = 4;
        if length(predidx)*nrch ~= length(optidx)
            disp(['blockidx ' num2str(blockidx{ib}(imb)) ': mismatch pred and opt -->adjusted predidx'])
            predidx = predidx(1:length(optidx)/nrch);
            
            %keyboard
        end
        
        
        
        
        cuvar_pred=[];predmat=[];  
        for ipred = 1:length(predvar)
            cuvar_pred = curtab.(predvar{ipred});
            predmat(:,ipred) = cuvar_pred(predidx);
            
            
            
            %if isub < 9
                if ipred>5
                predmat(:,ipred) = cuvar_pred(predidx-1);
                end
            %end
            %longpredmat(:,ipred) =
        end
        allpredmat = [allpredmat; predmat];
        allpredidx = [allpredidx; predidx];
        
        cuvar_opt=[];optmat=[];
        for iopt = 1:length(optvar)
            
            cuvar_opt = curtab.(optvar{iopt});
            if strcmp(optvar{iopt},'choice_resp_2_keys')==1
                leftResp = ismember(cuvar_opt(optidx),'left'); % left =1
                
                if s.sub{isub}.choice4 ==1 % transforms data into binary version for later analyses 
                    
                    leftResp=[];
                    leftResp_1 = ismember(cuvar_opt(optidx),'x');
                    leftResp_2 = ismember(cuvar_opt(optidx),'z');
                    leftResp = leftResp_1+leftResp_2;
                end
                
                
                optmat(:,iopt) = leftResp;
            else
                optmat(:,iopt) = cuvar_opt(optidx); % length is always predmat * 4 because (4 products)
            end
            
        end
        alloptmat = [alloptmat; optmat];
        alloptidx = [alloptidx; optidx];
        
    end
    

    
    s.sub{isub}.phase{ib+2}.Pname              = s.sub{isub}.phase_name{ib+2};
    s.sub{isub}.phase{ib+2}.opt.index          = alloptidx;
    s.sub{isub}.phase{ib+2}.opt.pmat.mat       = alloptmat;
    s.sub{isub}.phase{ib+2}.opt.pmat.names     = optvar;
    
    s.sub{isub}.phase{ib+2}.pred.index        = allpredidx;
    s.sub{isub}.phase{ib+2}.pred.pmat.mat     = allpredmat;
    s.sub{isub}.phase{ib+2}.pred.pmat.names   = predvar;
    
    
end

s.sub{isub}.info.totime         = str2num(curtab.total_time{end})/60;
s.sub{isub}.info.perf_slider    = [str2num(curtab.debrief_slider_2_response{end}) str2num(curtab.debrief_slider_2_rt{end})];
s.sub{isub}.info.maxMB          = size(allpredmat,1)/5;



s.sub{isub}.info.nrswitch       = [length(find(get_from_mat(s.sub{isub}.phase{4}.pred.pmat,'confirmSwitch')==1)) ...
    length(find(get_from_mat(s.sub{isub}.phase{5}.pred.pmat,'confirmSwitch')==1)) ...
    length(find(get_from_mat(s.sub{isub}.phase{6}.pred.pmat,'confirmSwitch')==1))]; % without switches in practice trials
s.sub{isub}.info.maxMB          = size(allpredmat,1)/5;




end