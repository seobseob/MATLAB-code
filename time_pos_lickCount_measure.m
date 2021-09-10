function [dtCell_spd_essen_data,dtCell_spd_essen_data_excel,dtCell_lick_count_data,dtCell_trigger_time_data] = ...
                                                time_pos_lickCount_measure(session_data,position_data,param)

%% variable initialization

    save_sheet = param.save_sheet;          % user determined option; 1: save dtCell_essen_data in an excel sheet
    fullPath = param.fullPath;              % user determined file name of excel sheet to store
%     time_col = param.time_col + 1;              % in both of session_data and position_data 
    sys_msg_col = param.sys_msg_col + 1;        % only in session_data
    msg_col = param.msg_col + 1;                % only in session_data
    sys_msg = param.sys_msg;                    % only in session_data
    anti_range = param.anti_range;              % only in position_data
%     VR_pos_col = param.VR_pos_col + 1;          % only in position_data
%     ctxt_flag_col = param.ctxt_flag_col + 1;    % only in position_data
%     phy_pos_col = param.phy_pos_col + 1;        % only in position_data
%     lick_msg = param.lick_msg; 
    lick_searching_flag = param.lick_searching_flag;
    
    % time col: generally double type column but the first two rows contain string
    % system message col: string type column + NaN
    % message value1 col: double and string are mixed but string info. is
    % not necessary + NaN
    % message value2 col: double and string are mixed but string info. is
    % not necessary + NaN
    % message value3 col: double type column + NaN
    
%% system message indexing

    % the session_log and position_data might contains unfinished trial data
    % due to VR system was crashed, thus, we have to exclude data during
    % system crash
    % msg_col shows trial number; when the VR system crashed sequence of
    % trial number is short, such as only trial 1 or 2 (or 3 in case)
    %
    
    % sys_msg_col: system message column
    % sys_msg = {'start run','BlackStart','EndTrial','PostTrialImaging',...
    %            'RwdEvent1:default','RwdEvent1:hit','StartTrigger','endTrigger'};
    % it is paired system message with 'start run' -> 'BlackStart' ->
    % 'EndTrial'/'PostTrialImaging' (when the last trial in a session, the
    % message is 'PostTrialImaging', otherwise 'EndTrial')
    
    trial_start_idx = strfind(session_data(:,sys_msg_col),sys_msg{1});  % 'start run'
	trial_start_idx = indexing_in_cell(trial_start_idx);
    
    black_start_idx = strfind(session_data(:,sys_msg_col),sys_msg{2});  % 'BlackStart'
    black_start_idx = indexing_in_cell(black_start_idx);
   
    % the last trial end message is replaced by message of 'PostTrialImaging'
    postTrialImaging_idx = strfind(session_data(:,sys_msg_col),sys_msg{4});  % 'PostTrialImaging'
    postTrialImaging_idx = indexing_in_cell(postTrialImaging_idx);
    trial_end_idx = strfind(session_data(:,sys_msg_col),sys_msg{3});    % 'EndTrial'
    trial_end_idx = indexing_in_cell(trial_end_idx);
           
    postTrialImaging_len = length(postTrialImaging_idx);
    trial_end_idx(end+1:end+postTrialImaging_len,1) = postTrialImaging_idx;
    trial_end_idx = sort(trial_end_idx);
    
    start_trigger_idx = strfind(session_data(:,sys_msg_col),sys_msg{7});    % StartTrigger
    start_trigger_idx = indexing_in_cell(start_trigger_idx);
    
    end_trigger_idx = strfind(session_data(:,sys_msg_col),sys_msg{8});      % endTrigger
    end_trigger_idx = indexing_in_cell(end_trigger_idx);
    
    % confirmation - length of three indices must be same
    if isequal(length(trial_start_idx),length(black_start_idx)) && ...
                      isequal(length(black_start_idx),length(trial_end_idx))
    else
       error('number of system message - start run, BlackStart, EndTrial -  is not matched')
    end
    
    % confirmation - number of start and endTrigger must be same
    if ~isequal(length(start_trigger_idx),length(end_trigger_idx))
       error('number of system message - StartTrigger, endTrigger -  is not matched')
    end
    
