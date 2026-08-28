function [s] = loadQuest(s,doplot)
%% load questionnaire data
% they are sorted into the order of subject ID
% note that we have attention check questions within each questionnaire
% hence it looks like there is 1 quest item missing in each questionnaire,
% but this is not the case; we are just not reading in the attention checks
% here
questdat = [];

im = 1;

%%

% pID: filename = questdata.csv
keyboard
filename='Spacegame - behavioural experiment (final)_March 8, 2023_17.37.csv';
opts = detectImportOptions(filename,'NumHeaderLines',0);
T    = readtable(filename,opts);

pID = T.Q43;


% merge tables to have same subjects
Q43     = s.subID;
cursubT = table(Q43);
new = innerjoin(cursubT, T);

% 1 person has two questionnaire files -> select the correct one:
[v, w] = unique( new.Q43, 'stable' );
duplicate_indices = setdiff( 1:numel(new.Q43), w);
new(duplicate_indices,:)=[];


% sort into right order:
for is = 1:length(s.subID)
    idx(is) = find(strcmp(new.Q43, s.subID{is})==1); % the same
end

s.quest.idx = idx; % use this idx to get the right order for the table
s.quest.tab = new(idx,:);


%% OCIR:
% no reverse items
s.ocir_names  = {'Q85_1',	'Q85_2',	'Q85_3'	,'Q85_4',	'Q85_5',	'Q85_6',	'Q85_7',	'Q85_8',...
    'Q85_9',	'Q85_11',	'Q85_12',	'Q85_13',	'Q85_14',	'Q85_15',	'Q85_16',...
    'Q85_17',	'Q85_18',	'Q85_19'};

curmat=[];
for iq = 1:length(s.ocir_names)
    curmat(:,iq) = s.quest.tab.(s.ocir_names{iq});
    questdat{im}(:,iq)  = s.quest.tab.(s.ocir_names{iq});
end
im = im +1;

