%% sets up environment
% loads data
% gets necessary variables for later analyses

% --------------------------------------------------------------------------------
%% create new datafile
% --------------------------------------------------------------------------------

if iload ==1
    
    %% get data
    % --------------------------------------------------------------------------------
    % load data
    % here, loads all pilot versions
    
    s = readdat(s,pilotID);

    
    
    
    %% save:
    
   % save(['s_data_behavstud' num2str(pilotID) '_' date],'s','-v7.3')
    
    
    
 elseif iload ==0   
    % --------------------------------------------------------------------------------
    %% load previous data set
    % --------------------------------------------------------------------------------
    

    % load('s_data_pilotNr502-Aug-2022.mat')
    %load('s_data_pilotNr513-Oct-2022.mat')
    % load('s_data_behavstud.mat')
    
    % round1:
    % load('s_data_behavstud628-Nov-2022')
    
    % round 2, N =111, study 1
    % load('s_data_behavstud6_12-Dec-2022')
    % large online study, run2:
    %load('s_data_behavstud7_24-Feb-2023')
    
    % --- study 2:
    % large online study, N=86
    %load('s_data_behavstud7_27-Feb-2023')
    
    % large online study, N=100
    %load('s_data_behavstud7_28-Feb-2023')
    
    % large online study, N=160
    load('s_data_behavstud7_02-Mar-2023')
end

% --------------------------------------------------------------------------------
% get schedule info
s = setrelev(s);

%% prep data: format data into phases
for is = 1:length(s.subID)
  s = formatdat(s,is,choice4);
end


%% coding check

for is = 1:length(s.subID)
    s = checkdat(s,is,choice4);
end

%% final pmat:
% mat file with all relevant variables for further analyses
s = getpmat(s);

%% loads questionnaire data from qualtrics
if pilotID == 7
    s = loadQuest(s,0);
end


