function [loadedDataSpeed,loadedDataFluor,loadedDataSpk] = VR_Excel_Rearrangement_importData2(param)
% Raw Data Structure(*.xls or *.xlsx file)
% 1st column: time(sec), 2nd: x-position in corridor(mm), 3rd: corridor flag(seperated 3 corridors-0,200,400)
% 4th: 2PM trigger number(not corrected)
% * Usually x-position starts 0 and ends around 1800 but not always

%% variables initialization
dirName = param.miceID_day;     % eg) '13775-day1', '13775-day4', so on
dirFindFlag = 0;                % if specific director were found this var. is assinged '1', if not '0'
fileNameSpd = param.speedName;
fileNameSpdExt = param.speedNameExtra;
fileNameFluo = param.fluoName;
fileNameSpk = param.spkName;
cells = param.good_cells;

%% searching folders 

% 1) searching for specific folder
dirNameWC = ['*',dirName,'*'];
dirList = dir(dirNameWC);

for dirIter = 1:1:size(dirList,1)
    if dirList(dirIter).isdir
        cur_path = cd(dirList(dirIter).name);
        dirFindFlag = 1;
        break
    end
end

%% searching files

if isequal(dirFindFlag,0)           % if specific directory is found
    msg = [dirName,' not found'];
    errordlg(msg,'File Error');    
else                                % if specific directory is found, 2) searching for specific files
    [loadedDataSpeed] = Speed_file_loading(fileNameSpd,fileNameSpdExt);
    [loadedDataFluor,loadedDataSpk] = Flour_Spk_file_loading(fileNameFluo,fileNameSpk,cells);
end

cd(cur_path)


function [loadedDataSpeed] = Speed_file_loading(fileNameSpd,fileNameSpdExt)
        
    % i)first priority to find speed measurement data(excel file) is using file name with 'Position - modified by Ilseob.*' 
    fileNameSpdExtWC = ['*',fileNameSpd,'*',fileNameSpdExt,'*'];
    fileList = dir(fileNameSpdExtWC);
    if ~isempty(fileList)
        loadedDataSpeed = table2array(readtable(fileList.name,'ReadVariableNames',false)); % xlsread(fileList.name);
        loadedDataSpeed = loadedDataSpeed(:,1:4);       % 1st column: time, 2nd col: x position, 3rd col: corridor flag, 4th col: trigger
    else
    % if condition i) is not true,    
    % ii)second priority to find speed measurement data(excel file) is using file name with 'Position.*'
        fileNameSpdWC = ['*',fileNameSpd,'*'];
        fileList = dir(fileNameSpdWC);
        if ~isempty(fileList)
            loadedDataSpeed = xlsread(fileList.name);
            loadedDataSpeed = loadedDataSpeed(:,1:4);       % 1st column: time, 2nd col: x position, 3rd col: corridor flag, 4th col: trigger
        else
            msg = [dirName,'- Speed measurement file not found'];
            errordlg(msg,'File Error');    
        end
    end


function [loadedDataFluor,loadedDataSpk] = Flour_Spk_file_loading(fileNameFluo,fileNameSpk,cells)
% import data of fluorescence & spike-train data
% Fluorescence Data Structure(*.mat file)
% 1-5th column: (meaningless) background ROIs, 6/8/10/12/..th col: fluorescence data of each ROIs 

% fileNameFluo usually has name of 'miceID-day-normalized dF-by-F data.mat'
% fileNameSpk has 'miceID-day-spike train normalized dF-by-F data.mat'
% both variable has characters of 'normalized dF-by-F'
fileNameFluoWC = ['*',fileNameFluo,'*'];
fileList = dir(fileNameFluoWC);
if ~isempty(fileList)
    for fileIter = 1:1:size(fileList,1)
        if isempty(strfind(fileList(fileIter).name,fileNameSpk))         % if fileList element does not have keyword 'spike', it is fluorescence data
           loadedMAT_tmp = matfile(fileList(fileIter).name);
           matName_tmp = whos(loadedMAT_tmp);
           loadedData_tmp = loadedMAT_tmp.(matName_tmp.name);
           loadedDataFluor = loadedData_tmp(cells,:);
           for cellIter = 1:1:size(loadedDataFluor,1)
               loadedDataFluor(cellIter,:) = min_max_scaling(loadedDataFluor(cellIter,:));
           end
           loadedDataFluor(isnan(loadedDataFluor)) = 0;

        else                                                    % if fileList element have keyword 'spike', it is spike train data
           fileNameFluoWC = '*were detected*';
           fileList = dir(fileNameFluoWC); 
           if ~isempty(fileList)
              loadedMAT_tmp = matfile(fileList.name);
              matName_tmp = whos(loadedMAT_tmp);
              loadedData_tmp = loadedMAT_tmp.('S2'); 
              loadedDataSpk = loadedData_tmp(cells,:);
              for cellIter = 1:1:size(loadedDataSpk,1)
                  loadedDataSpk(cellIter,:) = min_max_scaling(loadedDataSpk(cellIter,:));
              end
              loadedDataSpk(isnan(loadedDataSpk)) = 0;
           else
               error('spike data is not found')
           end
        end
    end
    
end

