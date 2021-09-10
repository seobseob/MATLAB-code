function [dtCell_essen_data,ref_time_idx] = essential_data_gather(dtCell_essen_data,idx,session_data,position_data,param)

    idxIter = param.idxIter;
    time_col = param.time_col + 1;
    ref_time_store_col = param.ref_time_store_col;
    phy_pos_col = param.phy_pos_col + 1;
    VR_pos_col = param.VR_pos_col + 1;
    phy_pos_store_col = param.phy_pos_store_col;
    VR_pos_store_col = param.VR_pos_store_col;
    dtCell_idx = param.dtCell_idx;
    % trial_end_time is treaky. there is time gap between session_log
    % and position data, thus position in trial_end depicts the first
    % element next trial. THEREFORE, we are going to use pos_dt_iter-1,
    % not pos_dt_iter directly
    EndTrial_offset = param.EndTrial_offset;
    
    ref_time_excel = session_data{idx(idxIter),time_col}; 
    ref_time = session_data{idx(idxIter),time_col-1};
    dtCell_essen_data{dtCell_idx+1,ref_time_store_col} = ref_time;                                    % time info. of start run/BlackStart/EndTrial

    pos_time_excel = cell2mat(position_data(:,time_col));
    ref_time_idx = find(ref_time_excel <= pos_time_excel);
    ref_time_idx = ref_time_idx(1);
    
    dtCell_essen_data{dtCell_idx+1,phy_pos_store_col} = abs(position_data{ref_time_idx+EndTrial_offset,phy_pos_col});  % physical position in start run/BlackStart/EndTrial
    dtCell_essen_data{dtCell_idx+1,VR_pos_store_col} = position_data{ref_time_idx+EndTrial_offset,VR_pos_col};         % VR position in start run/BlackStart/EndTrial
    
end