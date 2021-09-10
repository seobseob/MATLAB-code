function [unDim_test] = XLSTAT_analysis_pVal(xlsDT_single_sheet,condStrTb,cellNo,pVal_level,sheetName,unDim_test,row_col)

    % 4) find each cell's p-value of 'Unidimensional test of equality of the means of the classes:'
    % this table consists of # cell-by-6,
    % 'Variable','Lambda','F','DF1','DF2','p-value' are in each column
    % we are interested in the last column 'p-value', but sometime XLSTAT shows
    % p-value as '<0.0001' so we have to find it and convert 0.0001 in double 
    % this function returns table type data of 'Unidimensional test of equality of the means of the classes'
    % and binary type data of significant info.
    
    unDim_strcmp_logic = strcmpi(xlsDT_single_sheet{:,1},condStrTb{5});
    unDim_idx_temp1 = find(unDim_strcmp_logic);                     % find 'Unidimensional test of equality of the means of the classes:'

    cellNo_st=[condStrTb{6},num2str(1)];                  % find start index of Undimensional test table
    unDim_idx_st = find_idx(xlsDT_single_sheet,unDim_idx_temp1, cellNo_st);
    
    cellNo_end=[condStrTb{6},num2str(cellNo)];            % find end index of Undimensional test table
    unDim_idx_end = find_idx(xlsDT_single_sheet,unDim_idx_temp1, cellNo_end);

    unDim_tbl = xlsDT_single_sheet(unDim_idx_st:unDim_idx_end,1:6);              % make a small table of Undimensional test table
    unDim_VariableNames = {'Variable','Lambda','F','DF1','DF2','P_value'};
    unDim_tbl.Properties.VariableNames = unDim_VariableNames;

    unDim_pVal = zeros(cellNo,1);                                   % if p-value is below pVal_level(= significant), then return 1 otherwise 0
    for iter = 1:1:cellNo
       if strncmpi(unDim_tbl{iter,6},'<',1)                         % in a case with p-value as '<0.0001', we convert it into '0.0001' in a table
            unDim_tbl.P_value{iter} = '0.0001';
            unDim_pVal(iter) = 1;
       elseif ~isnan(str2double(unDim_tbl{iter,6})) & str2double(unDim_tbl{iter,6})<pVal_level
            unDim_pVal(iter) = 1;
       end
    end

    unDim_tbl(:,end+1) = num2cell(unDim_pVal);                      % add significant info(1: significant,0: non) into a table
    unDim_VariableNames = [unDim_VariableNames 'Significant'];      % add variable name too
    unDim_tbl.Properties.VariableNames = unDim_VariableNames;

    Property.unDim_test_tbl = unDim_tbl;
    Property.sheet_name = sheetName;
    Property.unDim_test_pVal = unDim_pVal;
    unDim_test{row_col(1),row_col(2)} = Property; 
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