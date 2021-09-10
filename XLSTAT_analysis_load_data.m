function [xlsDT,xlsDT_property,linReg_DA_global_flag] = XLSTAT_analysis_load_data(pathName,fileName,sheets,varNameTb,animalNo,sheetNames)

    % load *.xlsx file - user set
    % this function returns cell type data of excel data sheet which includes 
    % table type of all data sheet, cell type data of each sheet's size, 
    % and cell type data of cell number in all data sheet.
    %
    % the way how to recognize loaded single sheet is linear regression or
    % discriminant analzed data is three contexts are accumulated in context column 
    % in the loaded data sheet
    %
    % xlsDT has animal#-by-sheet size, xlsDT_property has info. of cell number,
    % xlsDT size each data sheets, and sheet name

    % cell type data of xlsDT; it includes data sheet from all sheet,
    % seperated by animal number in each row, eg) 1st row: all data sheets
    % in animal1 - it would be multiple columns, 2nd row: in animal2, so on
    xlsDT = cell(length(animalNo),round(length(sheets)/length(animalNo)));
    xlsDT_property = xlsDT; 
    
    % varNameTb has cell type of table.Properties.VariableNames:
    % {'context','trial','space','time','reward','weight'}
    % these variable names are used as a reference which sheet is raw data
    % sheet and which one is analyzed data sheet by XLSTAT
    
    % sheetNames is cell type string list, which show keyword of animal number.
    % the expression described below is user determined in the Excel, and 
    % it is used essential keyword thus users have to follow the expression.
    % Otherwise, custom expression is added in the sheetNames var.
    % {'animal\d','Animal\d','M\d','Mouse\d','mouse\d'}
    % in case of discriminant analysis only: {'all ctxt','all context'}
    
    % this var. depicts the loaded analyzed data sheets is from which 
    % analysis method, linear regression and/or discriminant analysis 
    % (1st row,1st col): raw data from linear regression, 
    % (1st row,2nd col): raw data from discriminant analysis
    % (2,1): analyzed data from linear regression, 
    % (2,2): analyzed data from discriminant analysis
    % 1st row is used for data sheet's property, and 2nd row for flag of analysis method
    linReg_DA_global_flag = zeros(2,2);
    
    h = waitbar(0,'Data loading...');
    
    for sheetIter = 1:1:length(sheets)
        % this var. depicts the loaded analyzed data sheets is from which 
        % analysis method, linear regression and/or discriminant analysis 
        % [linear regression, discriminant analysis]
        linReg_DA_local_flag = [0 0];     
    
        waitbar(sheetIter/length(sheets))
        
        % extract animal number in sheet name
        for exprIter = 1:1:length(sheetNames)
            [stIdx,endIdx] = regexp(sheets{sheetIter},sheetNames{exprIter});
            if ~isempty(stIdx)
                which_animal = str2double(sheets{sheetIter}(endIdx));     
                break
            end
        end
        
        % we can recognize raw data sheet and the one made by XLSTAT using
        % VariableNames in a table properties
        % it must has 'context','trial' and 'Cell' variable name in a raw data sheet 
        opts = detectImportOptions([pathName,fileName],'sheet',sheets{sheetIter});
        varNames_single_sheet = opts.VariableNames;
        strcmp_logic = contains(varNames_single_sheet,varNameTb{1},'IgnoreCase',true); % strncmpi(varNames_single_sheet,varNameTb{1},7);      % 'context' is 7 digit string
