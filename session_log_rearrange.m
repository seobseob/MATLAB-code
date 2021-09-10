function [xls_data,fullPath] = session_log_rearrange(param,varargin)

    time_col = param.time_col;
    sys_msg_col = param.sys_msg_col;
    msg_col = param.msg_col;
    
    if isempty(varargin)    % single file I/O mode
        [FileName,PathName] = uigetfile('*.*','Select the Session data');
        fullPath = [PathName,FileName];
    else                    % batch mode
        fullPath = cell2mat(varargin);
    end
    
    if ~contains(lower(fullPath),'session')
        error('You did not choose Session data file')
    end
    
%     opts = detectImportOptions([PathName,FileName],'Delimiter',';','NumHeaderLines', 1);

    % technical problem - I cannot solve this issue due to 'HeaderLines' parameter
%     csv_data = readtable([PathName,FileName],'Delimiter',';','ReadVariableNames',false,...
%         'HeaderLines',1,'Format','%q %q %q %q %f %f %f %f %s %s %s %s %s %s %s %f %f');

    [~,~,xls_data] = xlsread(fullPath);
    time_data = cell(size(xls_data,1),1);
    
    %% time information conversion
    
    % xls_data in the first column(time info.) contains string and datetime
    % type data together, thus, we have to handle datetime data separately

    numeric_idx = [];
    for iter = 1:1:size(xls_data,1)
       if isnumeric(xls_data{iter,1}) 
           numeric_idx = [numeric_idx; iter];
       else
           non_numeric_idx = iter;
       end
    end
    timeArr = cell2mat(xls_data(numeric_idx,time_col));
    % eg.) time_str = 19:36:47.711
    time_str = datestr(timeArr,'HH:MM:SS.FFF');
    % time_cell depicts datetime-type time information from time_str
    time_cell = datetime(time_str,'InputFormat','HH:mm:ss.SSS','Format','HH:mm:ss.SSS');
     
    % 'datatime' type variables cannot convert to cell type, so store
    % 'datetime' type var. into a cell type individually using for-loop
    for iter = numeric_idx(1):1:numeric_idx(end)
        time_data{iter,1} = time_cell(iter-non_numeric_idx,1);
    end
        
    %% NaN element handling
    
    % time col: generally double type column but the first two rows contain string
    % system message col: string type column + NaN
    % message value1 col: double and string are mixed but string info. is
    % not necessary + NaN
    % message value2 col: double and string are mixed but string info. is
    % not necessary + NaN
    % message value3 col: double type column + NaN
        
    h = waitbar(0,'Get rid of NaN element. Please wait...');
    
    for iter = 1:1:size(xls_data,1)
        waitbar(iter/size(xls_data,1))
        
        if isnan(xls_data{iter,sys_msg_col})
            % insert white space intensionally - string type column
            xls_data{iter,sys_msg_col} = ' ';       
        end
        if iter > 1         % keep variable header in session_data
            for msg_col_iter = 1:1:length(msg_col)
                % keep NaN element for array type data handling
                if ischar(xls_data{iter,msg_col(msg_col_iter)})
                    % insert NaN intensionally - double type column
                    xls_data{iter,msg_col(msg_col_iter)} = NaN;     
                end
            end
        end
    end
    close(h)
    
    xls_data = [time_data, xls_data];
    
end