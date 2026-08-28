function [s] = factana(s)
%% load factor scores from R

%% 1. FA run on all individual items:
% study 1:
%filename='fa_scores_Jan23.csv';
%filename='fa_subs_scores_Jan23.csv';

% study 2:
% filename='fa_scores_Feb23.csv';
% 
% opts = detectImportOptions(filename,'NumHeaderLines',0);
% T    = readtable(filename,opts);
% 
% s.fa.score = T;
% s.fa.mat = [T.ML1 T.ML2 T.ML3];
% s.fa.name = {'DASS_RSS';'LSAS';'OCIR'};

%% 2. FA run on subscales:

filename_sub='fa_subs_scores_Feb23.csv';
opts = detectImportOptions(filename_sub,'NumHeaderLines',0);
T    = readtable(filename_sub,opts);

s.fa_sub.score = T;
s.fa_sub.mat = [T.ML1 T.ML2 T.ML3];
s.fa_sub.name = {'DASS_RSS';'LSAS';'OCIR'};



%% correlation across FA analyses
% 
% figure
% imagesc(corrcoef([s.fa_sub.mat s.fa.mat]),[-1 1])
% colorbar
% names = {'FA_DASS_sub';'FA_OCIR_sub';'FA_socAnx_sub';'FA_DASS_all';'FA_socAnx_all';'FA_OCIR_all'};
% set_default_fig_properties(gca,gcf);hold all;
% set(gca,'XTick',1:length(names));
% set(gca,'XTickLabel', names,'FontSize',14);
% set(gca,'YTick',1:length(names));
% set(gca,'YTickLabel', names,'FontSize',14);
% 

end