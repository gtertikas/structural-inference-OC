function [ ] = set_default_fig_properties( axishandle,fighandle,leghandle )
% sets default figure properties for a given figure handle (input: gca)

bigsize=18;         % big texts
defaultsize=14;     % everything else
defLinewidth=1;

% general properties of figure;:
set(fighandle,'Color','w');
set(fighandle,'clipping','off');

% general properties of subplot:
set(axishandle,'fontsize',defaultsize);
set(axishandle,'Linewidth',defLinewidth);
set(axishandle,'clipping','off')

% shut interpreters off
 set(axishandle,'ticklabelinterpreter','none');

% title and axes
set(get(axishandle,'Title'),'Color','k','Fontsize',bigsize,'interpreter','none');
set(get(axishandle,'xlabel'),'Color','k','Fontsize',bigsize,'interpreter','none');
set(get(axishandle,'ylabel'),'Color','k','Fontsize',bigsize,'interpreter','none');
set(axishandle,'XColor','k');                                               % the color of the axis line and the tick marks
set(axishandle,'YColor','k');

% set box off and adjust legend:
set(axishandle,'box','off');
if nargin>2,
    set(leghandle,'fontsize',bigsize,'Location','northeast','box','on','interpreter','none');
end;

% align title to the left
% set(get(axishandle,'title'),'HorizontalAlignment','left')
% titpos=get(get(axishandle,'title'),'Position');
% titpos(1)=0;
% set(get(axishandle,'title'),'Position',titpos);

end

% some tricks
%ylabel({'','P (choice left)',''}, 'FontSize', 22)
%xlabel({'','regressors',''}, 'FontSize', 22) fontsize for
%label is 22
% set(gca,'box','off', 'FontSize', 20); the ticks are fontsize 20