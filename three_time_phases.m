function [timeDataTable_DA, bigTable2_DA] = three_time_phases(ctxtData, bigTable2_DA, param,param_sub)
                
% three time phases: i) 1700-(1st)1790, ii) licking time; (2nd)1790-before 3sec interval, iii) 3sec interval,
% iv) 1sec before 3sec interval
% essen_pos_idx var. will stores essential position information following three time phases

%% data initialization

% ctxtData includes a specific context data from one day, one animal
% ctxtData: ['Trial #', 'Time', 'X-pos', 'Velocity', and 'Selected cells' dF/F,'in cell2', ... 'in celln'];
[~,ctxtData_col] = size(ctxtData);

% we have to calculate the Discriminant Analysis (DA) using XLSTAT in excel
% thus here we organize data through three time phases described above, 
% which is compatible to excel sheet

% timeDataTable_DA:    
% save data re-organized by licking time info, 
%
% param.time_phase_mode = 1/2/3: data table has only one specific time phase data
% param.time_phase_mode = 1: anticipation area, 2: licking time, 3: 3sec. interval time phase
% 1st col: time bin, 2nd: context, 3rd: trial, 4th: reward(1/0), 
% 5th: weight(1/2), 6th to end: cell dF/F 
%
% param.time_phase_mode = 4: data table has all time phase data
% 1st col: time range(1: licking time/2: 1700-1800mm/3: 3sec interval), 
% 2nd: time bin#, 3rd: context#. 4th: trial#. 5th: reward(True:1/False:0), 6th: weight(0/2), 6th to end: mean dF/F all cells 

timeDataTable_DA = data_init(param_sub.time_phase_mode,ctxtData_col);    % private function

% param is from calling function, and param_sub is for using in this function
essen_pos_idx = param.essen_pos_idx;
trial_lim = param.trial_lim;
param_sub.time_mode = param_sub.time_mode;
param_sub.min_lick_time = param_sub.min_lick_time;
param_sub.min_anti_time = param_sub.min_anti_time;
param_sub.min_threeSec_time = param_sub.min_threeSec_time;
param_sub.time_phase_mode = param_sub.time_phase_mode;
param_sub.timeBin_Dur = param_sub.timeBin_Dur;

param_sub.xPos_offset = param.xPos_offset;
param_sub.dayIter = param.dayIter;
param_sub.miceIter = param.miceIter;
param_sub.ctxtIter = param.ctxtIter;
param_sub.bigTable_idx = param_sub.bigTable_idx;
param_sub.time_bin_organization_mode = param_sub.time_bin_organization_mode;

% day1 doesn't have licking time but day4 and 7 have
% 1) case of licking time(on day4 & 7): essen_pos_idx(3) < essen_pos_idx(4)
% 2) case of non-licking time(on day1): essen_pos_idx(3) >= essen_pos_idx(4)
rewardCol = 0; weightCol = 1;
if isequal(param.dayIter,2)       % dayIter=2, DREADDs Control: day4, DREADDs: day4
    if isequal(param.ctxtIter,1)  % reward context: day4 context1
        rewardCol = 1;
        weightCol = 2;
    end
elseif isequal(param.dayIter,3)   % dayIter=3, DREADDs Control: day7; dayIter=6, DREADDs: day12
    if isequal(param.ctxtIter,2)  % reward context: day7 context2
        rewardCol = 1;
        weightCol = 2;
    end
end

param_sub.rewardCol = rewardCol;
param_sub.weightCol = weightCol;
    
%% data handling 

