function [csv_data] = position_data_rearrange(param,varargin)

    time_col = param.time_col;
    
    if isempty(varargin)    % single file I/O mode
       [FileName,PathName] = uigetfile('*.csv','Select the Position data');
       fullPath = [PathName,FileName];
    else                    % batch mode
       fullPath = cell2mat(varargin);
    end
   
    wait_h = waitbar(0, 'Behavior data re-arangement...');
    opts = detectImportOptions(fullPath);
    format_str = [];
    for iter = 1:1:length(opts.VariableNames)
        format_str = [format_str, '%f'];
    end 
    csv_data = readtable(fullPath,'Delimiter',';','ReadVariableNames',false, 'Format',format_str);
    time_data = cell(size(csv_data,1),1);

    timeArr = table2array(csv_data(:,time_col));
    % eg.) time_str = 19:36:47.711
    time_str = datestr(timeArr,'HH:MM:SS.FFF');     
    % time_cell depicts datetime-type time information from time_str
    time_cell = datetime(time_str,'InputFormat','HH:mm:ss.SSS','Format','HH:mm:ss.SSS'); 
    
    % 'datatime' type variables cannot convert to cell type, so store
    % 'datetime' type var. into a cell type individually using for-loop
    for iter = 1:1:size(csv_data,1)
        time_data{iter,1} =  time_cell(iter,1);     
    end

    csv_data = table2cell(csv_data); 
    csv_data = [time_data, csv_data];

    close(wait_h)
    
end