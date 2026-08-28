function [s] = getpmat(s)
%% merge opt and pred pmats together -> into opt pmat
% merge opt and pred: opt file with confirmswitch, allFB
nrch = 4;
predn = {'allFB';'pred_ID';'register_orderidx';'probSwitch';'cmpAcc';'confirmSwitch';'allowSwitch'};

for isub = 1:length(s.subID)
    for iphase = 4:6
      
        
        newmat=[];predmat=[];
        
        predmat = get_from_mat(s.sub{isub}.phase{iphase}.pred.pmat,predn);
        % extend it into the format of opt trials (x4)
        for it = 1:length(predmat)
            newmat = [newmat; repmat(predmat(it,:),nrch,1)];
        end
        if size(s.sub{isub}.phase{iphase}.opt.pmat.mat,1) ~= size(newmat,1), disp('mismatch'),end
        
        % add to opt mat:
        matchnames = [s.sub{isub}.phase{iphase}.opt.pmat.names ;predn];
        matchmat=[s.sub{isub}.phase{iphase}.opt.pmat.mat newmat];
        s.sub{isub}.phase{iphase}.opt.pmat.mat = matchmat;
        s.sub{isub}.phase{iphase}.opt.pmat.names = matchnames;    
    end
end





end