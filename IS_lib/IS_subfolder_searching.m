function [dtCell_subfolder_list] = IS_subfolder_searching(varargin)

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
%
% reference:
% https://www.mathworks.com/matlabcentral/answers/112746-opening-a-directory-of-folders-and-accessing-data-within-each-folder

   
%% variable initialization

    % searchFile: sub-folder has to include user-determined file list
    % exclude_dirStr: file list of excluding in sub folder navigation function, e.g.) {'30min'}
    %
    % e.g.) searchFile = {'*Animal*Day*.csv', 'SessionLog*Animal*.xlsx'} 
    %    => searchFile_regExp = {'Animal?(\Day)?(\.csv)?', 'SessionLog?(\Animal)?(\.xlsx)?'}
    % Or
    % e.g.) searchFile_regExp = {'^Fall(\.mat)?'};    % 'Fall.mat' and 'Fall_IS cell selected.mat'
    
    if isempty(varargin)
        errordlg('input parameter is not enough')
    elseif ~isempty(varargin)
        searchFileName_regexp = varargin{1};
        
        % store subfolder list which includes user-determined file list
        % 1st col: full file path with the 1st file, 2nd: 2nd file
        dtCell_subfolder_list = {};
        dtCell_idx = 1;
    
        % [OPTION]
        if length(varargin)==2              % exclude file if multiple file were found in a folder
            exclFileName_multiCase = varargin{2};
        
        elseif length(varargin)==3          % exclude all file which get set by user
            exclFileName_multiCase = varargin{2};
            exclFileName_allCase = varargin{3};
        
        elseif length(varargin)==4          % exclude all sub-folder which get set by user
            exclFileName_multiCase = varargin{2};
            exclFileName_allCase = varargin{3};
            exclSubFolderName = varargin{4};
        end
    end

%% parsing sub folders - see reference code in this section

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
        delim_str = textscan(allSubFolders,'%q','Delimiter',':');   % in Linux Delimiter is ':', in Windows would be ';' 
    elseif ispc
        delim_str = textscan(allSubFolders,'%q','Delimiter',';');   % in Linux Delimiter is ':', in Windows would be ';' 
    end
    dtCell_folderName = delim_str{1,1};                             % only folder name is shown  
    num_folderName = length(dtCell_folderName);

%     % exclude folder by user-determined if there is any
%     if length(varargin)==2 & exclude_flag==1
%         subFolderName = exclFile_multiCase;
%         include_folder_idx = [];
%         for dirIter = 1:1:num_folderName
%            subFolderName = dtCell_folderName{dirIter};
%            if isempty(find(strfind(subFolderName,subFolderName)))
%                include_folder_idx = [include_folder_idx; dirIter];
%            end
%         end
%         dtCell_folderName = dtCell_folderName(include_folder_idx,1);
%         num_folderName = size(dtCell_folderName,1);
%     end

    % [OPTION] exclude folder by user-determined if there is any
    % open sub-folder name each, and check its name whether will get
    % excluded or not. 
    % only index of passed sub-folder name is stored in the 'folder_idx'. And
    % using this infomation, we can build up essential sub-folder name list
    if exist('exclSubFolderName','var')           % exclude all sub-folder which get set by user
        folder_idx = [];                    % this var. stores index of sub-folder name
        for dirIter = 1:1:num_folderName    % open sub-folder name each, one-by-one
           subFolderName = dtCell_folderName{dirIter,1};
           % check opened sub-folder name whether it will get excluded or not
           if isempty(regexp(subFolderName,exclSubFolderName{1},'ONCE'))
               folder_idx = [folder_idx; dirIter]; 
           end
        end
        dtCell_folderName = dtCell_folderName(folder_idx,1);
        num_folderName = size(dtCell_folderName,1);   
    end
    
