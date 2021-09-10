

% automation of excel work the XLSTAT worked

%%
% user determined parameters

% 1x: handling discriminant analysis data, 2x: linear regression
% case discriminant analysis: 1: context cell, 2: reward-context cell, 3: reward cell
% case linear regression: 1: space cell, 2: speed cell, 3: time cell
% workingMode = 11;                
% XLSTAT_analysis_userSet_check(workingMode);      % if workingMode is out of choice described above, raise error dialog to users

condStrTb = {'Wilks','F (Observed value)','Confusion matrix for the cross-validation results:','% correct',...
    'Unidimensional test of equality of the means of the classes:','Cell','R²','Type III Sum of Squares analysis'};

varNameTb = {'context','trial','space','time','reward','weight'};

% sheetNames is cell type string list, which show keyword of animal number.
% the expression described below is user determined in the Excel, and 
% it is used essential keyword thus users have to follow the expression.
% Otherwise, custom expression is added in the sheetNames var.
sheetNames = {'animal\d','Animal\d','M\d','A\d','a\d','Mouse\d','mouse\d'};
% sheetNames = {'all ctxt','all context'};      % only in case of discriminant analysis

pVal_level = 0.05;         % user determined p-value percentage

%%
% user select a target file (*.xlsx or *.xls) which has analyzed data by XLSTAT
% the input data must have a keyword: 'big data table'
% e.g.) day4_big data table_common cells across days_for pos+spd+ctxt factors analysis.xlsx
[fileName,pathName] = uigetfile({'*.xlsx';'*.xls'},'Select the file');

%%
% get information of target file and get rid of unnecessary(or unknown) sheets in a loaded file
% this function returns cell type data of appropriate sheet names and
% double type data of animal number(how many animals in the data table)
[sheets,animalNo] = XLSTAT_analysis_xlsfinfo(fileName,pathName,sheetNames);

%%
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
% linReg_DA_flag depicts the loaded analyzed data sheets is from which 
% analysis method, linear regression and/or discriminant analysis 
% (1st row,1st col): raw data from linear regression, 
% (1st row,2nd col): raw data from discriminant analysis
% (2,1): analyzed data from linear regression, 
% (2,2): analyzed data from discriminant analysis
% 1st row is used for data sheet's property, and 2nd row for flag of analysis method
[xlsDT,xlsDT_property,linReg_DA_flag] = XLSTAT_analysis_load_data(pathName,fileName,sheets,varNameTb,animalNo,sheetNames);

%%
% re-organize cell type data of xlsDT using xlsDT_property
% make relationship between raw and analyzed data, 
% eg) analyzed data come from which raw data
% xlsDT has animal#-by-sheet size, xlsDT_property has info. of cell number,
% xlsDT size each data sheets, data sheet name, and relationship among data sheets
%
% output parameter of xlsDT_property consists of
% Properties.data_size, Properties.cell_number, Properties.sheet_name,
% and relationship between raw and analyzed data sheet into xlsDT_property
% rawDT_oneHot_flag shows raw data sheet as '1', otherwise analyzed data sheet
[xlsDT,xlsDT_property,rawDT_oneHot_flag] = XLSTAT_analysis_reOrg_load_data(xlsDT,xlsDT_property,varNameTb);

%%
% Gathering essential data from multiple excel sheets in loop, analyzed data sheet is
% recognited by rawDT_oneHot_flag
% 1) number of cell, which has status 'OUT'
% in case of linear regression
% LR-2) find R-squared value
% LR-3) find 'Type III Sum of Squares analysis:'
%
% in case of discriminant analysis
% DA-2) 'F (Observed value)' of 'Wilks'' Lambda test (Rao''s approximation):'
% DA-3) correct % of 'Confusion matrix for the cross-validation results:'
% DA-4) each cell's p-value of 'Unidimensional test of equality of the means of the classes:'
% are calculated in the same loop shown below

% size of analyzed data sheet in the xlsDT
[row,col] = size(rawDT_oneHot_flag);
numCell_len = cell(row,col);
if isequal(linReg_DA_flag(2,1),1)       % if we have analyzed data from linear regression
    R_squared_value = cell(row,col);
    type3_SS = cell(row,col);
end
if isequal(linReg_DA_flag(2,2),1)       % if we have analyzed data from discriminant analysis 
    wilks_lambda_test_F = cell(row,col);
    crossVal_correctP = cell(row,col);
    unDim_test = cell(row,col);
end

