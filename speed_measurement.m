function [speed_avg_1Animal,dtMat_spd_all_trial,dtMat_spd_slowDown_all_trial] = speed_measurement(eachData,param,param_sub)

%% variables initialization

    timeCol = param.timeCol;        % time column
    spdCol = param.spdCol;          % speed column
    posCol = param.posCol;          % x-position column
    trial_lim = param.trial_lim;
    dayIter = param_sub.dayIter;
    cell_number = size(eachData,2)-4;
    
    dtMat_spd_all_trial = zeros(trial_lim(dayIter),3);
    dtMat_spd_slowDown_all_trial = zeros(trial_lim(dayIter),1);
    
    anti_pos_lim = 1700;                % anticipation area limit: 1700-(1st)1790mm
    mid_pos_lim = [800,900];            % middle area limit: 800-900mm
        
%% speed measurement processing
    

    for trialIter = 1:1:trial_lim(dayIter)
       % trial_dt:
       % 1st col: time, 2nd: x-position, 3rd: speed
       trial_dt = eachData(eachData(:,1)==trialIter,[timeCol,posCol,spdCol]); 
       % average speed in entire corridor
       entire_pos_avg_spd = (trial_dt(end,2)-trial_dt(1,2)) / (trial_dt(end,1)-trial_dt(1,1)); 
       
       % average speed in the anticipation area: 1700mm - (1st) 1790mm
       anti_pos_lim(2) = trial_dt(end,2);
       anti_pos_idx = find(trial_dt(:,2)>anti_pos_lim(1) & trial_dt(:,2)<anti_pos_lim(2));
       % in case of abscent anticipation area
       if isempty(anti_pos_idx)
          critic_idx = find(trial_dt(:,2)>anti_pos_lim(1));
          anti_pos_idx = critic_idx(1)-1;
       end
       anti_pos_idx = [anti_pos_idx; anti_pos_idx(end)+1];
       % how much slow speed down in the anticipation area = speed at 1700mm - speed at (1st) 1790mm 
       slowDown_anti = [trial_dt(anti_pos_idx(1),3) trial_dt(anti_pos_idx(end),3)];     % 1st ele: speed at 1700mm, 2nd: speed at (1st) 1790mm
       anti_pos_avg_spd = (trial_dt(anti_pos_idx(end),2)-trial_dt(anti_pos_idx(1),2)) / ...
                            (trial_dt(anti_pos_idx(end),1)-trial_dt(anti_pos_idx(1),1));
       
       % average speed in the middle of corridor: 800mm-900mm
       mid_pos_idx = find(trial_dt(:,2)>mid_pos_lim(1) & trial_dt(:,2)<=mid_pos_lim(2));
       mid_pos_avg_spd = (trial_dt(mid_pos_idx(end),2)-trial_dt(mid_pos_idx(1),2)) / ...
                            (trial_dt(mid_pos_idx(end),1)-trial_dt(mid_pos_idx(1),1));

       % gathering average speed in different ranges                 
       dtMat_spd_all_trial(trialIter,1) = entire_pos_avg_spd / 10;      % convert unit mm/s to cm/s
       dtMat_spd_all_trial(trialIter,2) = mid_pos_avg_spd / 10;         % convert unit mm/s to cm/s
       dtMat_spd_all_trial(trialIter,3) = anti_pos_avg_spd / 10;        % convert unit mm/s to cm/s
       
       dtMat_spd_slowDown_all_trial(trialIter,1) = slowDown_anti(1,1) - slowDown_anti(1,2);
    end
    
    % speed_avg_1Animal stores averaged speed measurement over trials 
    % in each animal, each context
    speed_avg_1Animal = mean(dtMat_spd_all_trial,1,'omitnan');


end