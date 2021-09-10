function [DataInte] = DREADDs_Control_Day1_4_7_behavior_and_neuroSignal_integration(F,spks,iscell)

% 'VR_Excel_Rearrangement_Dec_2017_Ver02.m'
% merging behavior and neuronal data 

%% variable initialization

    % user determined variable
    which_animal = 1;           % manually change animalID at this stage

    % basic info. initialization
    animalID_allAnimal = {'13118','13696','13775','13776','14228'};
    param.animalID = animalID_allAnimal{which_animal};   
    param.day = 'day1+4+7';
    param.animalID_day = [param.animalID,'-',param.day];
    param.trialNum_limit = [19,14,14];        % max number of trial; day1: 19, day4: 14, day7: 14
    DataInte = {'Animal','Cell #','Treatment','Session','Context','Reward','Trial #','Times(s)','Position(mm)','Velocity(mm/s)','mean dF/F','mean spike'};
    
    % neuronal signal data initialization
    % frame number in 13118 - day1,4,7 = [13878, 11425, 13236];
    % frame number in 13696 - day1,4,7 = [15730, 11033, 14599];
    % frame number in 13775 - day1,4,7 = [13656, 14952, 11727];
    % frame number in 13776 - day1,4,7 = [13084, 13906, 13032];
    frame_num_allAnimal = [13878, 11425, 13236; 15730, 11033, 14599; ...
                           13656, 14952, 11727; 13084, 13906, 13032];
    rescaled_F = cell(1,3); rescaled_spike = cell(1,3);     % signal in day1,4,7 will be stored in each column
    
    % behavior data initialization
    param.CorFlag = [0, 200, 400];              % corridor flag, each number depicts different corridors
    param.XPosEndLimit = 1800;                  % distance limit of x-position in corridor when a mouse finish running in a trial; we assume that length of corridor is 1800mm
    param.XPosStartLimit = 600;                 % distance limit of x-position in corridor when a mouse start running in a trial
    param.XPosStart = 0;                        % start point in X-Position
    param.XPosRange = 10;                       % range of x-position in corridor; this parameter is used when we draw heat-map
    param.XPosEnd = 1800 - param.XPosRange;     % end range of x-position in corridor; this parameter is used when we draw heat-map
    behavior_data = cell(1,3);                  % behavior data(animal movement in the VR) in day1,4,7 will be stored in each column
    
%% signal re-scaling
    
    % two-photon image data was analyzed (by Suite2p) and the 
    % result data(such as, '\13118-day1+4+7-image analyzed\plane0\Fall.mat') 
    % is already loaded in MATLAB manually

    % signal is merged from day1 to day7 and it is required to signal
    % re-scaling in each day

    for dayIter = 1:1:3             % Day 1, 4, 7
        if isequal(dayIter,1)       % in day1
           frame_num = 1:frame_num_allAnimal(which_animal,dayIter);
        else                        % in day4/7
           frame_num = frame_num(end)+1:frame_num(end)+frame_num_allAnimal(which_animal,dayIter);
        end

        % select signal by day
        %
        % iscell:
        % 1st col: 1/0(= True/False), 1: cell, 0: not cell
        % 
        % F/spks (= raw flourescence signal/spikes(deconvolved signal):
        % number of row: number of cell, number of columns: total number of frame
        raw_signal_by_day = F(logical(iscell(:,1)),frame_num);
        raw_spks_by_day = spks(logical(iscell(:,1)),frame_num);

        % min-max scaling by day
        rescaled_signal = min_max_scaling(raw_signal_by_day);      % min-max scaling, see 'IS_lib' folder
        rescaled_spks = min_max_scaling(raw_spks_by_day);

        % merging re-scaled data into a variable
        rescaled_F{1,dayIter} = rescaled_signal;
        rescaled_spike{1,dayIter} = rescaled_spks;
    end

%% import behavior data

    % Raw Data Structure(*.xls or *.xlsx file)
    % 1st column: time(sec), 2nd: x-position in corridor(mm), 3rd: corridor flag(seperated 3 corridors-0,200,400)
    % 4th: 2PM trigger number(not corrected)
    % * Usually x-position starts 0 and ends around 1800 but not always
    for dayIter = 1:1:3
        behavior_data{1,dayIter} = VR_Excel_Rearrangement_importData;
    end

%% data preprocessing

    % 1) searching for a start/end point
    % searching condition(start): time(in 1st col) & trigger(in 4th col) are not '0', plus, consider an issue below

    % 0         0   0     0
    % 2.9370    0   0   631
    % 3.0250    0   0   631
    % 3.2200    0   0     0
    % ......    ......
    % 8.5960    518 0     1 
    %
    % here, 631 in 4th coloumn is an issue to be ignored

    % searching condition(end): the maximum value which trigger(in 4th col) is not '0'

    % 2) seperation trials in each corridor table
    % first all, to calculate difference between neighbor x position in each row, such as (x position in row1 - row2), (x position in row2 - row3), so on.
    % next, to find index whose value is bigger than 1500 in 2nd column where depicts x position.
    % consequently, the variable 'trial_mark_tableN' includes index value which depicts new trial

    % 3) data correction of unusual condition, such as 
    %   i) 1.0(time) 1800(x-pos) 0(corridor) 
    %  ii) 1.1       1800        200  <- must be '0'
    % iii) 1.2       0           200
    % 
    % compare end index and second end index of each trial, for example,
    % compare i) and ii) index above and put correct corridor flag into 1) index

    % 4) conversion from trigger to frame number
    % trigger is increased by 4 times, therefore, we need convert it into the serial number of frame
    % such as, trigger number is [1000, 1003, 1007, 1010..] and it must be converted into [250,251,252,253...]

    % 5) to get rid of duplicated number of frame on DataTable1
    % if there is duplicate value, then we delete & overwrite that with next data
    % for example, (converted) frame number is [250,251,251,253,254,...], then,
    % we have got a duplicated number, 251 in 2nd & 3rd element

    % 6) interpolate absence number of frame

    % 7) calculation of velocity between frames
    for dayIter = 1:1:3
        [behavior_data{1,dayIter}, ~] = VR_Excel_Rearrangement_preprocessing(behavior_data{1,dayIter},param);    
    end