for rowIter = 1:1:row
    for colIter = 1:1:col
        if isequal(rawDT_oneHot_flag(rowIter,colIter),0)

            % this is analyzed data sheet
            xlsDT_single_sheet = xlsDT{rowIter,colIter};
            sheetName = xlsDT_property{rowIter,colIter}.sheet_name;
            cellNo = xlsDT_property{rowIter,colIter}.cell_number;
            if cellNo > 100
                cellNo = 100;
            end

            % 1) find number of cell, which has status 'OUT'
            % this function returns double type data of number of cell
            [numCell_len] = XLSTAT_analysis_numCell(xlsDT_single_sheet,sheetName,numCell_len,[rowIter colIter],cellNo);
            
            remain = xlsDT_single_sheet{3,1}; %{1,1};
            segments = strings(0);
            while (remain ~= "")
                [token,remain] = strtok(remain,'-');
                segments = [segments; token];
            end
            analysis_method_name = strtrim(segments{2});
                        
            if isequal(linReg_DA_flag(2,1),1) & strcmpi(analysis_method_name,'Linear regression')      % if we have analyzed data from linear regression
                % LR-2) find R-squared value
                [R_squared_value] = XLSTAT_analysis_R_squared_value(xlsDT_single_sheet,condStrTb,sheetName,R_squared_value,[rowIter colIter]);
                
                % LR-3) find 'Type III Sum of Squares analysis'
                [type3_SS] = XLSTAT_analysis_type3_SS(xlsDT_single_sheet,condStrTb,cellNo,pVal_level,sheetName,type3_SS,[rowIter colIter]);
            end
            
            if isequal(linReg_DA_flag(2,2),1) & strcmpi(analysis_method_name,'Discriminant Analysis (DA)') % if we have analyzed data from discriminant analysis 
                % DA-2) find 'F (Observed value)' of 'Wilks'' Lambda test (Rao''s approximation):'
                % When we find an observatoin named 'F (Observed value)' in a table, the
                % strcmp() function returns several observation. We have to find a sub
                % title 'Wilks'' Lambda test(Rao''s approximation):' first.
                % However, the sub title has quote mark, like 'Wilks'' Lambda test
                % (Rao''s approximation):', thus we have to use strncmp() command, not strcmp()
                % this function returns cell type data table of wilks lambda test F 
                % 'F (Observed value)' which each cell has struct type data of F value 
                % and whose sheet name 
                %
                % xlsDT has animal#-by-sheet size, xlsDT_property has info. of cell number,
                % xlsDT size each data sheets, data sheet name, and relationship among data sheets
                %
                % output parameter of xlsDT_property consists of
                % Properties.data_size, Properties.cell_number, Properties.sheet_name,
                % and relationship between raw and analyzed data sheet into xlsDT_property
                % rawDT_oneHot_flag shows raw data sheet as '1', otherwise analyzed data sheet
                [wilks_lambda_test_F] = XLSTAT_analysis_Wilks_lambda_test(xlsDT_single_sheet,condStrTb,sheetName,wilks_lambda_test_F,[rowIter colIter]);

                % DA-3) find correct % of 'Confusion matrix for the cross-validation results:'
                % this function returns table type data of '% correct'
                [crossVal_correctP] = XLSTAT_analysis_correctP(xlsDT_single_sheet,condStrTb,sheetName,crossVal_correctP,[rowIter colIter]);

                % DA-4) find each cell's p-value of 'Unidimensional test of equality of the means of the classes:'
                % this table consists of # cell-by-6,
                % 'Variable','Lambda','F','DF1','DF2','p-value' are in each column
                % we are interested in the last column 'p-value', but sometime XLSTAT shows
                % p-value as '<0.0001' so we have to find it and convert 0.0001 in double 
                % this function returns table type data of 'Unidimensional test of equality of the means of the classes'
                % and binary type data of significant info.
                [unDim_test] = XLSTAT_analysis_pVal(xlsDT_single_sheet,condStrTb,cellNo,pVal_level,sheetName,unDim_test,[rowIter colIter]);
            end
        end
    end
end

% original code 
% [wilks_lambda_test_F] = XLSTAT_analysis_Wilks_lambda_test(xlsDT,condStrTb,xlsDT_property,rawDT_oneHot_flag);
% [numCell_len] = XLSTAT_analysis_numCell(xlsDT,xlsDT_property,rawDT_oneHot_flag);
% [crossVal_correctP] = XLSTAT_analysis_correctP(xlsDT,condStrTb,row);
% [unDim_tbl,unDim_pVal] = XLSTAT_analysis_pVal(xlsDT,condStrTb,cellNo,pVal_level);

%% 
% we have integrated data sheets with raw and analyzed data, and 
% its properties are stored in a data sheet the same structure of
% integrated one.
% we are able to calculation anything we want using the data sheets. 
% However, this part is treaky; we have to set all possibility of
% calculation or users set manually including designation of name of data sheet
    
%%
% case 1 - discriminant analysis

% i) average % of reward cells in reward time
% we have to need data of cell_number from xlsDT_property, unDim_test_pVal
% from unDim_test. Accessing data sheet is designated by users manually
acc_col = 2;        % access 5th column in data sheet
animal_num = 5;
ptg_cell_vec = [];