% ctxtData includes a specific context data from one day, one animal
% ctxtData: ['Trial #', 'Time', 'X-pos', 'Velocity', and 'Selected cells' dF/F,'in cell2', ... 'in celln'];
for trialItr = 1:1:max(ctxtData(:,1))   

    if trialItr <= trial_lim(param_sub.dayIter)       % each day has different number of trial
        trialIdx = find(ctxtData(:,1) == trialItr);
        
        if ~isempty(trialIdx) && (ctxtData(trialIdx(end),3)>= param_sub.xPos_offset)   % few trial data has unfinished trial
            % xPos_offset stands for anticipation area criteria 
            %
            % essen_pos_idx contains accumulated essential position index of all trials
            % 1st: start position of each trial, 2nd: position index of 1700, 3rd: 1st 1790, 
            % 4th: starting position index of 3 sec. interval, 5th: end position index of 1790
            eachTrialTable = ctxtData(trialIdx,:);
                                    
            param_sub.essen_pos_idx = essen_pos_idx(trialItr,:)-essen_pos_idx(trialItr,1)+1;
            param_sub.trialItr = trialItr;
                     
            % time_phase_mode = 1/2/3/32: data table has only one specific time phase data
            % time_phase_mode = 1: anticipation area, 2: licking time, 3: 3sec. interval time phase
            % time_phase_mode = 31: 1sec. before 3sec. interval time phase
            %
            % time_phase_mode = 5: data table has all time phase data            
            if isequal(param_sub.time_phase_mode,1) | isequal(param_sub.time_phase_mode,4)
                % i) anticipation area time phase
                % 1700 - (1st) 1790mm
                if isequal(param_sub.time_phase_mode,4)
                    param_sub.which_phase = 1;
                end
                timeDataTable_DA = antiArea_time_phase(param_sub,eachTrialTable,timeDataTable_DA);
            end
            
            if isequal(param_sub.time_phase_mode,2) | isequal(param_sub.time_phase_mode,4)
                % ii) licking time phase
                % day1 doesn't have licking time but day4 and 7 have
                % 1) case of licking time(on day4 & 7): essen_pos_idx(3) < essen_pos_idx(4)
                % 2) case of non-licking time(on day1): essen_pos_idx(3) >= essen_pos_idx(4)
                if essen_pos_idx(trialItr,3) < essen_pos_idx(trialItr,4)          % licking time(on day4 and 7)
                    if isequal(param_sub.time_phase_mode,4)
                        param_sub.which_phase = 2;
                    end
                    timeDataTable_DA = licking_time_phase(param_sub,eachTrialTable,timeDataTable_DA);
                end
            end

            if isequal(param_sub.time_phase_mode,3) | isequal(param_sub.time_phase_mode,4) | isequal(param_sub.time_phase_mode,31)
                % iii) 3sec. interval or iv) 1sec. before 3sec. interval
                if isequal(param_sub.time_phase_mode,4)
                    param_sub.which_phase = 3;
                end
                timeDataTable_DA = threeSecIntvl_time_phase(param_sub,eachTrialTable,timeDataTable_DA);    
            end

        end
    end
end

bigTable2_DA{param_sub.bigTable_idx,param_sub.ctxtIter} = timeDataTable_DA;
% data re-organization: three_time_range.m    

end

function [timeDataTable_DA] = data_init(time_phase_mode,ctxtData_col)

    % time_phase_mode = 1/2/3: data table has only one specific time phase data
    % time_phase_mode = 1: anticipation area, 2: licking time, 3: 3sec. interval time phase
    %
    % time_phase_mode = 4: data table has all time phase data            
    if isequal(time_phase_mode,1) | isequal(time_phase_mode,2) | isequal(time_phase_mode,3) | isequal(time_phase_mode,31)      
        % timeDataTable_DA:    
        % save data re-organized by licking time info, 
        % 1st col: time bin, 2nd: context, 3rd: trial, 4th: reward(1/0), 
        % 5th: weight(1/2), 6th to end: cell dF/F 
        timeDataTable_DA = {'time bin','context','trial','reward(True/False)','weight',};  

    elseif isequal(time_phase_mode,4)    
        % timeDataTable_DA:   
        % save data re-organized by licking time info, 1st col: time range(1: licking time/2: 1700-1800mm/3: 3sec interval), 
        % 2nd: time bin#, 3rd: context#. 4th: trial#. 5th: reward(True:1/False:0), 6th: weight(0/2), 6th to end: mean dF/F all cells 
        timeDataTable_DA = {'time range','time bin','context','trial','reward(True/False)','weight',};
    end
    
    for iter = 1:1:ctxtData_col-4
        txt = ['dF/F cell',num2str(iter)];
        timeDataTable_DA = [timeDataTable_DA, txt];
    end

