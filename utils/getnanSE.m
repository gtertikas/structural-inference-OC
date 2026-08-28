function [stderror] = getSE(stddata)
%this function computes the standard error; Standard error is computed by condition.
% rows must be subjects, 
% cols must be conditions. 

[nsubj ncond]=size(stddata);
for iCond=1:ncond
    stderror(1,iCond)= nanstd(stddata(:,iCond))./ sum(~isnan(stddata(:,iCond))).^.5;
end

