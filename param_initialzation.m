function [param] = param_initialzation(param)
 
    % essential SystemMsg in the experiment control system log('SessionLog*-IS modified.xlsx')
    param.sys_msg = {'start run','BlackStart','EndTrial','PostTrialImaging','RwdEvent1:default','RwdEvent1:hit',...
                     'StartTrigger','endTrigger'};
    param.lick_msg = 'CondMod1';
    
    % assginment of column number which has essential data in csv/xlsx data
    param.time_col = 1;                     % in both of session_data and position_data
    % 'MsgValue1': trial number, 'MsgValue2': context number, 'MsgValue3': unknown
    param.sys_msg_col = 14;                 % only in session_data
    param.msg_col = 15:17;                  % only in session_data
    param.lick_msg_col = 4;                 % only in session_data
    
    param.VR_pos_col = 2;                   % only in position_data
    param.ctxt_flag_col = 3;                % only in position_data
    param.phy_pos_col = 5;                  % only in position_data
    
    % extra data initialization
    param.posBinWidth = 100;                % position bin width: 10cm(= 100mm)
    param.timeBinWidth = 0.5;               % time bin widht: 0.5sec
    param.pos_BlackStart = 2700;            % position in BlackStart = 2700mm
    
end