end

function [timeDataTable_DA] = licking_time_phase(param_sub,eachTrialTable,timeDataTable_DA)

    % ii) licking time phase
    essen_pos_idx = param_sub.essen_pos_idx;
    timeBin_Dur = param_sub.timeBin_Dur;
    time_mode = param_sub.time_mode;
    min_lick_time = param_sub.min_lick_time;
    
    % time_mode = 1: normal mode - using general time period in each time phase
    % tiem_mode = 2: min time mode - using min time period in each time phase
    %
    % essen_pos_idx:
    % 1st: start position of each trial, 2nd: position index of 1700, 3rd: 1st 1790, 
    % 4th: starting position index of 3 sec. interval, 5th: end position index of 1790
    if isequal(time_mode,1)
        lick_end = eachTrialTable(essen_pos_idx(4),2);                  % licking time end
    
    elseif isequal(time_mode,2)
        % 2nd 1790's time+min_licking time must be less than starting time of 3sec. interval
        if eachTrialTable(essen_pos_idx(3)+1,2)+min_lick_time < eachTrialTable(essen_pos_idx(4),2)
            lick_end = eachTrialTable(essen_pos_idx(3)+1,2)+min_lick_time;      % licking time end = lick time start + min_lick_time
        % otherwise, we set lick_end as its time period own
        else
            lick_end = eachTrialTable(essen_pos_idx(4),2);
        end
        
    end
    lick_st = eachTrialTable(essen_pos_idx(3)+1,2);     % licking time start
    lickTimeBin = lick_st:timeBin_Dur:lick_end;         % licking time start, +0.1, +0.2, ... , licking time end (sec)
    if lickTimeBin(end) < lick_end                      % just in case, we add correct lick time end if condition works
        lickTimeBin = [lickTimeBin lick_end]; 
    end
    
    % timeDataTable_DA:    
    % save data re-organized by licking time info, 
    %
    % time_phase_mode = 1/2/3: data table has only one specific time phase data
    % time_phase_mode = 1: anticipation area, 2: licking time, 3: 3sec. interval time phase
    % 1st col: time bin, 2nd: context, 3rd: trial, 4th: reward(1/0), 
    % 5th: weight(1/2), 6th to end: cell dF/F 
    %
    % time_phase_mode = 4: data table has all time phase data 
    % 1st col: time range(1: licking time/2: 1700-1800mm/3: 3sec interval), 
    % 2nd: time bin#, 3rd: context#. 4th: trial#. 5th: reward(True:1/False:0), 6th: weight(0/2), 6th to end: mean dF/F all cells 
    
    timeDataTable_DA = time_bin_organize(param_sub,eachTrialTable,lickTimeBin,lick_end,timeDataTable_DA);   
    
end

