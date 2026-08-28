%% code to plot boxplot and histogram

function [input] = boxhist(input,regname,yname)

rng('default') % for reproducibility
x =1:size(input,2); 
y = input;
%% set spacing 
binWidth = 0.1;  % histogram bin widths % TH: 0.4, MEG: 0.3
hgapGrp  = .09;   % horizontal gap between pairs of boxplot/histograms (normalized)
hgap     = 0.3;      % horizontal gap between boxplot and hist (normalized)



%% compute  histogram
hcounts = cell(size(y,2),2); 
hcounts = cell(5,2); 
for i = 1:size(y,2)
    [hcounts{i,1}, hcounts{i,2}] = histcounts(y(:,i),'BinWidth',binWidth); 
end
maxCount = max([hcounts{:,1}]);



%% plot boxplot

fig = figure();
ax = axes(fig); 
hold(ax,'on')

xInterval = mean(diff(sort(x))); % x-interval (best if x is at a fixed interval)
normwidth = (1-hgapGrp-hgap)/2;  
boxplotWidth = xInterval*normwidth;
boxplot(ax,y,'Positions',x,'Widths',boxplotWidth,'OutlierSize',3,'Labels',compose('%d',x))
set(gca,'XTick',1: length(x));
set(gca,'XTickLabel',regname,'FontSize',14);
ylabel(yname);
line([0 length(x)+1], [0 0],'Color','k');



%% histogram
histX0 = x + boxplotWidth/2 + hgap;    % histogram base
maxHeight = xInterval*normwidth;       % max histogram height
patchHandles = gobjects(1,size(y,2)); 
for i = 1:size(y,2)
    % Normalize heights 
    height = hcounts{i,1}/maxCount*maxHeight;
    % Compute x and y coordinates 
    xm = [zeros(1,numel(height)); repelem(height,2,1); zeros(2,numel(height))] + histX0(i);
    yidx = [0 0 1 1 0]' + (1:numel(height));
    ym = hcounts{i,2}(yidx);
    % Plot patches
    patchHandles(i) = patch(xm(:),ym(:),[0 .75 1],'FaceAlpha',.4);
end

xlim([0, length(x)+1])
set_default_fig_properties(gca,gcf);hold all;