%         % temporal code- opts.VariableNames returns weird result only in day7 2nd sheet 
%         if isequal(sheetIter,2)
%             strcmp_logic = 1;
%         end
        
        if ~isempty(find(strcmp_logic))             % this is a raw data sheet 
            xlsDT_single_sheet = readtable([pathName,fileName],'sheet',sheets{sheetIter});
            
            % check whether raw data is for linear regression or discriminant analysis:
            % if three contexts are accumulated in a context column it is
            % for discriminant analysis; otherwise it is for linear regresseion
            % if multiple context numbers are together in the context
            % column, then it is discriminant analysis. Otherwise, if there
            % is only one context number in the column it is linear
            % regression
            if isequal(length(unique(table2array(xlsDT_single_sheet(:,2)))),1)  % bug code: isequal(max(table2array(xlsDT_single_sheet(:,2))),1)     
                linReg_DA_local_flag(1) = 1;              % linear regression
                linReg_DA_global_flag(1,1) = 1;
            else                                                        
                linReg_DA_local_flag(2) = 1;              % discriminant analysis
                linReg_DA_global_flag(1,2) = 1;
            end
            [xlsDT,xlsDT_property] = xlsDT_raw_data_sheet(xlsDT_single_sheet,xlsDT,varNameTb,which_animal,xlsDT_property,sheets{sheetIter},linReg_DA_local_flag);
            
        else                                        % this is an analyzed sheet made by XLSTAT
            xlsDT_single_sheet = readtable([pathName,fileName],'sheet',sheets{sheetIter},'ReadVariableNames',false);
            
            % check whether raw data is for linear regression or discriminant analysis:
            % we can find clue in the loaded data sheet in 2nd row
            
            % method: separate one long sentence which have name of raw data sheet
            % eg) "XLSTAT 2018.5.52140  - Linear regression - Start time: 08.10.2018 at 16:48:24 / 
            %      End time: 08.10.2018 at 16:48:25 / Microsoft Excel 14.07015"
            % '-' is delimiter and ' Linear regression ' is the keyword  
            remain = xlsDT_single_sheet{3,1}; %{1,1};
            segments = strings(0);
            while (remain ~= "")
                [token,remain] = strtok(remain,'-');
                segments = [segments; token];
            end
            analysis_method_name = strtrim(segments{2});
            if strcmpi(analysis_method_name,'Linear regression')
                linReg_DA_local_flag(1) = 1;              % linear regression
                linReg_DA_global_flag(2,1) = 1;
            else
                linReg_DA_local_flag(2) = 1;              % discriminant analysis
                linReg_DA_global_flag(2,2) = 1;
            end
            
            [xlsDT,xlsDT_property] = xlsDT_analyzed_data_sheet(xlsDT_single_sheet,xlsDT,which_animal,xlsDT_property,sheets{sheetIter},linReg_DA_local_flag); 
        end
        
    end
    
    close(h)
    
end
    
function [xlsDT,xlsDT_property] = xlsDT_raw_data_sheet(xlsDT_single_sheet,xlsDT,varNameTb,which_animal,xlsDT_property,sheetsName,linReg_DA_flag)

    % in case of raw data sheet
    % we import column data only varNameTb designated
    varNames_single_sheet = xlsDT_single_sheet.Properties.VariableNames;
    varNames_idx = [];
    
    % find column data that varNameTb designated
    for varNameIter = 1:1:length(varNameTb)
        % caution) contains() is case sensitive
        idx_temp = find(contains(lower(varNames_single_sheet),lower(varNameTb{varNameIter})));
        if ~isempty(idx_temp)
            varNames_idx = [varNames_idx idx_temp];
        end
    end
    
    data_temp = xlsDT_single_sheet(:,varNames_idx);

    % in case of linear regression has multiple group of data 
    % and variable name is like 'Cell58','Cell58_1','Cell58_2'
    % therefore we have remove '_1/2' and extract cell number
    % discriminant analysis is not considered case above
    strTmp = contains(lower(varNames_single_sheet),'cell');
    strTmp = varNames_single_sheet(1,strTmp);
    strTmp = strTmp{1,end};
    rmvIdx = strfind(strTmp,'_');
    if ~isempty(rmvIdx)         % in case of linear regression
        cell_name = strTmp(1:rmvIdx-1);
    else                        % in case of discriminant analysis
        cell_name = strTmp;
    end
    cell_number = str2double(cell_name(regexp(cell_name,'\d')));    % extract cell number

    [xlsDT,xlsDT_property] = xlsDT_data_assign(data_temp,size(data_temp),cell_number,xlsDT,which_animal,xlsDT_property,sheetsName,linReg_DA_flag);
         
end

function [xlsDT,xlsDT_property] = xlsDT_analyzed_data_sheet(xlsDT_single_sheet,xlsDT,which_animal,xlsDT_property,sheetsName,linReg_DA_flag)

    % finding cell number in analyzed data sheet is not necessary here
    % we can find it in XLSTAT_analysis_reOrg_load_data()
    [xlsDT,xlsDT_property] = xlsDT_data_assign(xlsDT_single_sheet,size(xlsDT_single_sheet),0,xlsDT,which_animal,xlsDT_property,sheetsName,linReg_DA_flag);
    
end

function [xlsDT,xlsDT_property] = xlsDT_data_assign(data_single_sheet,data_single_sheet_size,data_single_sheet_cellNo,xlsDT,which_animal,xlsDT_property,sheetsName,linReg_DA_flag)

    % find empty column in a specific row(designed by which_animal)
    % the empty column is the place where we store data
    for emptIdx = 1:1:size(xlsDT,2)
        if isempty(xlsDT{which_animal,emptIdx})
            break
        end
    end
    Properties = struct;
    
    xlsDT{which_animal,emptIdx} = data_single_sheet;
    Properties.data_size = data_single_sheet_size;
    Properties.cell_number = data_single_sheet_cellNo;
    Properties.sheet_name = sheetsName;
    if isequal(linReg_DA_flag(1,1),1)
        Properties.linear_regression = 'Y';     
    elseif isequal(linReg_DA_flag(1,2),1)
        Properties.discriminant_analysis = 'Y';
    end
    xlsDT_property{which_animal,emptIdx} = Properties;
    

end