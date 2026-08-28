function [pout] = get_from_mat( pmat,topick )
% extracts columns from the MAT results matrix, SORTED according to input 
%
% INPUT:    - mat: trialcourse matrix
%           - topick: parameters of interest, a cell with strings
% OUTPUT:   - pout: the parameter matrix reduced to the parameters in poi
%             and SORTED like them
%%

mat=pmat;
allnam=pmat.names;

if ~iscell(topick),
    num_par=1;
    indp=nan;
else
    num_par=numel(topick);
    indp=nan(numel(topick),1);
end;


for ip=1:num_par,
    if ~iscell(topick),
        if isempty(find(ismember(allnam,topick)) ),
            disp(['Desired Parameter not in Matrix:' topick{ip}]);
            return
        end;
    else
        if isempty(find(ismember(allnam,topick{ip})) ),
            disp(['Desired Parameter not in Matrix:' topick{ip}]);
            return
        end;
    end;
    % execute what you want to do only now:
    if ~iscell(topick),
        indp(ip)=find(ismember(allnam,{topick}));
    else
        indp(ip)=find(ismember(allnam,topick{ip}));
    end;
end;

pout=pmat.mat(:,indp);





end