function [timeDataTable_DA] = antiArea_time_phase(param_sub,eachTrialTable,timeDataTable_DA)

    essen_pos_idx = param_sub.essen_pos_idx;
    timeBin_Dur = param_sub.timeBin_Dur;
    time_mode = param_sub.time_mode;
    min_anti_time = param_sub.min_anti_time;
     
    % time_mode = 1: normal mode - using general time period in each time phase
    % tiem_mode = 2: min time mode - using min time period in each time phase
    %
    % essen_pos_idx:
    % 1st: start position of each trial, 2nd: position index of 1700, 3rd: 1st 1790, 
    % 4th: starting position index of 3 sec. interval, 5th: end position index of 1790
    if isequal(time_mode,1)
        antiArea_end = eachTrialTable(essen_pos_idx(3)+1,2);                  % anticipation area time end
    
    elseif isequal(time_mode,2)
        % time of 1700 + min_anticipation time must be less than 1st 1790's time
        if eachTrialTable(essen_pos_idx(2),2)+min_anti_time < eachTrialTable(essen_pos_idx(3)+1,2)
            % anticipation area time end = anticipation area time start + min_anti_time
            antiArea_end = eachTrialTable(essen_pos_idx(2),2)+min_anti_time;      
        
        % otherwise, we set antiArea_end as its time period own
        else
            antiArea_end = eachTrialTable(essen_pos_idx(3)+1,2);
        end
        
    end
    
    antiArea_st = eachTrialTable(essen_pos_idx(2),2);           % anticipation area time start
    antiAreaTimeBin = antiArea_st:timeBin_Dur:antiArea_end;     % anticipation area time start, +0.1, +0.2, ... , anticipation area time end (sec)
    if antiAreaTimeBin(end) < antiArea_end                      % just in case, we add correct anticipation area time end if condition works
        antiAreaTimeBin = [antiAreaTimeBin antiArea_end]; 
    end
    
    timeDataTable_DA = time_bin_organize(param_sub,eachTrialTable,antiAreaTimeBin,antiArea_end,timeDataTable_DA);   
        
end

function [timeDataTable_DA] = threeSecIntvl_time_phase(param_sub,eachTrialTable,timeDataTable_DA)    

    essen_pos_idx = param_sub.essen_pos_idx;
    timeBin_Dur = param_sub.timeBin_Dur;
    time_mode = param_sub.time_mode;
    min_threeSec_time = param_sub.min_threeSec_time;
    time_bin_organization_mode = param_sub.time_bin_organization_mode;
    
    % iii) 3sec. interval
    if isequal(param_sub.time_phase_mode,3)
        % time_mode = 1: normal mode - using general time period in each time phase
        % tiem_mode = 2: min time mode - using min time period in each time phase
        %
        % essen_pos_idx:
        % 1st: start position of each trial, 2nd: position index of 1700, 3rd: 1st 1790, 
        % 4th: starting position index of 3 sec. interval, 5th: end position index of 1790,
        % 6th: 1sec. before 3sec. interval
        if isequal(time_mode,1)
            threeSec_end = eachTrialTable(essen_pos_idx(5),2);                      % 3sec. interval end

        elseif isequal(time_mode,2)
            % this 3 sec. interval keeps enough time period thus, we don't need to consider short data
            threeSec_end = eachTrialTable(essen_pos_idx(4),2)+min_threeSec_time;    % 3sec. interval end = 3sec. interval start + min_threeSec_time        
        end

        threeSec_st = eachTrialTable(essen_pos_idx(4),2);           % 3sec. interval start
        threeSecTimeBin = threeSec_st:timeBin_Dur:threeSec_end;     % 3sec. interval start, +0.1, +0.2, ... , 3sec. interval end (sec)
        if threeSecTimeBin(end) < threeSec_end                      % just in case, we add correct 3sec. interval end if condition works
            threeSecTimeBin = [threeSecTimeBin threeSec_end]; 
        end
    
    % iv) 1sec. before 3sec. interval
    elseif isequal(param_sub.time_phase_mode,31)
        threeSecTimeBin = essen_pos_idx(6);                         % index of 1sec. before 3sec. interval start
        threeSec_end = essen_pos_idx(4)-1;                          % index of 1sec. before 3sec. interval end
    end
    
    % mode = 1: normal mode - time bin
    % mode = 2: ITI(Inter-Trial-Interval) mode - time bin in ITI 
    if isequal(time_bin_organization_mode,1)
        timeDataTable_DA = time_bin_organize(param_sub,eachTrialTable,threeSecTimeBin,threeSec_end,timeDataTable_DA);
    elseif isequal(time_bin_organization_mode,2)
        timeDataTable_DA = ITI_bin_organize(param_sub,eachTrialTable,threeSecTimeBin,threeSec_end,timeDataTable_DA);
    end
            
