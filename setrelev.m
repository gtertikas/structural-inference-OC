function [s] = setrelev(s)
%% sets the relevance of stimuli for each block


nstim = 10;

% - same group vs different group
for isub = 1:length(s.sub)
    for iblock = 1:length(s.sub{isub}.sched.data.block)
        mat = zeros(nstim,nstim);
        
        curblock = s.sub{isub}.sched.data.block{iblock}.idx;
        struc{1} = [curblock{1}(1:2) curblock{2}(1) curblock{3}(1:2)];
        struc{2}  = [curblock{1}(3:4) curblock{2}(2) curblock{3}(3:4)];
        for istruct = 1:2
            gidx = struc{istruct};
            
            for ib = 1:length(gidx)
                for ia = 1:length(gidx)
                    mat(gidx(ib),gidx(ia)) = 1;
                end
            end
        end
        
        s.sub{isub}.sched.data.block{iblock}.matidx = mat; % 1 = same group, 0 = different group
    end
end


% - change across blocks:

for isub = 1:length(s.sub)
    
    for iblock = 2:length(s.sub{isub}.sched.data.block)
    prevmat = s.sub{isub}.sched.data.block{iblock-1}.matidx;
    curmat  = s.sub{isub}.sched.data.block{iblock}.matidx;
    
    prevmat(find(prevmat==1)) =2;
    
    mattdiff = curmat-prevmat; % -2: relevant -> irrelevant; -1: still relevant; 0: still irrelevant; 1 -> now relevant ( irr -> relev)
    
    % changed stimuli
    changemat = zeros(nstim,nstim);
    changemat(find(mattdiff==-2)) = 1;
    changemat(find(mattdiff==1))  = 1;
    
    s.sub{isub}.sched.data.block{iblock}.changeidx = changemat;
    s.sub{isub}.sched.data.block{iblock}.mattdiff  = mattdiff;
    s.sub{isub}.sched.data.block{iblock}.diff_desc  = {'-2:rel->irr';'-1:still relev';'0: still irr';'1: irr->rel'};
    end
    
end



end