function [xlsDT,xlsDT_property,rawDT_oneHot_flag] = XLSTAT_analysis_reOrg_load_data(xlsDT,xlsDT_property,varNameTb)

    % re-organize cell type data of xlsDT using xlsDT_property
    % make relationship between raw and analyzed data, 
    % eg) analyzed data come from which raw data
    % xlsDT has animal#-by-sheet size, xlsDT_property has info. of cell number,
    % xlsDT size each data sheets, and relationship among data sheets
    %
    % input parameter of xlsDT_property consists of
    % Properties.data_size, Properties.cell_number, Properties.sheet_name
    %
    % output parameter of xlsDT_property consists of
    % Properties.data_size, Properties.cell_number, Properties.sheet_name,
    % and relationship between raw and analyzed data sheet into xlsDT_property
    [row,col] = size(xlsDT);
    rawDT_oneHot_flag = zeros(row,col);     % this var. shows raw data sheet as '1', otherwise analyzed data sheet
    
    h = waitbar(0,'Data loading...');
    for rowIter = 1:1:row
        rawDT_flag = 0;         % this var. depicts number of raw data table,eg) i-th raw data table
        rawDT_col_flag = [];    % this var. stores column number which depicts raw data table in a row
        analDT_col_flag = [];   % this var. stores column number which depicts analyzed data table in a row
        
        waitbar(rowIter/row)
        
        % cf) if analyzed data sheet is placed in the first place in xlsDT,
        % it is not possible to make relationship analyzed data to a
        % specific raw data table
        %
        % find raw data table first!
        for colIter = 1:1:col
            
            xlsDT_single_sheet = xlsDT{rowIter,colIter};
            
            % we can recognize raw data sheet and the one made by XLSTAT using
            % VariableNames in a table properties
            varNames_single_sheet = xlsDT_single_sheet.Properties.VariableNames;
            % it must has 'trial', 'context' and 'Cell' variable name in a raw data sheet 
            strcmp_logic = strcmpi(varNames_single_sheet,varNameTb{1}) | strcmpi(varNames_single_sheet,varNameTb{2});     
            if ~isempty(find(strcmp_logic))         % this is a raw data sheet 
                % we give number of raw dta table, eg) i-th raw data table
                rawDT_flag = rawDT_flag + 1;
                [xlsDT_property] = xlsDT_raw_data_sheet(xlsDT_property,[rowIter, colIter],rawDT_flag);
                                
                % to avoid repeatatoin when searching for raw data
                % table, we stores column number which depicts raw
                % data table in a row
                rawDT_col_flag = [rawDT_col_flag, colIter];
            
            else                                    % this is an analyzed data sheet
                % we make relationship between raw and analyzed data table
                % to avoid repeatatoin when searching for analyzed data
                % table, we stores column number which depicts analyzed
                % data table in a row
                analDT_col_flag = [analDT_col_flag, colIter];
            end
        end
        
        for dummyIter = 1:1:length(analDT_col_flag)
           colIter = analDT_col_flag(dummyIter);
           xlsDT_single_sheet_str = xlsDT{rowIter,colIter}{4,1};%{2,1};
           [xlsDT_property] = xlsDT_analyzed_data_sheet(xlsDT_single_sheet_str,xlsDT_property,[rowIter colIter],rawDT_col_flag);
            
        end

        rawDT_oneHot_flag(rowIter,rawDT_col_flag) = 1;
    end
    close(h)
    
end

function [xlsDT_property] = xlsDT_raw_data_sheet(xlsDT_property,row_col,rawDT_flag)

    % input parameter of xlsDT_property consists of
    % Properties.data_size, Properties.cell_number, Properties.sheet_name
    % we add number of raw data sheet into xlsDT_property
    xlsDT_property{row_col(1),row_col(2)}.raw_sheet = 'Y';
    xlsDT_property{row_col(1),row_col(2)}.raw_sheet_number = rawDT_flag;
    
end

function [xlsDT_property] = xlsDT_analyzed_data_sheet(xlsDT_single_sheet_str,xlsDT_property,row_col,rawDT_col_flag)

    % i) we find the name of raw data sheet
    % i-1) separate one long sentence which have name of raw data sheet
    % eg) "Y / Qualitative: Workbook = Discriminant Analysis-DREADDs-Control-reward period consideration-Day4.xlsx / 
    % Sheet = Day4-animal1-licking time-Rnd / Range = 'Day4-animal1-licking time-Rnd'!$D:$D / 210 rows and 1 column"
    % '/' is delimiter and 'Sheet = ' is the keyword
    segments = xlsDT_string_token(xlsDT_single_sheet_str,'/');
    
    % i-2) find real raw data sheet name in ' Sheet = Day4-animal1-licking time-Rnd '
    % '=' is delimiter and 'Sheet = ' is the keword, and we have to trim white space
    for segIter = 1:1:size(segments,1)
       if ~isempty(strfind(segments{segIter},'Sheet = '))
           segments2 = xlsDT_string_token(segments{segIter},'=');
           break
       end
    end
    raw_sheet_name = strtrim(segments2{2});
   
    % ii) we make relationship between raw and analyzed data sheet and
    % iii) find cell number from raw data sheet
    % row_col depicts target(analyzed data sheet) row and column in xlsDT_property
    [xlsDT_property] = xlsDT_raw_anal_relation(xlsDT_property,row_col,rawDT_col_flag,raw_sheet_name);
    
end

function [segments] = xlsDT_string_token(remain,delimiter)
    
    segments = strings(0);
    while (remain ~= "")
        [token,remain] = strtok(remain,delimiter);
        segments = [segments; token];
    end
end

function [xlsDT_property] = xlsDT_raw_anal_relation(xlsDT_property,row_col,rawDT_col_flag,raw_sheet_name)

    % input parameter of xlsDT_property consists of
    % Properties.data_size, Properties.cell_number, Properties.sheet_name
    % we add relationship between raw and analyzed data sheet into xlsDT_property
    %
    % row_col depicts target row and column in xlsDT_property
    for dummyIter = 1:1:length(rawDT_col_flag)
       colIter = rawDT_col_flag(dummyIter);
       if strcmpi(xlsDT_property{row_col(1),colIter}.sheet_name,raw_sheet_name)
          rawSheetNo = xlsDT_property{row_col(1),colIter}.raw_sheet_number;
          rawSheetName = xlsDT_property{row_col(1),colIter}.sheet_name;
          cellNo = xlsDT_property{row_col(1),colIter}.cell_number;
                    
          xlsDT_property{row_col(1),row_col(2)}.analyzed_sheet = 'Y';
          xlsDT_property{row_col(1),row_col(2)}.raw_sheet_number = rawSheetNo;
          xlsDT_property{row_col(1),row_col(2)}.raw_sheet_name = rawSheetName;
          xlsDT_property{row_col(1),row_col(2)}.cell_number = cellNo;
          break
       end
        
    end

end