%% merging(synchronizing) raw data of VR with fluorescence data

    [DataInte] = merge_behavior_neuroSignal(behavior_data,rescaled_F,rescaled_spike,DataInte,param);
    
end

function [DataInte] = merge_behavior_neuroSignal(behavior_data,rescaled_F,rescaled_spike,DataInte,param)

%% variable initialization

    animalID = param.animalID;
    CorFlag = param.CorFlag;
    num_cell = size(rescaled_F{1,1},1);
    day = param.day;
    trialNum_limit = param.trialNum_limit;
    
    frameNum_col = 5; ctxt_col = 3; DataInte_ctxt_col = 5;
    DataInte_trial_col = 7; DataInte_time_col = 8;
    DataInte_pos_col = 9; DataInte_spd_col = 10; DataInte_avgSig_col = 11; 
    DataInte_avgSpk_col = 12;
        
    % merging(synchronizing) behavior data with neuronal signal  
    DataInte_len = size(DataInte,2);

    for cellIter = 1:1:num_cell
        DataInte{1,end+1} = ['cell',num2str(cellIter)];
        DataInte{1,end+1} = ['cell',num2str(cellIter),' spike'];
    end
    
    % input simple information into 'DataInte' variable
    % Data structure of 'DataInte': {'Animal','Cell #','Treatment','Session','Context','Reward','Trial #','Times(s)','Position(mm)','Velocity(mm/s)','mean dF/F','mean spike'};
    DataInte{2,1} = animalID;
    DataInte{2,2} = size(rescaled_F{1,1},1);
    DataInte{2,4} = day;
    
    % for counting trial numbers
    % trial no. increases when only trial flag is changed 
    cntTrialNos = [0,0,0];      % trial no in context1, 2, 3 
    trialFlag = 0;              % trial flag depicts whether change current trial no.
    
