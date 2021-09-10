function [param,var] = batchMode_param_set(param) 

% intialization and set parameters & variables here for batch mode running

    % subfolder has to include user-determined file list
    param.searchingFile_list = {'*Ani*.csv', 'SessionLog*Ani*.xlsx'};  
    param.subFolder_excludeFile_list = {'30min'};
%         param.subFolder_excludeFolder_list = {'Day'};
    param.excludeDay_list = [0,6,11];
    
    % this function searches sub-folders in user-determined folder
    % according to user input parameter, this function might returns only
    % sub-folder name list, or sub-folder name list where includes files users
    % want to find. 
    % option) users can set excluding sub-folders which has specific file name
    %
    % e.g.) IS_subfolder_searching() returns sub-folder name list,
    %       IS_subfolder_searching(searchFile) returns sub-folder name list
    %        where includes files users want to find
    %       IS_subfolder_searching(searchFile, exclude_fileStr) returns
    %        sub-folder name list where excludes files users want ot exlcude
    var.dtCell_subfolder_list = IS_subfolder_searching(param.searchingFile_list,param.subFolder_excludeFile_list);

    % a series of animal name list: 'Animal 1', 'Animal 2', so on
    % as well as sub animal name list: 'Animal1', 'Animal2', so on
    % e.g.) animalList{1} = {'Animal 1';'Animal1'}, 
    %       animalList{2} = {'Animal 2';'Animal2'}
    param.animalList = animalList_sub_func(param.animal_number);
    
    % a series of day list: Day1-10, Day18:'1week after relearning', 
    % Day19: 'distractor', Day20: 'combined pattern', Day62:'6weeks',
    % Day63: '6weeks-distractor', Day64: '6weeks-combined'
    % 
    % param.dayList:
    % dayList{1} = {'Day1'; 'Day 1'}; dayList{2} = {'Day2'; 'Day 2'}; ...
    % dayList{12} = {'1week'; '1 week'; 'distractor'}
    param.dayList = dayList_sub_func(param.day);

    var.dtCell_batch_speed = {'Animal','Day','Speed in Context1','Speed in Context2','Speed in Context3',...
        'Speed in Context1','Speed in Context2','Speed in Context3',...
        'Speed in Context1','Speed in Context2','Speed in Context3',...
        'Speed in Context1','Speed in Context2','Speed in Context3'};

    var.dtCell_batch_lick_count = {'Animal','Day','lick count by position in Context1',...
        'lick count by position in Context2','lick count by position in Context3',...
        'lick count by time in Context1','lick count by time in Context2',...
        'lick count by time in Context3'};
    var.dtCell_batch_idx = 1;
    
    if param.TwoPM_frame_sync_flag
        var.dtCell_batch_twoPM_frame_data = {'Animal','Day','Data'};
    end
end



