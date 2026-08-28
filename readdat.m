function [s] = readdat(s,pID)
%
%   input files:
%               -
%               - pavlovia
%               -
%

%% pilot ID:

if pID == 1
    pathname = ['data/pilot1_Jan21'];
elseif pID == 2
    pathname = ['data/pilot2/pilot_prolific_Feb22'];
elseif pID ==3
    pathname = ['data/pilot2/pilot_prolific_08Feb22'];
elseif pID == 4
    pathname = ['data/pilot3/pilot_prolific_15Feb'];
elseif pID == 5
    pathname = ['data/pilot4_exp/pilot_prolific_26April'];
    
elseif pID == 6
    pathname = ['data/behav_study/'];
 elseif pID == 7
    pathname = ['data/large_onlineStudy_Feb23/'];
    elseif pID == 8
    pathname = ['data/pilot5_neutralstim_test/'];   
end

cd (pathname)


%% 1. In-person data collection (lab people):

if pID ==1
    
    subID=[];
    subfile={'001_exp_v4_2022-01-25_14h56.20.143.csv','002_exp_v4_2022-01-25_10h48.30.981.csv','S003_exp_v4_2022-01-26_17h56.43.874.csv','S004_exp_v4_2022-01-26_17h55.21.979.csv'};
    
    
    
    for i = 1:length(subfile)
        if i<9
            cursub   = {['S00' num2str(i)]};
        elseif i>9
            cursub   = {['S0' num2str(i)]};
        end
        subID = [subID, cursub];
    end
    
    
    s.subID = subID;
    
    vars = {};
    
    opt = []; T =[];
    for isub = 1:length(subID)
        opts = detectImportOptions(subfile{isub},'NumHeaderLines',0);
        T    = readtable(subfile{isub},opts);
        
        
        % ------- variables of interest:
        paths   = {'allpic_filename';'pred_path';'opt_path';'FBnew_choicepath'};
        vars    = {'end_all_time';'session'};
        treevar = {'index';'selected_picID';'out_corrAns';'tr_accuracy';'allpicRT';'pic1';'pic2';'pic3';'pic4';'pic5';'pic6';'pic7';'pic8';'pic9';'pic10';...
            'pic11';};
        
        chvar   = {'pred_ID';'opt_ID';'opt_choiceRT';'curpayoff';'FB_optchoice';'allFB';'FBdur';'switchseq'};
        rsbvar  = {'rsbRT';'rsbimage';'space_resp_rt';'photoID'};
        debriefvar = {'debrief_slider_rt';'debrief_slider_response'};
        allvar=[];
        allvar =  [vars ; treevar;chvar ;rsbvar; debriefvar];
        
        
        instr.table       = T;
        instr.names       = allvar;
        
        
        % ------- save:
        s.sub{isub}.instr          = instr;
        
    end
end


%% Pilot on Prolific