for animalIter = 1:1:animal_num
    pVal_array = unDim_test{animalIter,acc_col}.unDim_test_pVal;
    cellNo = xlsDT_property{animalIter,acc_col}.cell_number;
    ptg_cell_vec = [ptg_cell_vec; length(find(pVal_array))/cellNo*100];

end
avg_ptg_cell = mean(ptg_cell_vec);
sem_ptg_cell = std(ptg_cell_vec)/sqrt(animal_num);

% ii) average % of correct reward prediction in reward time
% we have to need data of correct_percentage from crossVal_correctP
acc_col = 2;        % access 5th column in data sheet
animal_num = 5;
ptg_correct_vec = [];

for animalIter = 1:1:animal_num
    correct_ptg_array = table2array(crossVal_correctP{animalIter,acc_col}.correct_percentage);
    % in case of reward/non-reward
    ptg_correct_vec = [ptg_correct_vec; mean(correct_ptg_array)*100];
    % in case of context1/2/3
%     ptg_correct_vec = [ptg_correct_vec; correct_ptg_array'*100];
end
avg_ptg_correct = mean(ptg_correct_vec,1);
% in case of reward/non-reward 
sem_ptg_correct = std(ptg_correct_vec)/sqrt(animal_num);

% in case of context 1/2/3
% sem_ptg_correct = std(ptg_correct_vec,1)./sqrt(animal_num);


%% 
% case 2 - linear regression
%
% Gathering essential data from multiple excel sheets in loop, analyzed data sheet is
% recognited by rawDT_oneHot_flag
% 1) number of cells, which has (user determined) significant p-value
% in case of linear regression
% LR-2) find R-squared value
% LR-3) find 'Type III Sum of Squares analysis:'

animal_num = 5;

numCell_len_mat = zeros(animal_num,3);      % store number of cells, which has (user determined) significant p-value, in all animal in all context
R_squared_value_mat = zeros(animal_num,3);  % store R-Squared value in all animal in all context
type3_SS_cell = cell(animal_num,4);         % store predicting cells operant in single vs. multiple contexts

for animalIter = 1:1:animal_num
    ctxtIter = [1 1];
    type3_SS_Sig_mat = [];
    
    % 1) find number of cell, which has (user determined) significant p-value
    % this function returns % of number of cell
    for colIter = 1:1:size(type3_SS,2)
        if ~isempty(type3_SS{animalIter,colIter})
            numCell_len_mat(animalIter,ctxtIter(1)) = length(find(type3_SS{animalIter,colIter}.type3_SS_pVal)) / ...
                                                        size(type3_SS{animalIter,colIter}.type3_SS_pVal,1) * 100;
            ctxtIter(1) = ctxtIter(1) + 1;
        end
    end
    
    % LR-2) find R-squared value
    for colIter = 1:1:size(R_squared_value,2)
        if ~isempty(R_squared_value{animalIter,colIter})
            R_squared_value_mat(animalIter,ctxtIter(2)) = R_squared_value{animalIter,colIter}.R_squared_value;
            ctxtIter(2) = ctxtIter(2) + 1;
        end
    end

    % LR-3) find 'Type III Sum of Squares analysis'
    for colIter = 1:1:size(type3_SS,2)
        if ~isempty(type3_SS{animalIter,colIter})
            type3_SS_Sig_mat = [type3_SS_Sig_mat, type3_SS{animalIter,colIter}.type3_SS_tbl.Significant];
        end
    end
    type3_SS_Sig_mat = sum(type3_SS_Sig_mat,2);
    type3_SS_cellNo = size(type3_SS_Sig_mat,1);
    for multiCtxtIter = 1:1:4 
       % percentage of predicting cells operant in '0 context'
       type3_SS_cell{animalIter,1} = length(find(type3_SS_Sig_mat == 0)) / type3_SS_cellNo * 100;     
       
       % percentage of predicting cells operant in '1 context'
       type3_SS_cell{animalIter,2} = length(find(type3_SS_Sig_mat == 1)) / type3_SS_cellNo * 100;     
       
       % percentage of predicting cells operant in '2 contexts'
       type3_SS_cell{animalIter,3} = length(find(type3_SS_Sig_mat == 2)) / type3_SS_cellNo * 100;     
       
       % percentage of predicting cells operant in '3 contexts'
       type3_SS_cell{animalIter,4} = length(find(type3_SS_Sig_mat == 3)) / type3_SS_cellNo * 100;     
    end
end

avg_numCell_len_mat = mean(numCell_len_mat,1);          % average % of predicting cells
avg_R_squared_value_mat = mean(R_squared_value_mat,1);  % average R-Squared value of predicting cells
avg_type3_SS_cell = mean(cell2mat(type3_SS_cell),1);    % average speed predicting cells operant in single vs. multiple contexts
           