%% separation of trial in position data & calculation of speed each trial
%  cf.) anticipation area speed measurement is exceptional case, the system
%       message is not useable, thus, the method we used past is required

    % in session_log
    % 1st col: trial number, 2nd: context number 
    % 3rd-5th: time info. of start run, black start, and end trial
    % in position data
    % 6-8th: (abs) position in physical environment, 9-11th: position in VR,
    % 12th: speed between start run and EndTrial(cm/s), 
    % 13th: speed between BlackStart and EndTrial(cm/s),
    % 14th: speed between start run and BlackStart(cm/s),
    % 15th: speed in anticipation area(cm/s)
    dtCell_spd_essen_data = {'Trial #','Context','Time in start run','Time in BlackStart','Time in EndTrial',...
                         'Phy. pos in start run','Phy. pos in BlackStart','Phy. pos in EndTrial', ...
                         'VR pos in start run','VR pos in BlackStart','VR pos in EndTrial',...
                         'Speed start-EndTrial(cm/s)','Speed BlackStart-EndTrial(cm/s)',...
                         'Speed start-BlackStart(cm/s)','Speed in aniticipation area(cm/s)'};
    
    dtCell_lick_count_data = {'Trial #','Context','lick count before black start','lick count after black start'};
    
    % StartTrigger & endTrigger data handling here
    dtCell_trigger_time_data = {'Trigger type','Time'};
    for ii = 1:1:length(start_trigger_idx)
            % StartTrigger
            dtCell_trigger_time_data{(ii-1)*2+1,1} = sys_msg{7};
            dtCell_trigger_time_data{(ii-1)*2+1,2} = session_data{start_trigger_idx(ii),1}; 
            
            % endTrigger
            dtCell_trigger_time_data{(ii-1)*2+2,1} = sys_msg{8};
            dtCell_trigger_time_data{(ii-1)*2+2,2} = session_data{end_trigger_idx(ii),1};
    end
       
    dtCell_idx = 1;
           
    h = waitbar(0,'Speed & licking count measurement. Please wait...');
    for idxIter = 1:1:length(trial_start_idx)
       dtCell_spd_essen_data{dtCell_idx+1,1} = idxIter;   % trial number
       dtCell_spd_essen_data{dtCell_idx+1,2} = session_data{trial_start_idx(idxIter),msg_col(2)};   % context number
       
       dtCell_lick_count_data{dtCell_idx+1,1} = idxIter;  % trial number
       dtCell_lick_count_data{dtCell_idx+1,2} = session_data{trial_start_idx(idxIter),msg_col(2)};  % context number
       
       waitbar(idxIter / length(trial_start_idx))
       
       % start run
       param.idxIter = idxIter;
       param.ref_time_store_col = 3;
       param.phy_pos_store_col = 6;
       param.VR_pos_store_col = 9;
       param.dtCell_idx = dtCell_idx;
       param.EndTrial_offset = 0;
       [dtCell_spd_essen_data,start_run_idx] = essential_data_gather(dtCell_spd_essen_data,trial_start_idx,session_data,position_data,param);   % speed measurement
       if lick_searching_flag
            param.lick_count_ref = 'position';
            dtMat_lick_before_black_start = licking_info_gather(trial_start_idx,black_start_idx,session_data,position_data,param);    % licking count
       end
       oneTrial_idx = [];
       oneTrial_idx = [oneTrial_idx, start_run_idx];
             
       % BlackStart
       param.ref_time_store_col = 4;
       param.phy_pos_store_col = 7;
       param.VR_pos_store_col = 10;
       param.dtCell_idx = dtCell_idx;
       [dtCell_spd_essen_data,~] = essential_data_gather(dtCell_spd_essen_data,black_start_idx,session_data,position_data,param);   % speed measurement
       if lick_searching_flag     % reward was given
            param.lick_count_ref = 'time';
            dtMat_lick_after_black_start = licking_info_gather(black_start_idx,trial_end_idx,session_data,position_data,param);    % licking count
       
            % dtCell_lick_count_data: {'Trial #','Context','lick count before black start','lick count after black start'}
            %if ~isempty(dtMat_lick_before_black_start)
                dtCell_lick_count_data{dtCell_idx+1,3} = dtMat_lick_before_black_start;  % licking count
            %else
            %    dtCell_lick_count_data{dtCell_idx+1,3} = nan(1,lick_before_black_start_len);  
            %end
            %if ~isempty(dtMat_lick_after_black_start)
                dtCell_lick_count_data{dtCell_idx+1,4} = dtMat_lick_after_black_start;   % licking count
            %else
            %    dtCell_lick_count_data{dtCell_idx+1,4} = NaN;
            %end
       else                       % reward was not given
           dtCell_lick_count_data{dtCell_idx+1,3} = NaN;
           dtCell_lick_count_data{dtCell_idx+1,4} = NaN;
       end
       
       % EndTrial
       % trial_end_time is treaky. there is time gap between session_log
       % and position data, thus position in trial_end depicts the first
       % element next trial. THEREFORE, we are going to use pos_dt_iter-1,
       % not pos_dt_iter directly
       param.ref_time_store_col = 5;
       param.phy_pos_store_col = 8;
       param.VR_pos_store_col = 11;
       param.dtCell_idx = dtCell_idx;
       param.EndTrial_offset = -1;
       [dtCell_spd_essen_data,end_trial_idx] = essential_data_gather(dtCell_spd_essen_data,trial_end_idx,session_data,position_data,param);  
       oneTrial_idx = [oneTrial_idx, end_trial_idx];
       
       % anticipation area 
       % speed measurement in anticipation area: 2600-2700mm
       % position data:
       % 1st col: time, 2nd: position in VR, 5th: position in physical environment
       % oneTrial_idx consists of 1-by-two vector and depicts index of
       % 'start run' and 'EndTrial' in position_data
       % therefore, dtMat_position_data depicts a single trial data of position
       oneTrial_position_data = position_data(oneTrial_idx(1):oneTrial_idx(2),:);
       anti_speed = anticipation_area_speed(oneTrial_position_data,anti_range);
              
       % speed between start run and EndTrial(cm/s)
       start_EndTrial_time = datevec(dtCell_spd_essen_data{dtCell_idx+1,5}-dtCell_spd_essen_data{dtCell_idx+1,3});
       start_EndTrial_time = start_EndTrial_time(end-1)*60 + start_EndTrial_time(end);
       dtCell_spd_essen_data{dtCell_idx+1,12} = (dtCell_spd_essen_data{dtCell_idx+1,8} - ...
                                            dtCell_spd_essen_data{dtCell_idx+1,6}) / start_EndTrial_time / 10;
           
       % speed between BlackStart and EndTrial(cm/s)
       black_EndTrial_time = datevec(dtCell_spd_essen_data{dtCell_idx+1,5}-dtCell_spd_essen_data{dtCell_idx+1,4});
       black_EndTrial_time = black_EndTrial_time(end-1)*60 + black_EndTrial_time(end);
       dtCell_spd_essen_data{dtCell_idx+1,13} = (dtCell_spd_essen_data{dtCell_idx+1,8} - ...
                                            dtCell_spd_essen_data{dtCell_idx+1,7}) / black_EndTrial_time / 10; 
    
       % speed between start run and BlackStart(cm/s)
       start_Black_time = datevec(dtCell_spd_essen_data{dtCell_idx+1,4}-dtCell_spd_essen_data{dtCell_idx+1,3});
       start_Black_time = start_Black_time(end-1)*60 + start_Black_time(end);
       dtCell_spd_essen_data{dtCell_idx+1,14} = (dtCell_spd_essen_data{dtCell_idx+1,7} - ...
                                            dtCell_spd_essen_data{dtCell_idx+1,6}) / start_Black_time / 10; 
                                        
       % speed in anticipation area(cm/s);  260-270cm
       dtCell_spd_essen_data{dtCell_idx+1,15} = anti_speed;
       
       dtCell_idx = dtCell_idx + 1;
    end
    
    % datetime type data is displayed by 'HH:MM:SS.FFF' in dtCell_essen_data_excel
    dtCell_spd_essen_data_excel = dtCell_spd_essen_data;
    for rowIter = 2:1:size(dtCell_spd_essen_data,1)
        for colIter = 3:1:5
            dtCell_spd_essen_data_excel{rowIter,colIter} = datestr(dtCell_spd_essen_data_excel{rowIter,colIter},'HH:MM:SS.FFF');
        end
    end
    
    if isequal(save_sheet,1)  
        writetable(cell2table(dtCell_spd_essen_data_excel),fullPath,'WriteVariableNames',false);
        %xlswrite(fullPath,dtCell_spd_essen_data_excel);
    end
    
    close(h)
    
end