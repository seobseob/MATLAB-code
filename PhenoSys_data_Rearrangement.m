function [varargout] = PhenoSys_data_Rearrangement(varargin)

% PhenoSys data includes i) animal's behavior data - such as movement in the
% Virtual Reality system, number of water reward licking - in an excel/csv
% file, named '*Animal n-Day m*'.
% As well as, it has ii) experiment control system's log - such as when
% started triggered 2PM system, which context, which trial, so on - in an
% excel/csv file, named 'SessionLog*-IS modified.xlsx'. 
% 
% caution!!) The experiment system was operated by users manually and 
% it was possible that experiment performed many times separately due to 
% malfunction of the system, thus, I had to deleted weired log data and 
% re-organized the system log manually after experiment, and it was named 
% '*-IS modified.xlsx'.  

% important!!!
% VR_Excel_Rearrangement_May_2019_Ver03_Result_data_handling.m and 
% licking_count_organization.m handles result data to plot, respectively
   
% example:
% 1) single file I/0 mode; input parameter=0;
% [dtCell_spd_essen_data,dtCell_spd_essen_data_excel,dtCell_lick_count_data,dtCell_twoPM_frame_data] = PhenoSys_data_Rearrangement(0)
% 2) batch mode; input parameter=1;
% [dtCell_batch_speed,dtCell_batch_lick_count,dtCell_batch_twoPM_frame_data] = PhenoSys_data_Rearrangement(1)

% data structure of behavior data, e.g.)19.05.11_Animal 1-Day3.csv:
% * time must be converted to HH:MM:SS.ssss; context flag: 0(=1), 200(=2), 400(=3)
%      time        pos in VR  ctxt flag  unknown   pos in physical        unknown
% -------------------------------------------------------------------------------------
% 43596.4396687616	2.415	      0	       338	  -121.903703703704	  -160.259259259259
% 43596.4396689931	2.608	      0	       338	  -122.037037037037	  -169.822222222222
% 43596.4396692245	2.741	      0	       338	  -122.348148148148	  -180.007407407407
% 43596.439669456	3.134	      0	       338	  -122.666666666667	  -189.807407407407
% 43596.4396696875	3.489	      0	       338	  -123.103703703704	  -199.281481481481
% 43596.439669919	3.97	      0	       338	  -123.637037037037	  -208.651851851852

% experiment control system log, e.g.)SessionLog-19.05.11-Animal 1-Day3-IS modified.xlsx:
% * MsgValue1 depicts trial number, MsgValue2 shows context number
% ** essential SystemMsg is shown in 'param.sys_msg' below  
%      time         ...     SystemMsg               MsgValue1               MsgValue2
% -------------------------------------------------------------------------------------
% 43596.4395772569	...		start	           Weilun_Context.xlsx		
% 43596.439577338	...		vr	               started	                PhenoSoft VR.exe	
% 43596.439729537	...		StartTrigger			
% 43596.4397295602	...		PreTrialImaging			
% 43596.4432019792	...		start run	       1	                    2


%% variable initialization

    % user must determine these variables 
    if isempty(varargin)                                    
        param.batchMode = 1;                            % batch mode on/off        
    elseif isequal(size(varargin,1),1)
        param.batchMode = varargin{1};
    end
    param.animal_number = 10;                            % number of animal(how many animals from animal1)
    param.day = 'all';                                  % number of day(how many days from day0) or 'all'  
    param.anti_range = [2600, 2700];                    % anticipation range: 2600-2700mm
    param.save_sheet = 0;                               % user determined option; 1: save dtCell_essen_data as an excel sheet, 0: not save    
    param.excelFileName = 'speed measurement2.xlsx';    % user determined file name of excel sheet to store
    param.TwoPM_frame_sync_flag = 0;                    % synchronization two-photon image-set and frame number(1: activate, 0: inactivate)
    param.posRange_to_save = [500,2700];                % position range to save(50-270cm); see 'pos_sep' in reOrg_data_by_context.m 
    param.timeRange_to_save = [0,5];                  % time range to save(0-2.5sec); see '' in reOrg_data_by_context.m
    
    % intialization and set parameters & variables here for batch mode running
    if param.batchMode
        [param,var] = batchMode_param_set(param); 
        dtCell_batch_speed = var.dtCell_batch_speed;
        dtCell_batch_lick_count = var.dtCell_batch_lick_count;
        dtCell_batch_idx = var.dtCell_batch_idx;      
        dtCell_subfolder_list = var.dtCell_subfolder_list;
        if param.TwoPM_frame_sync_flag
            dtCell_batch_twoPM_frame_data = var.dtCell_batch_twoPM_frame_data;
        end
        clear var       % delete temporal variable
    end
    % dtCell_subfolder_list has path info. of behavior in the Virtual Reality system in the first column,
    % as well as experiment system log in the second column. They must be paired together,
    % otherwise data processing cannot be performed.
    
    param = param_initialzation(param);
    
    % time col: generally double type column but the first two rows contain string
    % system message col: string type column + NaN
    % message value1 col: double and string are mixed but string info. is
    % not necessary + NaN
    % message value2 col: double and string are mixed but string info. is
    % not necessary + NaN
    % message value3 col: double type column + NaN
    
