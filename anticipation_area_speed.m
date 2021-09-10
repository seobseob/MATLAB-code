function [anti_speed] = anticipation_area_speed(oneTrial_position_data,anti_range)

    % oneTrial_position_data depicts a single trial data using index from
    % 'start run' and 'EndTrial' system messages
    %
    % oneTrial_position data:
    % 1st col: time, 2nd: position in VR, 5th: position in physical environment
       
    % anticipation area is placed in 10 cm before 270cm
    temp_data = cell2mat(oneTrial_position_data(:,3));      % position in VR
    anti_data = oneTrial_position_data(temp_data >= anti_range(1) & temp_data < anti_range(2),:);
    time_diff = datevec(anti_data{end,1} - anti_data{1,1});
    time_diff = time_diff(end-1)*60 + time_diff(end);        % sec. unit
    pos_diff = abs(anti_data{end,6} - anti_data{1,6});       % position difference in physical environment
    anti_speed = pos_diff / time_diff / 10;                  % cm/s unit
    
end