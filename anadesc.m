function [s]=anadesc(s,doplot)
%% descriptive plots
% 1: overview: accept rate, payoff and switchnr
% 2. reversal for each choice


%% 1. quick overview
% doplot = 1
blockn = {'shortMB';'prac1';'prac2';'exp'};

icount=1;acceptR=[];
for isub = 1:length(s.subID)
    icount=1;
    for iphase = 3:6
        acceptR_phase(icount) =  mean(get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'accept'));
        FB = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'FB_optchoice');FB(find(FB==-1))=0;
        binarypay(isub,icount) = mean(FB);
        
        if iphase>3
        length_prac(isub,iphase-3) = round((length(get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'accept'))/4)/5);
        end
        
        icount=icount+1;
        
    end
    acceptR = [acceptR; acceptR_phase];
    switchNR(isub,:) = s.sub{isub}.info.nrswitch(:,end);
    
    
end

rundoplot = [1 0 0];
eval('anadesc_plot')

%% 2. reversals per subject
% only practice and exp trials



for isub = 1:length(s.subID)
    icount=1;phaseFB=[];stimacc_phase = NaN(3,3);subcount=1;
    for iphase = 4:6
        FB=[];
        FB = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'FB_optchoice');FB(find(FB==-1))=0; % payoff
        tmp_switchY = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'confirmSwitch');
        switchY = zeros(length(tmp_switchY),1);
        idxswitch = find(tmp_switchY==1);
        inr = 4;swnr=inr;trueswitch=[];
        while swnr< length(idxswitch)+1
            trueswitch = [trueswitch; idxswitch(swnr)];
            swnr = swnr+inr;
        end
        
        
        if trueswitch(end) == length(tmp_switchY) % just simply before the next block starts
            trueswitch(end) = [];
        end
        
        trueswitch = trueswitch+1; % !!! KEEP IN MIND; it is the switch on the next trial
        switchY(trueswitch) =1;
        % add to opt mat:
        s.sub{isub}.phase{iphase}.opt.pmat.mat(:,end+1) = switchY;
        s.sub{isub}.phase{iphase}.opt.pmat.names(end+1) = {'trueSwitch'};
        
        
        
        %% implicit vs explicit
        
        if iphase >3
            
            allFB  = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'allFB'); % implicit or explicit
            predID = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'pred_ID');
            payoff = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'FB_optchoice');
            if s.sub{isub}.choice4==1
                conf = get_from_mat(s.sub{isub}.phase{iphase}.opt.pmat,'confidence');
            else
                conf =[];
            end
            payoff(find(payoff==-1))=0;
            hidstim = s.sub{isub}.sched.data.default{2};
            hididx=[];
            hididx = find(ismember(predID,hidstim)==1);
            
            % stimidx: 0 = implicit, 1 = explicit, 2 = hidden
            stimidx=[];
            stimidx = zeros(length(allFB),1);
            stimidx(find(allFB==1)) = 1;
            stimidx(hididx)         = 2;
            
            % add to pmat:
            s.sub{isub}.phase{iphase}.opt.pmat.mat(:,end+1) = stimidx;
            s.sub{isub}.phase{iphase}.opt.pmat.names(end+1) = {'stimidx'};
            
            uniqueidx = unique(stimidx);
            
            for ist = 1:length(uniqueidx)
                curidx=[];
                curidx = find(stimidx==uniqueidx(ist));
                stimacc_phase(iphase-3,uniqueidx(ist)+1)=mean(payoff(curidx)); %im, ex, hidden
            end
            
            if iphase>4
                
                allch{iphase}.stim = [payoff(find(stimidx==0)) payoff(find(stimidx==1)) ];
                allch{iphase}.hid  = payoff(find(stimidx==2));
                phase.allch_acc         = allch;
                
                
                
            end
            payoff(stimidx==2)=[];switchY(stimidx==2)=[]; allFB(stimidx==2)=[];if numel(conf)>0,conf(stimidx==2)=[];end
            ia = 1; ib=4;avgpayoff=[]; avgswitch=[];avgallFB=[];avgallconf = [];
            while ia < length(payoff)+1
                avgpayoff = [ avgpayoff;mean(payoff(ia:ib))];
                avgswitch  = [avgswitch; mean(switchY(ia:ib))];
                avgallFB   = [avgallFB; mean(allFB((ia:ib)))];
                if numel(conf)>0
                avgallconf   = [avgallconf; mean(conf((ia:ib)))];
                end
                ia = ia+4;ib=ib+4;
            end
            avgswitch(find(avgswitch>0)) =1;
            if length(find(avgswitch>0)) ~= length(trueswitch), disp('did not catch all switches'),end
            
            avg_allch{iphase}.avgpayoff = avgpayoff;
            avg_allch{iphase}.avgswitch = avgswitch;
            avg_allch{iphase}.avgallFB = avgallFB;
            avg_allch{iphase}.avgallconf = avgallconf;
            
        end
        
        
        
        
        
        
        
        
        
        % --- save:
        phase.FB{icount}        = FB;
        phase.switchY{icount}   = switchY;
        phase.stimacc_phase     =   stimacc_phase;
        
        
        
        
        
        
        
        
        icount=icount+1;
    end

    phasesub{isub}.phase=phase;
    phasesub{isub}.avg=avg_allch;
    
    rundoplot = [0 1 0];
    eval('anadesc_plot')
end


% plot across sub accuracy

rundoplot = [0 0 1];
eval('anadesc_plot')






end