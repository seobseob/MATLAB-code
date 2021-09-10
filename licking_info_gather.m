function [dtMat_lick_count_sep] = licking_info_gather(A_dt_idx,B_dt_idx,session_data,position_data,param)
 
    % A_dt_idx, B_dt_idx:
    % trial_start_idx('start run') or black_start_idx('BlackStart') or
    % trial_end_idx('EndTrial'/'postTrialImaging')  
    
    idxIter = param.idxIter;    % loop iteration number in trial_start_idx
    pos_BlackStart = param.pos_BlackStart;  % 2700mm(= 270cm)
    posBinWidth = param.posBinWidth;        % position bin width: 10cm(= 100mm)
    timeBinWidth = param.timeBinWidth;      % time bin width: 0.5sec
    lick_count_ref = param.lick_count_ref;  % licking time count by 'position' or 'time'
    lick_msg = param.lick_msg;              % system message when licking: 'CondMod1'
    %sys_msg: {'start run','BlackStart','EndTrial','PostTrialImaging','RwdEvent1:default','RwdEvent1:hit'};
    sys_msg = param.sys_msg(5:6); 
    
    if (B_dt_idx(idxIter) - A_dt_idx(idxIter)) > 1
        % licking_row: 1st col: 'datetime' type time, 2nd: excel format time, 
        % 3rd: licking duration, 4th: count of licking
        licking_row_temp = session_data(A_dt_idx(idxIter):B_dt_idx(idxIter),:);
        
        % hit/default system message
        licking_default_idx = find(strcmp(licking_row_temp(:,15),sys_msg{1}));
        licking_hit_idx = find(strcmp(licking_row_temp(:,15),sys_msg{2}));
                    
        licking_row_temp_idx = strcmp(licking_row_temp(:,5),lick_msg);
        licking_row = licking_row_temp(licking_row_temp_idx,[1,2,7,8]);
        
        % licking hit/default count +1
        % hit/dafault don't have info. of licking duration and count, so 
        % insert dafault value; licking duration: 100ms, count: 1
        if ~isempty(licking_hit_idx)
            licking_row = [licking_row_temp(licking_hit_idx,[1,2]), 100, 1; licking_row];
        end
        if ~isempty(licking_default_idx)
            licking_row = [licking_row_temp(licking_default_idx,[1,2]), 100, 1; licking_row];
        end
        
        if ~isempty(licking_row)
            % compensation licking count using licking duration
            % we assume that a single licking take about 100ms
            % if licking duration is over 200ms licking count would be two
            licking_row(:,4) = num2cell(round(cell2mat(licking_row(:,3))./110));
            dtCell_lick_count = position_data_searching(licking_row,position_data);

            if strcmp(lick_count_ref,'position')
                % A_dt_idx: trial_start_idx, B_dt_idx: black_start_idx
                dtMat_lick_count_sep = 0:posBinWidth:pos_BlackStart;
                dtMat_lick_count_sep(2,:) = zeros(1,size(dtMat_lick_count_sep,2));
                lick_pos = cell2mat(dtCell_lick_count(:,3));

                for ii = 1:1:length(dtMat_lick_count_sep)-1
                   cond = (lick_pos>= dtMat_lick_count_sep(1,ii)) & ...
                                        (lick_pos<dtMat_lick_count_sep(1,ii+1));
                   if ~isempty(find(cond,1)) 
                       dtMat_lick_count_sep(2,ii) = sum(cell2mat(dtCell_lick_count(cond,4)));
                   end 
                end

            elseif strcmp(lick_count_ref,'time')
                % A_dt_idx: black_start_idx, B_dt_idx: trial_end_idx
                time_dur = datevec(session_data{B_dt_idx(idxIter),1}-session_data{A_dt_idx(idxIter),1});
                dtMat_lick_count_sep = 0:timeBinWidth:time_dur(1,end);
                dtMat_lick_count_sep(2,:) = zeros(1,size(dtMat_lick_count_sep,2));

                % 'BlackStart' index for getting a reference time in position_data
                blackStart_ref_time_excel = session_data{A_dt_idx(idxIter),2};
                blackStart_ref_time_idx = find(blackStart_ref_time_excel <= cell2mat(position_data(:,2)));
                blackStart_ref_time_idx = blackStart_ref_time_idx(1);

                % time info. in dtCell_lick_count is from position_data
                lick_time = zeros(size(dtCell_lick_count,1),1);
                for ii = 1:1:size(dtCell_lick_count,1)
                   lick_time_temp = datevec(dtCell_lick_count{ii,1} - ...
                                            position_data{blackStart_ref_time_idx,1});
                   lick_time(ii,1) = lick_time_temp(end-1)*60 + lick_time_temp(end);
                end

                for ii = 1:1:length(dtMat_lick_count_sep)-1
                   cond = (lick_time(:,1)>= dtMat_lick_count_sep(1,ii)) & ...
                                    (lick_time(:,1)<dtMat_lick_count_sep(1,ii+1));
                   if ~isempty(find(cond,1))
                       dtMat_lick_count_sep(2,ii) = sum(cell2mat(dtCell_lick_count(cond,4)));
                   end
                end
            end
        
        else
            if strcmp(lick_count_ref,'position')
                dtMat_lick_count_sep = 0:posBinWidth:pos_BlackStart;
                dtMat_lick_count_sep(2,:) = zeros(1,size(dtMat_lick_count_sep,2));
            elseif strcmp(lick_count_ref,'time')
                time_dur = datevec(session_data{B_dt_idx(idxIter),1}-session_data{A_dt_idx(idxIter),1});
                dtMat_lick_count_sep = 0:timeBinWidth:time_dur(1,end);
                dtMat_lick_count_sep(2,:) = zeros(1,size(dtMat_lick_count_sep,2));
            end
        end
        
    else        % there is no licking info. between two system messages
        if strcmp(lick_count_ref,'position')
            dtMat_lick_count_sep = 0:posBinWidth:pos_BlackStart;
            dtMat_lick_count_sep(2,:) = zeros(1,size(dtMat_lick_count_sep,2));
        elseif strcmp(lick_count_ref,'time')
            time_dur = datevec(session_data{B_dt_idx(idxIter),1}-session_data{A_dt_idx(idxIter),1});
            dtMat_lick_count_sep = 0:timeBinWidth:time_dur(1,end);
            dtMat_lick_count_sep(2,:) = zeros(1,size(dtMat_lick_count_sep,2));
        end
    end

    
end


function [dtCell_lick_count] = position_data_searching(licking_row,position_data)
    
    dtCell_lick_count = cell(size(licking_row,1),4);
    
    for lick_iter = 1:1:size(licking_row,1)
        ref_time_excel = licking_row{lick_iter,2};
        pos_time_excel = cell2mat(position_data(:,2));
        ref_time_idx = find(ref_time_excel <= pos_time_excel);
        ref_time_idx = ref_time_idx(1);
        
        dtCell_lick_count{lick_iter,1} = position_data{ref_time_idx,1};     % 'datetime' type time info.
        dtCell_lick_count{lick_iter,2} = position_data{ref_time_idx,2};     % excel format time info.
        dtCell_lick_count{lick_iter,3} = position_data{ref_time_idx,3};     % position in VR
        dtCell_lick_count{lick_iter,4} = licking_row{lick_iter,4};          % count of licking 
    end

end