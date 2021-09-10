function [type3_SS] = XLSTAT_analysis_type3_SS(xlsDT_single_sheet,condStrTb,cellNo,pVal_level,sheetName,type3_SS,row_col)

    % LR-3) find each cell's p-value of 'Type III Sum of Squares analysis:'
    % this table consists of # cell-by-6,
    % 'Source','DF','Sum of squares','Mean squares','F','Pr > F' are in each column
    % we are interested in the last column 'p-value', but sometime XLSTAT shows
    % p-value as '<0.0001' so we have to find it and convert 0.0001 in double 
    % this function returns table type data of 'type3_SS'
    % and binary type data of significant info.
    
    t3SS_strcmp_logic = strfind(xlsDT_single_sheet{:,1},condStrTb{8});
    for ii = 1:1:size(t3SS_strcmp_logic,1)                % find 'Type III Sum of Squares analysis:' 
        if t3SS_strcmp_logic{ii} == 1
            t3SS_idx_temp1 = ii;
            break
        end
    end
%     t3SS_idx_temp1 = find(cell2mat(t3SS_strcmp_logic));             % find 'Type III Sum of Squares analysis:'

    cellNo_st=[condStrTb{6},num2str(1)];                  % find start index of Type III SS table
    t3SS_idx_st = find_idx(xlsDT_single_sheet,t3SS_idx_temp1, cellNo_st);
    
    cellNo_end=[condStrTb{6},num2str(cellNo)];            % find end index of Type III SS table
    t3SS_idx_end = find_idx(xlsDT_single_sheet,t3SS_idx_temp1, cellNo_end);

    t3SS_tbl = xlsDT_single_sheet(t3SS_idx_st:t3SS_idx_end,1:6);              % make a small table of Type III SS table
    t3SS_VariableNames = {'Source','DF','SumOfSquares','MeanSquares','F','P_value'};
    t3SS_tbl.Properties.VariableNames = t3SS_VariableNames;

    t3SS_pVal = zeros(cellNo,1);                                   % if p-value is below pVal_level(= significant), then return 1 otherwise 0
    for iter = 1:1:cellNo
       if strncmpi(t3SS_tbl{iter,6},'<',1)                         % in a case with p-value as '<0.0001', we convert it into '0.0001' in a table
            t3SS_tbl.P_value{iter} = '0.0001';
            t3SS_pVal(iter) = 1;
       elseif ~isnan(str2double(t3SS_tbl{iter,6})) & str2double(t3SS_tbl{iter,6})<pVal_level
            t3SS_pVal(iter) = 1;
       end
    end

    t3SS_tbl(:,end+1) = num2cell(t3SS_pVal);                      % add significant info(1: significant,0: non) into a table
    t3SS_VariableNames = [t3SS_VariableNames 'Significant'];      % add variable name too
    t3SS_tbl.Properties.VariableNames = t3SS_VariableNames;

    Property.type3_SS_tbl = t3SS_tbl;
    Property.sheet_name = sheetName;
    Property.type3_SS_pVal = t3SS_pVal;
    type3_SS{row_col(1),row_col(2)} = Property; 
end


function idx = find_idx(xlsDT,idx_temp,cell_num)
    
    iter = 1;
    while(~contains(xlsDT{idx_temp+iter,1},cell_num,'IgnoreCase',true)) %(~strcmpi(xlsDT{idx_temp+iter,1},cell_num))
        iter = iter+1;
        if iter > size(xlsDT,1)
           errordlg('Type III Sum of Squares analysis is not found','Data Error');      % show users error dialog
           return
        end
    end
    idx = idx_temp+iter;

end