%% gathering subfolders which includes user-determined excluding file and/or folder

    % e.g.) searchFile = {'*Animal*Day*.csv', 'SessionLog*Animal*.xlsx'} 
    %    => searchFile_regExp = {'Animal?(\Day)?(\.csv)?', 'SessionLog?(\Animal)?(\.xlsx)?'}
    % Or
    % e.g.) searchFile_regExp = {'^Fall(\.mat)?'};    % 'Fall.mat' and 'Fall_IS cell selected.mat'

    % i) open sub-folder each one-by-one
    % ii) find file which satisfy user-determined name condition in the opened sub-folder
    % iii)[OPTION] if file found in step ii) has excluding condition user set in advance, then skip storing a file name 
    % iv) [OPTION] if there are multiple file in a sub-folder, check excluding file name condition that user set in advance
    % v) store a sub-folder name, where user finding file is placed, in a sub-folder list
    
    if exist('searchFileName_regexp','var')        % sub-folder name list where includes files users want to find
        % Process all image files in those folders.
        for dirIter = 1:1:num_folderName
            % step i)
            subFolderName = dtCell_folderName{dirIter};

%             for fileIter = 1:1:length(searchFileName_regexp)    % this allows multiple condition of search file name
%                if isunix()
%                    fileNamePattern = sprintf('%s/%s', subFolderName,searchFileName_regexp{fileIter});
%                elseif ispc()
%                    fileNamePattern = sprintf('%s\%s', subFolderName,searchFileName_regexp{fileIter});
%                end
%                baseFileNames = dir(fileNamePattern);
%                num_baseFileNames = size(baseFileNames,1);
% 
%                if isempty(baseFileNames)
%                    break
%                else
%                    % [OPTION]
%                    if exist('exclFileName_allCase','var')
%                        for ii = 1:1:num_baseFileNames
%                           if ~isempty(regexp(baseFileNames(ii).name,exclFileName_multiCase{1},'ONCE'))
%                               baseFileNames(ii) = [];           % exclude elements
%                           end
%                        end
%                    end
%                    
%                    % [OPTION] target file which has 'baseFileNames' exist more than one 
%                    % if user already set excluding file name condition in advance in this case, 
%                    % check all file name in a sub-folder whether will get excluded or not
%                    if num_baseFileNames > 1 & exist('exclFileName_multiCase','var')    % excluding condition
% %                        if exist('exclude_fileStr','var') == 0
% %                            errordlg('Excluding condition is not set. More than one target file were found, thus a excluding file list has to be set')
% %                        else    
% %                            % file list of excluding in sub folder navigation function
% %                            % eg.) {'30min'}
% %                            for ii = 1:1:size(baseFileNames,1) 
% %                               if ~isempty(strfind(baseFileNames(ii).name,exclFileName_multiCase{1}))
% %                                   baseFileNames(ii) = [];     % exclude elements
% %                                   break
% %                               end
% %                            end
% %                        end
%                        
%                        for ii = 1:1:num_baseFileNames
%                           if ~isempty(regexp(baseFileNames(ii).name,exclFileName_multiCase{1},'ONCE'))
%                               baseFileNames(ii) = [];           % exclude elements
%                           end
%                        end
%                    end
%                     
%                    for file_multicase_iter = 1:1:num_baseFileNames
%                        if isunix()
%                            dtCell_subfolder_list{dtCell_idx,fileIter} = [baseFileNames(file_multicase_iter).folder,'/',baseFileNames(file_multicase_iter).name];
%                        elseif ispc()
%                            dtCell_subfolder_list{dtCell_idx,fileIter} = [baseFileNames(file_multicase_iter).folder,'\',baseFileNames(file_multicase_iter).name];
%                        end
% 
% %                        if isequal(fileIter,2)
%                            dtCell_idx = dtCell_idx + 1;
% %                        end
%                    
%                    end
                   
%                end
%             end


            baseFileNames = dir(subFolderName);             % baseFileNames is a struct type variable
            num_baseFileNames = size(baseFileNames,1);
            
            % get rid of directory element in 'baseFileNames'.
            element_idx = [];
            for struct_iter = 1:1:num_baseFileNames
                if baseFileNames(struct_iter).isdir == 0
                    element_idx = [element_idx; struct_iter];
                end
            end
            baseFileNames = baseFileNames(element_idx);     % baseFileNames has only file data; a struct type variable
                
            % it is possible 'baseFileNames' is empty             
            % handle only file data(= non-directory) below
            if ~isempty(baseFileNames)
                                     
                % step ii)
                % find file which satisfy user-determined naming condition in a sub-folder
                % 
                % name_condition_check(sub-folder list, regular expression, special case(1: step iv), 0: rest cases)
                if exist('searchFileName_regexp','var')
                    element_idx = name_condition_check(baseFileNames,searchFileName_regexp,0);
                    baseFileNames = baseFileNames(element_idx);
                end
                
                % it is possible 'baseFileNames' is empty if nothing
                % was found above step ii)     
                if ~isempty(baseFileNames)
                    % step iii)
                    % [OPTION] if user already set a excluding filename condition not to store, then delete index of struct element
                    % in the 'baseFileNames'
                    if exist('exclFileName_allCase','var')
                        element_idx = name_condition_check(baseFileNames,exclFileName_allCase,0);
                        baseFileNames(element_idx) = [];          % exclude elements
                    end
                    
                end
                
                % it is possible 'baseFileNames' is empty after excluding
                % filename condition checking above step iii)                   
                if ~isempty(baseFileNames)              
                    % step iv)
                    % [OPTION] target file which has 'baseFileNames' exist more than one 
                    % if user already set excluding file name condition in advance in this case, 
                    % check all file name in a sub-folder whether will get excluded or not
                    if exist('exclFileName_multiCase','var')
                        element_idx = name_condition_check(baseFileNames,exclFileName_multiCase,1);
                        baseFileNames(element_idx) = [];           % exclude elements
                    end
                end
                
                % it is possible 'baseFileNames' is empty after excluding
                % filename condition checking above step iv)                
                if ~isempty(baseFileNames)
                    num_baseFileNames = size(baseFileNames,1);
                    
                    % step v)
                    % store a sub-folder name in a sub-folder list
                    for struct_iter = 1:1:num_baseFileNames
                        dtCell_idx = size(dtCell_subfolder_list,1) + 1;
                        if isunix()
                            dtCell_subfolder_list{dtCell_idx,1} = [baseFileNames(struct_iter).folder,'/',baseFileNames(struct_iter).name];
                        elseif ispc()
                            dtCell_subfolder_list{dtCell_idx,1} = [baseFileNames(struct_iter).folder,'\',baseFileNames(struct_iter).name];
                        end
                    end
                end
                
            end

                   
        end
        
    else    % this function might returns only sub-folder name list
%         dtCell_subfolder_list = dtCell_folderName;
        errordlg('input parameter is not enough. filename to find is not designated.')
    end
end


function [element_idx] = name_condition_check(baseFileNames,cond_regEx,multiCase)
% This sub-function returns an element index vector which shows whether sub-folder
% name satisfy naming condition user-determined or not satisfy.
%
% INPUT: 
% i) sub-folder list: it is a struct type and it includes several fields but
% we need to access 'name' field only. 
% ii) regular expression: user has to set regular expression in advance to
% find file or exclude file and/or sub-folder name in user selected path.
% iii) flag of special case(1: step iv), 0: rest cases): in step iv), it
% assumed that multiple file were found in a sub-folder. And, if a user wants
% exclude file with specific naming condition user set, the code has to
% have 'if num_file > 1' paragraph. Therefore, this sort of flag is
% required.
%
% OUTPUT:
% a vector which has index in a sub-folder list is returned.
    
    element_idx = [];
    num_baseFileNames = size(baseFileNames,1);
    if isempty(cond_regEx)
        cond_regEx = '';
    else
        cond_regEx = cond_regEx{1};
    end
    
    % step iv)
    % [OPTION] target file which has 'baseFileNames' exist more than one 
    % if user already set excluding file name condition in advance in this case, 
    % check all file name in a sub-folder whether will get excluded or not
    if multiCase
        if num_baseFileNames > 1    % excluding condition
            for struct_iter = 1:1:num_baseFileNames
                if ~isempty(regexp(baseFileNames(struct_iter).name, cond_regEx,'ONCE'))
                    element_idx = [element_idx; struct_iter];
                end
            end
        end

    % the rest cases; step ii) & step iii)    
    else
        for struct_iter = 1:1:num_baseFileNames
            if ~isempty(regexp(baseFileNames(struct_iter).name, cond_regEx,'ONCE'))
                element_idx = [element_idx; struct_iter];
            end
        end
    end

end