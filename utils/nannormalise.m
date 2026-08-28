function [outdata] = nannormalise(indata)
%this function normalises a matrix column by column, ignoring the Nans


outdata=indata;
[waste ncol]=size(outdata);
for icol=1:ncol,
    indok=find(~isnan(indata(:,icol)));
    outdata(indok,icol)=normalise(indata(indok,icol));
end