%% data management

    for dayIter = 1:1:3
        if isequal(dayIter,1)
            trialNum_limit_1day = trialNum_limit(dayIter);
        else
            trialNum_limit_1day = trialNum_limit_1day + trialNum_limit(dayIter);
        end
        
        % rescaled_F/spik (= raw flourescence signal/spikes(deconvolved signal):
        % number of row: number of cell, number of columns: total number of frame
        behavior_data_1day = behavior_data{1,dayIter};
        rescaled_F_1day = rescaled_F{1,dayIter};
        rescaled_spike_1day = rescaled_spike{1,dayIter};
        
        % the first frame number in behavior_data is different from the rescaled_F
        % therefore, we have to synchronize the frame numbers between of them
        sync_Startpt = behavior_data_1day(1,frameNum_col);  
        if behavior_data_1day(end,5) >= size(rescaled_F_1day,2)   % there is difference between number of 2PM imaging frame and VR system
            sync_Endpt = size(rescaled_F_1day,2);
        else
            sync_Endpt = behavior_data_1day(end,frameNum_col);
        end

        rescaled_F_1day = rescaled_F_1day(:,sync_Startpt:sync_Endpt);           % rearrange data for the range synchronization between behavior & neuronal signal
        rescaled_spike_1day = rescaled_spike_1day(:,sync_Startpt:sync_Endpt);   % rearrange data   
    
        if isequal(dayIter,1)       % in day1
           dt_size_offset = 0;
        else                        % in day4/7
           dt_size_offset = size(DataInte,1)-1;
        end
            
        % input VR experiment result data into 'DataInte' variable
        % caution: # of cells in row and series of data in column in rescaled_F/spike
        % therefore, be careful data structure when we manage variables mentioned above 
        for frameIter = 1:1:size(rescaled_F_1day,2)      % row # in 'DataInte' 
            if cntTrialNos(find(behavior_data_1day(frameIter,ctxt_col) == CorFlag))==trialNum_limit_1day
                disp('trial number limit. dummy breakpoints') 
            end
            
            if cntTrialNos(find(behavior_data_1day(frameIter,ctxt_col) == CorFlag)) <= trialNum_limit_1day
                % trial number changing condition
                if (frameIter > 1) && ((behavior_data_1day(frameIter-1,2)-behavior_data_1day(frameIter,2))>1500)
                   trialFlag = 1; 
                end

                switch find(behavior_data_1day(frameIter,ctxt_col) == CorFlag)    % Context: 1: corridor1, 2: corr2, 3: corr3
                    case 1 
                        if cntTrialNos(1) <= trialNum_limit_1day 
                            DataInte{(frameIter+dt_size_offset)+1,DataInte_ctxt_col} = 1;
                            if isequal(frameIter,1) & isequal(dayIter,1)
                                cntTrialNos(1) = 1;
                            end
                            if isequal(trialFlag,1)  % check context flag and counting trial no
                                trialFlag = 0; 
                                cntTrialNos(1) = cntTrialNos(1) + 1;
                            end
                            DataInte{(frameIter+dt_size_offset)+1,DataInte_trial_col} = cntTrialNos(1);    % 'Trial #'
                        end

                    case 2
                        if cntTrialNos(2) <= trialNum_limit_1day 
                            DataInte{(frameIter+dt_size_offset)+1,DataInte_ctxt_col} = 2;
                            if isequal(frameIter,1) & isequal(dayIter,1)
                                cntTrialNos(2) = 1;
                            end
                            if isequal(trialFlag,1)
                                trialFlag = 0; 
                                cntTrialNos(2) = cntTrialNos(2) + 1;
                            end
                            DataInte{(frameIter+dt_size_offset)+1,DataInte_trial_col} = cntTrialNos(2);
                        end

                    case 3
                        if cntTrialNos(3) <= trialNum_limit_1day 
                            DataInte{(frameIter+dt_size_offset)+1,DataInte_ctxt_col} = 3;
                            if isequal(frameIter,1) & isequal(dayIter,1)
                                cntTrialNos(3) = 1;
                            end
                            if isequal(trialFlag,1)
                                trialFlag = 0; 
                                cntTrialNos(3) = cntTrialNos(3) + 1;
                            end
                            DataInte{(frameIter+dt_size_offset)+1,DataInte_trial_col} = cntTrialNos(3);
                        end
                end

            
                DataInte{(frameIter+dt_size_offset)+1,DataInte_time_col} = behavior_data_1day(frameIter,1);           % 'Time(s)'
                DataInte{(frameIter+dt_size_offset)+1,DataInte_pos_col} = behavior_data_1day(frameIter,2);            % 'Position(mm)'
                DataInte{(frameIter+dt_size_offset)+1,DataInte_spd_col} = behavior_data_1day(frameIter,6);            % 'Velocity(mm/s)'
                DataInte{(frameIter+dt_size_offset)+1,DataInte_avgSig_col} = mean(rescaled_F_1day(:,frameIter));      % mean dF/F per frame
                DataInte{(frameIter+dt_size_offset)+1,DataInte_avgSpk_col} = mean(rescaled_spike_1day(:,frameIter));  % mean spike per frame

                for iter = 1:1:size(rescaled_F_1day,1)      % cell # in rescaled_F_1day & rescaled_spike_1day
                    DataInte{(frameIter+dt_size_offset)+1,DataInte_len+(2*(iter-1))+1} = rescaled_F_1day(iter,frameIter);
                    DataInte{(frameIter+dt_size_offset)+1,DataInte_len+(2*(iter-1))+2} = rescaled_spike_1day(iter,frameIter);
                end
            end
            
        end
        
        trialFlag = 0;              % trial flag depicts whether change current trial no.
    end
    
end