end   

function [timeDataTable_DA] = time_bin_organize(param_sub,eachTrialTable,timeBin,time_end,timeDataTable_DA)

    ctxtIter = param_sub.ctxtIter;
    trialItr = param_sub.trialItr;
    rewardCol = param_sub.rewardCol;
    weightCol = param_sub.weightCol;
    time_phase_mode = param_sub.time_phase_mode;
    if isequal(time_phase_mode,4)   
        which_phase = param_sub.which_phase;
	end
       
    % timeDataTable_DA:    % option 1: data table has one specific time phase data
    % save data re-organized by licking time info, 1st col: time range(1: licking time/2: 1700-1800mm/3: 3sec interval), 
    % 2nd: time bin#, 3rd: context#. 4th: trial#. 5th: reward(True:1/False:0), 6th: weight(1/2), 6th to end: mean dF/F all cells 
    %
    % eachTrialTable: ['Trial #', 'Time', 'X-pos', 'Velocity', and 'Selected cells' dF/F,'in cell2', ... 'in celln'];
    if length(timeBin)>1
        for timeBinIter = 1:1:length(timeBin)-1        % time bin start, +0.1, +0.2, ... , time bin end (sec)                               
            if isequal(timeBinIter,length(timeBin)-1)
                time_idx = find(eachTrialTable(:,2)>=timeBin(timeBinIter) & eachTrialTable(:,2)<time_end);
            else
                time_idx = find(eachTrialTable(:,2)>=timeBin(timeBinIter) & eachTrialTable(:,2)<timeBin(timeBinIter+1));
            end

            % time_phase_mode = 1/2/3: data table has only one specific time phase data
            % time_phase_mode = 1: anticipation area, 2: licking time, 3: 3sec. interval time phase
            % 1st col: time bin, 2nd: context, 3rd: trial, 4th: reward(1/0), 
            % 5th: weight(1/2), 6th to end: cell dF/F 
            %
            % time_phase_mode = 4: data table has all time phase data 
            % 1st col: time range(1: licking time/2: 1700-1800mm/3: 3sec interval), 
            % 2nd: time bin#, 3rd: context#. 4th: trial#. 5th: reward(True:1/False:0), 6th: weight(0/2), 6th to end: mean dF/F all cells 
            if ~isempty(time_idx)
                timeBin_mean = mean(eachTrialTable(time_idx,5:end),1,'omitnan');
                if isequal(time_phase_mode,1) | isequal(time_phase_mode,2) | isequal(time_phase_mode,3)
                    timeDataTable_DA = [timeDataTable_DA; timeBinIter, ctxtIter, trialItr, rewardCol, weightCol, num2cell(timeBin_mean)];
                elseif isequal(time_phase_mode,4)
                    timeDataTable_DA = [timeDataTable_DA; which_phase, timeBinIter, ctxtIter, trialItr, ...
                                        rewardCol, weightCol, num2cell(timeBin_mean)];
                end
            end

        end
        
    % only in case of iv) 1sec. before 3sec. interval
    % here, timeBin is not real time bin, but it start time of iv) 
    % the code below use index which depicts begining and end of time, and 
    % this code different above, thus, be careful when modify/understand code
    elseif isequal(length(timeBin),1)
        timeBin_mean = mean(eachTrialTable(timeBin:time_end,5:end),1,'omitnan');
        timeDataTable_DA = [timeDataTable_DA; 1, ctxtIter,trialItr,rewardCol,weightCol, num2cell(timeBin_mean)];
    end
end