if pID >1
    %% 1. demographics:
    cd demographics
    
    if pID == 2
        datacsv = 'prolific_export_61fff04022c23c2de0d23ae6.csv';
    elseif pID == 3
        datacsv = 'prolific_export_6200f3743798bebe3d93c94c.csv';
    elseif pID == 4
        datacsv = 'prolific_export_620bbe3c495875ca6ece3390.csv';
    elseif pID == 5
        
        datacsv= 'prolific_export_6261317e47b8fcb97ed9480e.csv';
        
    elseif pID == 6
        
        datacsv= 'prolific_export_637cfb0d658f097693696d4e.csv';
    elseif pID == 7
        
        datacsv= 'prolific_export_63ece351a25eb00088fe8a1f.csv';
    elseif pID == 8
                datacsv= 'prolific_export_6475dcecefe35c3fecb58536.csv';

    end
    
    % 1. properties of file:
    opts = detectImportOptions(datacsv,'NumHeaderLines',0);
    T    = readtable(datacsv,opts);
    
    % 2. variable names/ header:
    varnames        = T.Properties.VariableNames';
    
    getsub=[];
   
    for i = 1:length(T.Status)
        
       if strcmp(T.CompletionCode{i},'77437CED')==1 
       %if strcmp(T.Status{i},'APPROVED')==1 
            getsub = [getsub;i];
        end
    end
   
    
    
    
           
    % some people completed experiment, but did get a no-code
    % include them here:
    if pID == 7
        
        
        picksubs = {'6277127cab20267323378b3b';
            '5ba1a06b0686690001f514ae';
            '60fac7ec133b6bf250d6d668';
            '5b215df1df28a7000166f497';
            '5c4852b342213c0001f5967a';
            '62cc66d7db7262253e778d5d';
            '5ec6be322a1c090e1f681ed5';
            '63b844da85fc3b1d33b69ecc';
            '62962018b1bef67edfd5718e';
            '63d15ee3d6cacf7e94f8c102';
            '60e2f29d1b210b7492202572';
            '5d5ee60d8c0a07001719f9dd';
            '6329cf9aff421956acd033e9';
            '59b69d4fb269ef0001801733';
            '636a552ed7ba6f6ecc5c3dc9';
            '63d508e7cfc3204304a949e2';
            '5f0219dce0d2de3a5179d1aa';
            '639b9b047b98a3d09a77a6c6';
            };

        for isc = 1:length(picksubs)
            getsub = [getsub; find(ismember(T.ParticipantId,picksubs{isc})==1)];
        end
        getsub= sort(getsub,'ascend');
    end
    
    
    %% exclude these people:
    if pID==7
        
        tmpsu = T.ParticipantId(getsub);
        
        
        exclude={'597095d3db808600019d603e';
            '63e51e063af1cc5baf0c72ca';
            '60edb4bc87206e9977d8d57e';
            '63d40228c2fb877b0bfe84ec';
            '58aca85e0da7f10001de92d4';
            '60e2f29d1b210b7492202572';
            '615244e111aefca2b42a35f9';
            '5c4f7f31bb73b80001e5e8b7';
            '60d33d90bfc3eb89147053d1';
            '63d7ed23658859de19d2bd66';
            '607081b0ecb2499634a349dd'};
        
        
        for i = 1:length(exclude)
            exID(i) = find(strcmp(tmpsu,exclude{i})==1);
            
        end
       
        getsub(exID,:) = [];
        
        
        
    end
    
    
    
    if pID == 4
        disp('exclude 1 outlier')
        getsub(5)=[];
        getsub(12)=[];
        getsub(3)=[];
    elseif pID==5
        getsub(1)=[];
       % getsub(8)=[];
       % getsub(11)=[];
    end
    
    
    s.subID         = T.ParticipantId(getsub);
    s.demo.table    = T(getsub,:);
    s.demo.names    = varnames;
    
    
    cd ../pavlovia
    
    
    
    for isub = 1:length(s.subID)
        
        % get file:
        subdir =[]; subdir = dir([s.subID{isub} '*.csv']);
        if pID == 4
            subdir =[]; subdir = dir(['data_' s.subID{isub} '*.csv']);
        end
        
        if pID == 5
            
            %curpath= ['data_' num2str(s.subID{isub}) '*'];
            curpath= [num2str(s.subID{isub}) '*.csv'];
            subdir = dir(fullfile(curpath));
        end
        
        % check whether there are two files 
        if pID == 6 || pID == 7
            curpath= [num2str(s.subID{isub}) '*.csv'];
            subdir = dir(fullfile(curpath));
            if numel(subdir)>1 % 2 files saved
                
                pickfile=NaN;
                % check which one has the variable total_time = complete
                % data set
                
                for i = 1:length(subdir)
                filecsv = subdir(i).name;
                % ---- all data:
                opts=[];opts = detectImportOptions(filecsv,'NumHeaderLines',0);
                curmat=[];curmat    = readtable(filecsv,opts);
                curnames=[];curnames = curmat.Properties.VariableNames';
                if sum(ismember(curnames,'total_time'))==1, pickfile = i; end
                
                end 
                subdir = subdir(pickfile);
                
                
            end   
        end
        
       
        filecsv = subdir.name;
        % ---- all data:
        opts=[];opts = detectImportOptions(filecsv,'NumHeaderLines',0);
        curmat=[];curmat    = readtable(filecsv,opts);
        curnames=[];curnames = curmat.Properties.VariableNames';
        
        s.sub{isub}.sched = curmat.sched(1);
        
        cd ../schedule
        if pID ==2
            if curmat.sched(1) ==1
                schedmat = load('data_sched1_04-Feb-2022.mat');
            elseif curmat.sched(1)==2
                schedmat = load('data_sched2_04-Feb-2022.mat');
            elseif curmat.sched(1)==2
                schedmat = load('data_sched3_04-Feb-2022.mat');
            elseif curmat.sched(1)==2
                schedmat = load('data_sched4_04-Feb-2022.mat');
            end
            
        elseif pID ==3
            
            if curmat.sched(1) ==1
                schedmat = load('data_sched1_08-Feb-2022.mat');
            elseif curmat.sched(1)==2
                schedmat = load('data_sched2_08-Feb-2022.mat');
            elseif curmat.sched(1)==2
                schedmat = load('data_sched3_08-Feb-2022.mat');
            elseif curmat.sched(1)==2
                schedmat = load('data_sched4_08-Feb-2022.mat');
            end
            
        elseif pID == 4
            if curmat.sched(1) ==1
                schedmat = load('data_sched1_15-Feb-2022.mat');
            elseif curmat.sched(1)==2
                schedmat = load('data_sched2_15-Feb-2022.mat');
            end
            
        elseif pID == 5
            if isub <5
                if curmat.sched(1) ==1
                    schedmat = load('data_sched1_21-Apr-2022.mat');
                end
                
            else
                
                % add schedule
                if curmat.sched(1) ==1
                    schedmat = load('data_sched1_10-May-2022.mat');
                elseif curmat.sched(1)==2
                    schedmat = load('data_sched2_10-May-2022.mat');
                end
            end
        end
        
        if pID == 6
            if curmat.sched(1) ==1
                schedmat = load('data_sched1_10-May-2022.mat');
            elseif curmat.sched(1)==2
                schedmat = load('data_sched2_10-May-2022.mat');
            end
        end
        if pID == 7 || pID == 8
            if curmat.sched(1) ==1
                schedmat = load('data_sched1_10-May-2022.mat');
            elseif curmat.sched(1)==2
                schedmat = load('data_sched2_10-May-2022.mat');
            end
        end
        
        
        cd ../pavlovia
        
       
        
        %%
        % --- schedule:
        snames = {'allpic_def1';'allpic_def2';'allpic_change';'allpic_final_1';'allpic_final_2';'corrAns';'pic1';'pic2';'pic3';'pic4';'pic5';'pic6';'pic7';'pic8';'pic9';'pic10';'pic11'};
        
        
        
        
        
        % --- data:
        % indices are : choice_pred_1 (4 choices), choice_pred_2,3=data
        dnames = {'end_all_time';'session';...
            'out_corrAns';'tr_accuracy';'allpicRT';'selected_picID';...
            'index_opt';'pred_ID';'opt_ID';'opt_choiceRT';'curpayoff';'FB_optchoice';'allFB';'FBdur';'switchseq';...
            'debrief_slider_rt';'debrief_slider_response'};
        
        
        % save data:
        instr.table       = curmat;
        instr.names       = dnames;
        instr.tablenames  = instr.table.Properties.VariableNames';

        s.sub{isub}.instr = instr;
        s.sub{isub}.sched = schedmat;
        s.sub{isub}.schedidx = curmat.sched(1);
        s.sub{isub}.choice4 =0;
        
    end
    
    
    
end

cd ../../..
end