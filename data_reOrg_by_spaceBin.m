function [dt_spaceBin,dt_spaceBin_1800] = data_reOrg_by_spaceBin(eachData,dt_spaceBin,param,dt_spaceBin_1800,param_sub)
    
%% variables initialization

    dayIter = param.dayIter;
    miceIter = param.miceIter;
    ctxtIter = param.ctxtIter;
    heatMapRange = param.heatMapRange;  % 10cm position bin  % 0:50:1900; % 5cm position bin
    trial_lim = param.trial_lim;            % [day1:19, day4:14, day7:14]
    mice_number = param.animal_number;
    spaceBin_data_by_eachTrial = [];
    spaceBin_data_by_eachTrial_1800 = [];  
    mode = param_sub.mode;          % 'normal': using normal dF/F, 'peak': using amplitude of peak
    
    % the data structure of each cell in dataTable is 
    % eachData: ['Trial #', 'Time', 'X-pos[mm]', 'Velocity', and 'Selected cells' dF/F,'in cell2', ... 'in celln'];
    
    %% arrangement of fluorescence data by position bin

    for trialIter = 1:1:trial_lim(dayIter)      % [day1:19, day4:14, day7:14]
                           
       for xPosIter = 1:1:length(heatMapRange)-2
           trial_xPos_idx = find(eachData(:,1)==trialIter & eachData(:,3)>=heatMapRange(xPosIter) & eachData(:,3)<heatMapRange(xPosIter+1));   
           
           if ~isempty(trial_xPos_idx)
                trial_xPos_1800_idx = trial_xPos_idx;       % range of x-position 0-(end)1800mm
                
                % we have to consider the end range of x-position which is (1st) 1790 
                if isequal(xPosIter, length(heatMapRange)-2)
                    first1790_xPos = eachData(trial_xPos_idx(end),3);
                    first1790_idx = find(first1790_xPos == eachData(trial_xPos_idx,3)) + trial_xPos_idx(1)-1;
                    trial_xPos_idx = trial_xPos_idx(1):first1790_idx(1);
                end
               
                mean_speed = mean(eachData(trial_xPos_idx,4),1);
                if strcmpi(mode,'normal')
                    mean_activity = mean(eachData(trial_xPos_idx,5:end),1);  % mean activity of one space bin from all cells,e.g.) 1-by-number of cells
                elseif strcmpi(mode,'peak')
                    mean_activity = max(eachData(trial_xPos_idx,5:end),[],1);   % max amplitude of peak in one space bin from all cells,e.g.) 1-by-number of cells
                end
                sum_activity = sum(eachData(trial_xPos_idx,5:end),1);    % sum activity of one space bin from all cells,e.g.) 1-by-number of cells
                                               
                mean_speed_1800 = mean(eachData(trial_xPos_1800_idx,4),1);          % range of x-position 0-(end)1800mm
                mean_activity_1800 = mean(eachData(trial_xPos_1800_idx,5:end),1);   % range of x-position 0-(end)1800mm
                
                % spaceBin_data_by_eachTrial contains accumulated data by space bins 
                % ['X-pos bin','Context','Trial #','Avg speed','Selected cells' dF/F,'in cell2', ... 'in celln'];
                spaceBin_data_by_eachTrial = [spaceBin_data_by_eachTrial; ...
                                xPosIter,ctxtIter,trialIter,mean_speed,mean_activity];
                            
                % range of x-position 0-(end)1800mm            
                spaceBin_data_by_eachTrial_1800 = [spaceBin_data_by_eachTrial_1800; ...
                                xPosIter,ctxtIter,trialIter,mean_speed_1800,mean_activity_1800];
                
           else
                spaceBin_data_by_eachTrial = [spaceBin_data_by_eachTrial; ...
                                xPosIter,ctxtIter,trialIter,0,zeros(1,size(eachData,2)-4)];
                            
                % range of x-position 0-(end)1800mm            
                spaceBin_data_by_eachTrial_1800 = [spaceBin_data_by_eachTrial_1800; ...
                                xPosIter,ctxtIter,trialIter,0,zeros(1,size(eachData,2)-4)];
               
           end

       end
    end   
    
    % output data in this function
    dt_spaceBin_idx = (dayIter-1)*mice_number + miceIter;
    dt_spaceBin{dt_spaceBin_idx,ctxtIter} = spaceBin_data_by_eachTrial;
    dt_spaceBin_1800{dt_spaceBin_idx,ctxtIter} = spaceBin_data_by_eachTrial_1800;
    
   
end