function [timeDataTable_DA] = ITI_bin_organize(param_sub,eachTrialTable,timeBin,time_end,timeDataTable_DA)

cell_no = size(eachTrialTable,2)-4;
pks = cell(1,cell_no); pks_loc = cell(1,cell_no);
for cellIter = 1:1:cell_no
    avg_signal = mean(eachTrialTable(:,cellIter+4));        % average of signal in each cell
    [pks_temp,pks_loc_temp] = findpeaks(eachTrialTable(:,cellIter+4)); % find peaks
    pks_idx = pks_temp> avg_signal;                              % peaks must greater than average of signal
    % amplitude and location of peaks which are greater than average of
    % signal are stored in pks and pks_loc(both are cell-type var.) each
    pks{1,cellIter} = pks_temp(pks_idx); pks_loc{1,cellIter} = pks_loc_temp(pks_idx);
end

    ctxtIter = param_sub.ctxtIter;
    trialItr = param_sub.trialItr;
    rewardCol = param_sub.rewardCol;
    weightCol = param_sub.weightCol;
        
    % timeDataTable_DA:    % option 1: data table has one specific time phase data
    % save data re-organized by licking time info, 1st col: time range(1: licking time/2: 1700-1800mm/3: 3sec interval), 
    % 2nd: time bin#, 3rd: context#. 4th: trial#. 5th: reward(True:1/False:0), 6th: weight(1/2), 6th to end: mean dF/F all cells 
    %
    % eachTrialTable: ['Trial #', 'Time', 'X-pos', 'Velocity', and 'Selected cells' dF/F,'in cell2', ... 'in celln'];
    if length(timeBin)>1
        for timeBinIter = 1:1:length(timeBin)-1        % time bin start, +0.1, +0.2, ... , time bin end (sec)                               
            if isequal(timeBinIter,length(timeBin)-1)
                time_idx = find(eachTrialTable(:,2)>=timeBin(timeBinIter) & eachTrialTable(:,2)<time_end);
            else
                time_idx = find(eachTrialTable(:,2)>=timeBin(timeBinIter) & eachTrialTable(:,2)<timeBin(timeBinIter+1));
            end

            % time_phase_mode = 1/2/3: data table has only one specific time phase data
            % time_phase_mode = 1: anticipation area, 2: licking time, 3: 3sec. interval time phase
            % 1st col: time bin, 2nd: context, 3rd: trial, 4th: reward(1/0), 
            % 5th: weight(1/2), 6th to end: cell dF/F 
            %
            % time_phase_mode = 4: data table has all time phase data 
            % 1st col: time range(1: licking time/2: 1700-1800mm/3: 3sec interval), 
            % 2nd: time bin#, 3rd: context#. 4th: trial#. 5th: reward(True:1/False:0), 6th: weight(0/2), 6th to end: mean dF/F all cells 
            if ~isempty(time_idx)
                dtMat_pks = zeros(1,cell_no);
                for cellIter = 1:1:cell_no
                   % find matching index number in pks_loc{1,cellIter}
                   % pks_loc{1,cellIter} contains index of peaks and time_idx index of specific time bin
                   % when index of time bin matches index of peaks, store amplitude of peaks whose matching index 
                   pks_idx = find(pks_loc{1,cellIter}>=time_idx(1) & pks_loc{1,cellIter}<=time_idx(end));
                   if ~isempty(pks_idx)
                       % it is possible that multiple indices are selected
                       % if so, we select max amplitude and store it
                       [~,max_pks_idx] = max(pks{1,cellIter}(pks_idx));
                       dtMat_pks(1,cellIter) = pks{1,cellIter}(pks_idx(max_pks_idx));  
                   end
                end
                timeDataTable_DA = [timeDataTable_DA; timeBinIter, ctxtIter, trialItr, rewardCol, weightCol, num2cell(dtMat_pks)];
                
            end

        end
    end
    
end