s.ocir_scores = sum(curmat');

if doplot(1) ==1
    figure
    hist(sum(curmat'))
    set_default_fig_properties(gca,gcf);hold all;
    
    ylabel('OCIR total score');
    xlim([0 90])
end



%% ICARR:
% check with correct answers
qid = {'Q55',	'Q56',	'Q57',	'Q58',	'Q59',	'Q60',	'Q62',	'Q61', 'Q64', 'Q67', 'Q69' ,'Q71', 'Q73', 'Q75' ,'Q77', 'Q80'};

CorrIt = [4 4 4 6 6 3 4 4 5 2 2 4 3 2 6 7];


for iq = 1:length(qid)
    curit = s.quest.tab.(qid{iq});
    answ = ismember(curit,CorrIt(iq));
    questdat{im}(:,iq) =answ;
end
im = im +1;


%% social anxiety
% mean across fear and avoid and then total score
% no reverse items
qfear = {'Q204_33_1',	'Q204_34_1',	'Q204_35_1',	'Q204_36_1'	,'Q204_47_1'	,'Q204_48_1',	'Q204_49_1'	,'Q204_50_1'	,'Q204_51_1'	,'Q204_52_1'	,'Q204_53_1',	'Q204_54_1',	'Q204_55_1',...
    'Q204_56_1',	'Q204_57_1'	,'Q204_58_1'	,'Q204_59_1'	,'Q204_60_1'	,'Q204_61_1'	,'Q204_62_1'	,'Q204_63_1'	,'Q204_64_1'	,'Q204_65_1',	'Q204_66_1'};

qavoid = {'Q204_33_2'	,'Q204_34_2'	,'Q204_35_2', 'Q204_36_2',	'Q204_47_2'	,'Q204_48_2',	'Q204_49_2'	,'Q204_50_2'	,'Q204_51_2',	'Q204_52_2'	,'Q204_53_2'	,'Q204_54_2'	,'Q204_55_2'	,	'Q204_56_2'	,'Q204_57_2',	'Q204_58_2'	,'Q204_59_2',	'Q204_60_2',	'Q204_61_2',...
    'Q204_62_2',	'Q204_63_2',	'Q204_64_2',	'Q204_65_2'	,'Q204_66_2'};



for iq = 1:length(qavoid)
    questdat{im}(:,iq) = s.quest.tab.(qavoid{iq});
end
im = im +1;

for iq = 1:length(qfear)
    questdat{im}(:,iq) = s.quest.tab.(qfear{iq});
end
im = im +1;

%% AMI- apathy
% no reverse items
% behavioural: Q5, 9, 10, 11, 12, 15
% social: Q2, 3, 4, 8, 14, 17
% emotional: Q1, 6, 7, 13, 16, 18

qami = {'Q82_1'	,'Q82_2'	,'Q82_3'	,'Q82_4'	,'Q82_5'	,'Q82_6'	,'Q82_7'	,'Q82_8'	,'Q82_9'	,'Q82_10' ,'Q82_12'	,...
    'Q82_13'	,'Q82_14'	,'Q82_15',	'Q82_16',	'Q82_17',	'Q82_18'	,'Q82_19'};


for iq = 1:length(qami)
    questdat{im}(:,iq) = 4 - s.quest.tab.(qami{iq}); % reverse scored all items, so higher number means more apathy
end
im = im +1;



%% BIS
% reverse scores implemented
qbis = {'Q83_1',	'Q83_2'	,'Q83_3',	'Q83_4'	,'Q83_5'	,'Q83_6'	,'Q83_7'	,'Q83_8'	,'Q83_9'	,'Q83_10',	'Q83_11',	'Q83_12',	'Q83_13'	,'Q83_14'	,'Q83_15'	,'Q83_16'	,'Q83_17',...
    'Q83_19',	'Q83_20'	,'Q83_21',	'Q83_22'	,'Q83_23'	,'Q83_24',	'Q83_25',	'Q83_26',	'Q83_27'	,'Q83_28'	,'Q83_29'	,'Q83_30',	'Q83_31'};


revit = [];
revit =[1, 7,8,9,10,12,13,15,20,29,30];

for iq = 1:length(qbis)
    if ismember(iq,revit)==1
        questdat{im}(:,iq) = 5 - s.quest.tab.(qbis{iq});
    else
        questdat{im}(:,iq) = s.quest.tab.(qbis{iq});
    end
end

im = im +1;



%% DASS
% no reverese items
qdass = {'Q84_1',	'Q84_2',	'Q84_3',	'Q84_4',	'Q84_5'	,'Q84_6'	,'Q84_7'	,'Q84_8'	,'Q84_9'	,'Q84_10'	,'Q84_11'	,'Q84_12'	,'Q84_13'	,'Q84_14',	'Q84_15',...
    'Q84_16'	,'Q84_17',	'Q84_18'	,'Q84_19'	,'Q84_20',	'Q84_21',...
    'Q84_22'	,'Q84_23'	,'Q84_24'	,'Q84_25',	'Q84_26'	,'Q84_27',	'Q84_28',	'Q84_29'	,'Q84_30'	,'Q84_31',	'Q84_32'	,'Q84_33'	,'Q84_34',	'Q84_35',...
    'Q84_37'	,'Q84_38'	,'Q84_39'	,'Q84_40',	'Q84_41'	,'Q84_42',	'Q84_43'};



for iq = 1:length(qdass)
    questdat{im}(:,iq) = s.quest.tab.(qdass{iq});
end
im = im +1;

%% schizo
% reverse items
revit =  [26 27 28 30 31 34 37 39];
% Q55_26 Q55_27	Q55_28  Q55_30	Q55_31 Q55_34 Q55_38 Q55_40


dsch = {'Q55_1'	,'Q55_2',	'Q55_3',	'Q55_4',	'Q55_5'	,'Q55_6'	,'Q55_7'	,'Q55_8'	,'Q55_9'	,'Q55_10'	,'Q55_11',	'Q55_12'	,'Q55_13'	,'Q55_14',	'Q55_15',	'Q55_16',	'Q55_17',...
    'Q55_18'	,'Q55_19'	,'Q55_20',	'Q55_21',	'Q55_22',	'Q55_23',	'Q55_24'	,'Q55_25',	'Q55_26',	'Q55_27'	,'Q55_28'	,'Q55_29'	,'Q55_30',	'Q55_31',	'Q55_32'	,'Q55_33'	,'Q55_34',...
    'Q55_35',	'Q55_37',	'Q55_38',	'Q55_39'	,'Q55_40',	'Q55_41'	,'Q55_42',	'Q55_43'	,'Q55_44'};


for iq = 1:length(dsch)
    if ismember(iq,revit)==1
        questdat{im}(:,iq) = 1 - s.quest.tab.(dsch{iq});
    else
        questdat{im}(:,iq) = s.quest.tab.(dsch{iq});
    end
end



for iq = 1:length(dsch)
    questdat{im}(:,iq) = s.quest.tab.(dsch{iq});
end
im = im +1;


%% self-esteem
% reverse items: 2,5,6,8,9
revit = [2,5,6,8,9];
dse = {'Q54_1'	,'Q54_2'	,'Q54_3',	'Q54_4',	'Q54_5'	,'Q54_6', 'Q54_8'	,'Q54_9',	'Q54_10'	,'Q54_11'};

for iq = 1:length(dse)
    if ismember(iq,revit)==1
        questdat{im}(:,iq) = 3 - s.quest.tab.(dse{iq});
    else
        questdat{im}(:,iq) = s.quest.tab.(dse{iq});
    end
end
im = im +1;



%% attention questions:
%figure
attname  = {'OCIR';'LSAS_fear';'LSAS_avoid';'RSS';'SSMS';'DASS';'BIS';'AMI'};
corrit   = [2 3 0 2 0 1 3 0];
attit    = {'Q85_10','x_80_1','x_80_2','Q54_7','Q55_36','Q84_36','Q83_18','Q82_11'};
allincon = [];
for iq = 1:length(attname)
    attdat(:,iq) = s.quest.tab.(attit{iq});
    allincon = [allincon; find( attdat(:,iq) ~= corrit(iq))];
    %subplot(2,4,iq)
   % hist(attdat(:,iq))
end
subnoatt = unique(allincon);
for i = 1:length(allincon)
    many(i) = numel(find(allincon(i)== allincon));
end
moreAfail = unique(allincon(find(many==2)));


%% total scores:

for i = 1:length(questdat)
    toscore(:,i) = sum(questdat{i}');
    
end

%%
s.quest.all = questdat;
s.quest.tot = toscore;
s.quest.name = {'OCIR';'ICAA';'LSAS_fear';'LSAS_avoid';'AMI';'BIS';'DASS';'SSMS';'RSS'};
s.quest.noatt.all = subnoatt;
s.quest.noatt.many = moreAfail;

%%  OCIR subscales:
im = 1;
ocir_ss_names = {'wash';'obs';'hoar';'ord';'cmp';'neut'};
ocir_ss{im} = [5,11,17]; im=im+1;
ocir_ss{im} = [6,12,18]; im=im+1;
ocir_ss{im} = [1,7,13]; im=im+1;
ocir_ss{im} = [3,9,15]; im=im+1;
ocir_ss{im} = [2,8,14]; im=im+1;
ocir_ss{im} = [4,10,16]; im=im+1;

ocirtot =  s.quest.all{1};

for im = 1:length(ocir_ss_names)
    ocir_sub(:,im) = sum(ocirtot(:,ocir_ss{im})');
end
s.quest.ocir_sub.pmat.names = ocir_ss_names;
s.quest.ocir_sub.pmat.mat = ocir_sub;

figure
names =ocir_ss_names;
rcorr = corr(ocir_sub,'Type','Spearman');
N = length(names);
imagesc(rcorr,[-1 1]);hold all;
x = repmat(1:N,N,1); % generate x-coordinates
y = x'; % generate y-coordinates
t = num2cell(round(rcorr,2)); % extact values into cells
t = cellfun(@num2str, t, 'UniformOutput', false); % convert to string
text(x(:), y(:), t, 'HorizontalAlignment', 'Center')
set_default_fig_properties(gca,gcf);hold all;
set(gca,'XTick',1: length(names));
set(gca,'XTickLabel',names,'FontSize',14);
set(gca,'YTick',1: length(names));
set(gca,'YTickLabel',names,'FontSize',14);
xtickangle(45)
colorbar





%% DASS subscale
im = 1;
dass_ss_names = {'dep';'anx';'stress'};
dass_ss{im} = [3, 5, 10, 13, 16, 17, 21, 24, 26, 31, 34, 37, 38, 42]; im=im+1;
dass_ss{im} = [2, 4, 7, 9, 15, 19, 20, 23, 25, 28, 30, 36, 40, 41]; im=im+1;
dass_ss{im} = [1, 6, 8, 11, 12, 14, 18, 22, 27, 29, 32, 33, 35, 39]; im=im+1;
         
dasstot =  s.quest.all{7};

for im = 1:length(dass_ss_names)
    dass_sub(:,im) = sum(dasstot(:,dass_ss{im})');
end
s.quest.dass_sub.pmat.names = dass_ss_names;
s.quest.dass_sub.pmat.mat   = dass_sub;
      

figure
names =dass_ss_names;
rcorr = corr(dass_sub,'Type','Spearman');
N = length(names);
imagesc(rcorr,[-1 1]);hold all;
x = repmat(1:N,N,1); % generate x-coordinates
y = x'; % generate y-coordinates
t = num2cell(round(rcorr,2)); % extact values into cells
t = cellfun(@num2str, t, 'UniformOutput', false); % convert to string
text(x(:), y(:), t, 'HorizontalAlignment', 'Center')
set_default_fig_properties(gca,gcf);hold all;
set(gca,'XTick',1: length(names));
set(gca,'XTickLabel',names,'FontSize',14);
set(gca,'YTick',1: length(names));
set(gca,'YTickLabel',names,'FontSize',14);
xtickangle(45)
colorbar


%% ocir and dass    
figure
names =[dass_ss_names; ocir_ss_names];
rcorr = corr([dass_sub ocir_sub],'Type','Spearman');
N = length(names);
imagesc(rcorr,[-1 1]);hold all;
x = repmat(1:N,N,1); % generate x-coordinates
y = x'; % generate y-coordinates
t = num2cell(round(rcorr,2)); % extact values into cells
t = cellfun(@num2str, t, 'UniformOutput', false); % convert to string
text(x(:), y(:), t, 'HorizontalAlignment', 'Center')
set_default_fig_properties(gca,gcf);hold all;
set(gca,'XTick',1: length(names));
set(gca,'XTickLabel',names,'FontSize',14);
set(gca,'YTick',1: length(names));
set(gca,'YTickLabel',names,'FontSize',14);
xtickangle(45)
colorbar




%% correlation across subscales
%
if doplot(1)==1

    
    figure
    names = s.quest.name;
    var = [];
    rcorr = corr([dass_sub ],'Type','Spearman');
    N = length(names);
    imagesc(rcorr,[-1 1]);hold all;
    x = repmat(1:N,N,1); % generate x-coordinates
    y = x'; % generate y-coordinates
    t = num2cell(round(rcorr,2)); % extact values into cells
    t = cellfun(@num2str, t, 'UniformOutput', false); % convert to string
    text(x(:), y(:), t, 'HorizontalAlignment', 'Center')
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'XTick',1: length(names));
    set(gca,'XTickLabel',names,'FontSize',14);
    set(gca,'YTick',1: length(names));
    set(gca,'YTickLabel',names,'FontSize',14);
    xtickangle(45)
    colorbar
    
    
    
    
end


keyboard

%% save as individual questionnaires into csv file --> for R
allmat=[];
%
newmat = s.quest.all;
newmat(2)=[];

newname = s.quest.name;
newname(2)=[];

for iq = 1:length(newname)
    curmat = [1:size(newmat{iq},2) ;newmat{iq}];
    allmat = [allmat curmat];
end
%
csvwrite('behStudy_questdat_new.csv', allmat)


end