%% data handling - session_data & position_data accessing, then speed calculation

    % dtCell_essen_data contains essential data, such as, trial and context
    % number, speed, and so on
    %
    % 1st col: trial number, 2nd: context number 
    % 3rd-5th: time info. of start run, black start, and end trial
    % 6-8th: (abs) position in physical environment, 9-11th: position in VR,
    % 12th: speed between start run and EndTrial(cm/s), 
    % 13th: speed between BlackStart and EndTrial(cm/s),
    % 14th: speed between start run and BlackStart(cm/s),
    % 15th: Speed in anticipation area(2600-2700mm)
    
    if param.batchMode 
        for animalIter = 10:1:length(param.animalList)
            % to avoid accessing Animal 1 & Animal 10, split path into
            % several pieces using multiple demiters - '/','-','_'. 
            % and then, compare animalList to each pieces.
            % strsplit() is required to this work
            
            % a series of animal name list: 'Animal 1', 'Animal 2', so on
            % as well as sub animal name list: 'Animal1', 'Animal2', so on
            % e.g.) animalList{1} = {'Animal 1';'Animal1'}, 
            %       animalList{2} = {'Animal 2';'Animal2'}
            
            % a series of day list: Day1-10, Day18:'1week after relearning', 
            % Day19: 'distractor', Day20: 'combined pattern', Day62:'6weeks',
            % Day63: '6weeks-distractor', Day64: '6weeks-combined'
            % 
            % param.dayList:
            % dayList{1} = {'Day1'; 'Day 1'}; dayList{2} = {'Day2'; 'Day 2'}; ...
            % dayList{12} = {'1week'; '1 week'; 'distractor'}
            
            % this var. records index of animal ID (only for one animal) & day in dtCell_subfolder_list;
            % 1st col: index of corresponding animal ID in the dtCell_subfolder_list, 
            % 2nd: index of day, 3rd+4th: path of behavior data and system log respectively
            dtCell_animal_day_idx = subfolder_list_indexing_func(param,dtCell_subfolder_list,animalIter);
                       
           for dayIter = 1:1:length(param.dayList)   
               % generally, 'Day 0', 'Day 6', and 'Day 11' are visual stimuli, thus, we do not need to analyze them
               % param.dayList begins 'Day 0', therefore, dayIter=1 depicts 'Day 0'
               
               if ~sum(dayIter == param.excludeDay_list+1)              % skip user-determined day in excludeDay_list 
                   if ~isempty(dtCell_animal_day_idx{dayIter,3}) & ~isempty(dtCell_animal_day_idx{dayIter,4})
                      % add input parameter of file path into both sub function below
                      [session_data,fullPath] = session_log_rearrange(param,dtCell_animal_day_idx{dayIter,4}); 
                      position_data = position_data_rearrange(param,dtCell_animal_day_idx{dayIter,3}); 
                      
                      if param.TwoPM_frame_sync_flag
                          % navigate a data which contains number of frame in all animal in all day
                          % which consists of *.mat file
                          % I manually made this data; it might possibly made automatically using
                          % header of *.raw data, however I do not know how to do in MATLAB.
                          % I opened individual *.raw data in Fiji with virtual stack, and recorded
                          % number of frame in an excel sheet, and then, pasted the data into a *.mat
                          % file. See an example in num_frame_data_load().
                          [num_frame_data,param] = num_frame_data_load(fullPath,param);
                      end
                      
                      % speed measurement result will be stored in the specific path
                      param.fullPath = speed_result_path_to_store(param.excelFileName,fullPath);
                      
                      % index of water reward licking count data
                      param.lick_searching_flag = is_licking(session_data(:,param.lick_msg_col+1),param.lick_msg);
                      
                      % group time,position according to event(start run, black start,etc), as well as, speed calculation
                      %
                      % dtCell_spd_essen_data:
                      % 1st col: Trial #, 2nd: Context, 3rd-5th: Time in start run/BlackStart/EndTrial
                      % 6-8th: physical position in start run/BlackStart/EndTrial,
                      % 9-11th: VR position in start run/BlackStart/EndTrial
                      % 12-14th: Speed in three condition, i) start run-EndTrial(cm/s), 
                      % ii) BlackStart-Endtrial, iii) start run-Blackstart,
                      % 15th: Speed in anticipation area(2600-2700mm)
                      % 
                      % dtCell_lick_count_data: 
                      % 1st col: Trial #, 2nd: Context,3rd: Lick count before black start,
                      % 4th: Lick count after black start
                      [dtCell_spd_essen_data,~,dtCell_lick_count_data,dtCell_trigger_time_data] = ...
                                        time_pos_lickCount_measure(session_data,position_data,param);
                           
                      if param.TwoPM_frame_sync_flag              
                          % two-photon image frame number synchronization
                          % dtCell_twoPM_frame_data:
                          % 1st col: trial#, 2nd: context#, 3rd: (accumulted)frame# in start run,
                          % 4th: frame# in BlackStart, 5th: frame# in EndTrial
                          % caution!! frame number here is always accumulated value
                          dtCell_batch_twoPM_frame_data{dtCell_batch_idx+1,1} = dtCell_animal_day_idx{dayIter,1};       % Animal ID
                          dtCell_batch_twoPM_frame_data{dtCell_batch_idx+1,2} = dtCell_animal_day_idx{dayIter,2};       % Day #
                          dtCell_batch_twoPM_frame_data{dtCell_batch_idx+1,3} = TwoPM_frame_sync_func(dtCell_trigger_time_data,dtCell_spd_essen_data,num_frame_data);   % data
                      end
                      
                      % integrate speed calculation in all days, in all animals
                      [dtCell_batch_speed] = speed_store_func(dtCell_batch_speed,dtCell_batch_idx,param,animalIter,dayIter);
                                           
                      % integrate licking count in all days, in all animals
                      [dtCell_batch_lick_count] = lickCount_store_func(dtCell_batch_lick_count,dtCell_batch_idx,param,animalIter,dayIter);
                      
                      % re-organized data(speed measurement, licking count) by three different contexts
                      [dtCell_batch_speed,dtCell_batch_lick_count] = reOrg_data_by_context(dtCell_spd_essen_data,...
                            dtCell_batch_speed,dtCell_batch_lick_count,dtCell_lick_count_data,dtCell_batch_idx,param);

                      % after processing of one day, display a message
                      dtCell_batch_idx = dtCell_batch_idx + 1;
                      processing_msg_disp_func(animalIter,dayIter,param)
                      
                   end
               end
           end
        end
        
    % single file I/O mode    
    else 
        % session log rearrangement
        % session_data is cell type variable
        [session_data,fullPath] = session_log_rearrange(param);
        
        % speed measurement result will be stored in the specific path
        param.fullPath = speed_result_path_to_store(param.excelFileName,fullPath);
        
        % position data rearrangement
        % position_data is cell type variable
        % time delay issue between session_data and position_data
        % both made by Phenosys
        position_data = position_data_rearrange(param);
        
        if param.TwoPM_frame_sync_flag
            % navigate a data which contains number of frame in all animal in all day
            % which consists of *.mat file
            % I manually made this data; it might possibly made automatically using
            % header of *.raw data, however I do not know how to do in MATLAB.
            % I opened individual *.raw data in Fiji with virtual stack, and recorded[dtCell_batch_speed,dtCell_batch_lick_count,dtCell_batch_twoPM_frame_data] = PhenoSys_data_Rearrangement(1)
            % number of frame in an excel sheet, and then, pasted the data into a *.mat
            % file. See an example in num_frame_data_load().
            [num_frame_data,param,animal,day] = num_frame_data_load(fullPath,param);
        end
        
        % index of water reward licking count data
        param.lick_searching_flag = is_licking(session_data(:,param.lick_msg_col+1),param.lick_msg);
    
        % group time,position according to event(start run, black start,etc), as well as, speed calculation
        [dtCell_spd_essen_data,dtCell_spd_essen_data_excel,dtCell_lick_count_data,dtCell_trigger_time_data] = ...
                                        time_pos_lickCount_measure(session_data,position_data,param);
        
         if param.TwoPM_frame_sync_flag
             % two-photon image frame number synchronization
             % dtCell_twoPM_frame_data:
             % 1st col: trial#, 2nd: context#, 3rd: (accumulted)frame# in start run,
             % 4th: frame# in BlackStart, 5th: frame# in EndTrial
             % caution!! frame number here is always accumulated value
             dtCell_twoPM_frame_data{1,1} = animal;         % Animal ID
             dtCell_twoPM_frame_data{1,2} = day;            % Day #
             dtCell_twoPM_frame_data{1,3} = TwoPM_frame_sync_func(dtCell_trigger_time_data,dtCell_spd_essen_data,num_frame_data); % data
         end
         
    end
    % data processing is over

    % output data handling here
    if param.batchMode
       varargout{1} = dtCell_batch_speed; 
       varargout{2} = dtCell_batch_lick_count;
       if param.TwoPM_frame_sync_flag
           varargout{3} = dtCell_batch_twoPM_frame_data;
       end
       
    else
       % dtCell_spd_essen_data:
       % 1st col: Trial #, 2nd: Context, 3rd-5th: Time in start run/BlackStart/EndTrial
       % 6-8th: physical position in start run/BlackStart/EndTrial,
       % 9-11th: VR position in start run/BlackStart/EndTrial
       % 12-14th: Speed in three condition, i) start run-EndTrial(cm/s), 
       % ii) BlackStart-Endtrial, iii) start run-Blackstart,
       % 15th: Speed in anticipation area(2600-2700mm)
       % 
       % dtCell_lick_count_data: 
       % 1st col: Trial #, 2nd: Context,3rd: lick count before black start,
       % 4th: lick count after black start
       varargout{1} = dtCell_spd_essen_data;
       varargout{2} = dtCell_spd_essen_data_excel;
       varargout{3} = dtCell_lick_count_data;
       if param.TwoPM_frame_sync_flag
           varargout{4} = dtCell_twoPM_frame_data;
       end
    end
    
    % important!!!
    % VR_Excel_Rearrangement_May_2019_Ver03_Result_data_handling.m and 
    % licking_count_organization.m handles result data to plot, respectively
     
end

function [fullPath] = speed_result_path_to_store(excelFileName,fullPath)
                      
    % speed measurement result will be stored in the specific path
	[filePath,~,~] = fileparts(fullPath);
	if ispc
        fullPath = [filePath,'\',excelFileName];
    else
        fullPath = [filePath,'/',excelFileName];
	end
                      
end

function [lick_searching_flag] = is_licking(lick_msg_data,lick_msg)
      
    % index of water reward licking count data
    lick_idx = strcmp(lick_msg_data,lick_msg);
    lick_idx = find(lick_idx);
    if isempty(lick_idx)
        lick_searching_flag = 0;  
    else
        lick_searching_flag = 1;
    end
                      
end

function processing_msg_disp_func(animalIter,dayIter,param)

    if size(param.animalList{animalIter},1) == 2
        txt_animal = param.animalList{animalIter}{1,1};
    end
    if size(param.dayList{dayIter},1) == 2
        txt_day = param.dayList{dayIter}{1,1};
    elseif size(param.dayList{dayIter},1) >= 2
        txt_day = [param.dayList{dayIter}{1,1},'-',param.dayList{dayIter}{3,1}];
    end
    
    disp([txt_animal,'-',txt_day,' is done.'])

end







