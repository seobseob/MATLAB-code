function [dtCell_subfolder_list] = recurse_subfolders(param)

    % reference
    % https://www.mathworks.com/matlabcentral/answers/112746-opening-a-directory-of-folders-and-accessing-data-within-each-folder

    param
    param.searchingFile_list;
    param.subFolder_excludeFile_list;
    isfield(param,'subFolder_excludeFolder_list')
    
%% variable initialization

    % subfolder has to include user-determined file list
    % eg.) param.searchingFile_list = {'*Animal*Day*.csv', 'SessionLog*Animal*.xlsx'};
    searchingFile_list = param.searchingFile_list;
    
    % store subfolder list which includes user-determined file list
    % 1st col: full file path with the 1st file, 2nd: 2nd file
    dtCell_subfolder_list = {};
    dtCell_idx = 1;
    
    % file list of excluding in sub folder navigation function, e.g.) {'30min'}
    exclFile_list = param.subFolder_excludeFile_list;

%% parsing sub folders

    % Define a starting folder.
    % Ask user to confirm or change.
    topLevelFolder = uigetdir();
    if topLevelFolder == 0
        return;
    end

    % Get list of all subfolders.
    allSubFolders = genpath(topLevelFolder);    % long, single line string
    % Parse into a cell array.
    if isunix
        C_scan = textscan(allSubFolders,'%q','Delimiter',':');   % in Linux Delimiter is ':', in Windows would be ';' 
    elseif ispc
        C_scan = textscan(allSubFolders,'%q','Delimiter',';');   % in Linux Delimiter is ':', in Windows would be ';' 
    end
    listOfFolderNames = C_scan{1,1};
    numberOfFolders = length(listOfFolderNames);

    % exclude folder by user-determined if there is any
    if isfield(param,'subFolder_excludeFolder_list')
        subFolder_excludeFolder_list = param.subFolder_excludeFolder_list;
        include_folder_idx = [];
        for dirIter = 1:1:numberOfFolders
           thisFolder = listOfFolderNames{dirIter};
           if isempty(find(strfind(thisFolder,subFolder_excludeFolder_list)))
               include_folder_idx = [include_folder_idx; dirIter];
           end
        end
        listOfFolderNames = listOfFolderNames(include_folder_idx,1);
        numberOfFolders = size(listOfFolderNames,1);
    end

%% gathering subfolders which includes user-determined file

    % searchingFile_list:
    % eg.) {'*Animal*Day*.csv', 'SessionLog*Animal*.xlsx'}

    % Process all image files in those folders.
    for dirIter = 1:1:numberOfFolders
        % Get this folder and print it out.
        thisFolder = listOfFolderNames{dirIter};
%         fprintf('Processing folder %s\n', thisFolder);

        for fileIter = 1:1:length(searchingFile_list)
           filePattern = sprintf('%s/%s', thisFolder,searchingFile_list{fileIter});
           baseFileNames = dir(filePattern);
           if isempty(baseFileNames)
               break
           else
               if size(baseFileNames,1) > 1     % excluding condition
                   % file list of excluding in sub folder navigation function
                   % eg.) {'30min'}
                   for ii = 1:1:size(baseFileNames,1) 
                      if ~isempty(strfind(baseFileNames(ii).name,exclFile_list{1}))
                          baseFileNames(ii) = [];     % exclude elements
                          break
                      end
                   end
               end
               
               dtCell_subfolder_list{dtCell_idx,fileIter} = ...
                                [baseFileNames.folder,'/',baseFileNames.name];
               if isequal(fileIter,2)
                   dtCell_idx = dtCell_idx + 1;
               end
           end
        end
        
    end

end