function [dtCell_animal_day_idx] = subfolder_list_indexing_func(param,dtCell_subfolder_list,animalIter)

    % this var. records index of animal ID (only for one animal) & day in dtCell_subfolder_list;
    % 1st col: index of corresponding animal ID in the dtCell_subfolder_list, 
    % 2nd: index of day, 3rd+4th: path of behavior data and system log respectively
    dtCell_animal_day_idx = cell(length(param.dayList),4);
    
    for foldIter = 1:1:size(dtCell_subfolder_list,1)
        animalID_found_flag = 0; dayNum_found_flag = 0;
        
        % to avoid accessing Animal 1 & Animal 10, split path into
        % several pieces using multiple demiters - '/','-','_'. 
        % and then, compare animalList to each pieces.
        % strsplit() is required to this work
        subfold_split = strsplit(dtCell_subfolder_list{foldIter,1},{'\','/','-','_'},'CollapseDelimiters',true);
        
        % important!! do for-loop(outer) in animal ID & day number in each first, and then, 
        % for-loop(inner) in splited string of subfolder
        % e.g.) target = {'/media/choii/SSD/PhenoSys DATA/Animal 1/Animal 1-6weeks-combined/19.07.05_Animal 1.csv'}
        % after strsplit(), the result{...,'Animal 1','6weeks','combined','19.07.05','Animal 1.csv'}.
        % if do for-loop in splited string of subfolder then day number, day number searching function might wrongly 
        % found '6weeks' and finished its process, 'combined' would not be detected
        
        % find animal
        % animal ID must be compared 
        % param.animalList:
        % e.g.) animalList{1} = {'Animal 1';'Animal1'}, 
        %       animalList{2} = {'Animal 2';'Animal2'}
        strPattern1 = param.animalList{animalIter}{1,1};
        strPattern2 = param.animalList{animalIter}{2,1};
        animalID_found_flag = animalID_searching_sub_func(subfold_split,strPattern1,strPattern2);
                
        % find day
        % param.dayList:
        % dayList{1} = {'Day1'; 'Day 1'}; dayList{2} = {'Day2'; 'Day 2'}; ...
        % dayList{12} = {'1week'; '1 week'; 'distractor'}
        if animalID_found_flag == 1
            [dayIter,dayNum_found_flag] = dayNum_searchinig_sub_func(subfold_split,dtCell_subfolder_list{foldIter,1},param);
        end
        
        % we found essential information of animal ID and day number, and
        % organize a data table in dtCell_animal_day_idx
        if animalID_found_flag & dayNum_found_flag
           dtCell_animal_day_idx{dayIter,1} = param.animalList{animalIter}{1,1};
           if size(param.dayList{dayIter},1) > 2
               dtCell_animal_day_idx{dayIter,2} = [param.dayList{dayIter}{1,1},'-',param.dayList{dayIter}{end,1}]; 
           else
               dtCell_animal_day_idx{dayIter,2} = param.dayList{dayIter}{1,1}; 
           end
           dtCell_animal_day_idx{dayIter,3} = dtCell_subfolder_list{foldIter,1};
           dtCell_animal_day_idx{dayIter,4} = dtCell_subfolder_list{foldIter,2};
        end
           
         
        
    end
    
end

function [animalID_found_flag] = animalID_searching_sub_func(subfold_split,strPattern1,strPattern2)

    animalID_found_flag = 0;
    for splitIter = 1:1:length(subfold_split)
        % e.g.) foldIter = 1; 
        % dtCell_subfolder_list{foldIter,1} = {'/media/choii/SSD/PhenoSys DATA/Animal 1/Animal 1-1 week after relearning/19.05.28_Animal 1-Day18.csv'}
        % subfold_split = {'','media','choii','SSD','PhenoSys DATA','Animal 1','Animal 1','1 week after relearning','19.05.28','Animal 1','Day18.csv'}
        if strcmpi(subfold_split{splitIter},strPattern1) | strcmpi(subfold_split{splitIter},strPattern2)
            animalID_found_flag = 1;
            break
        end
    end 
    
end

function [dayIter,dayNum_found_flag] = dayNum_searchinig_sub_func(subfold_split,subfold,param)

    % it is possible to separate two groups of day:
    % i) Day1-10 are normal series of day, however,
    % ii) the rest is '1week' after with 'distractor' & 'combined pattern',
    % and '6weeks' after with 'distractor' & 'combined pattern'
    
    % param.dayList:
    % dayList{1} = {'Day0'; 'Day 0'}; dayList{2} = {'Day1'; 'Day 1'}; ...
    % dayList{13} = {'1week'; '1 week'; 'distractor'}  
        
    for dayIter = 1:1:length(param.dayList)    
        dayNum_strPattern1 = param.dayList{dayIter}{1,1};   % e.g.) 'Day1' or 'Day 1'
        dayNum_strPattern2 = param.dayList{dayIter}{2,1};   %       '1week' or '1 week'
        if size(param.dayList{dayIter},1) > 2
            dayNum_strPattern3 = param.dayList{dayIter}{3,1};   % e.g.) 'distractor' or 'combined'
        end
        
        if contains(dayNum_strPattern1,'day','IgnoreCase',true)    % 'Day0'-'Day11'
            % e.g.) foldIter = 1; 
            % dtCell_subfolder_list{foldIter,1} = {'/media/choii/SSD/PhenoSys DATA/Animal 1/Animal 1-1 week after relearning/19.05.28_Animal 1-Day18.csv'}
            % subfold_split = {'','media','choii','SSD','PhenoSys DATA','Animal 1','Animal 1','1 week after relearning','19.05.28','Animal 1','Day18.csv'}
            day_check = {};
            for splitIter = 1:1:length(subfold_split)
                if strcmpi(subfold_split{splitIter},dayNum_strPattern1) | strcmpi(subfold_split{splitIter},dayNum_strPattern2)
                    day_check{1,1} = dayNum_strPattern1;
                    dayNum_found_flag = 1;
                    break
                end
            end

        else   % '1week'/'6weeks' + 'distractor'/'combined = '1week','1week-distractor','1week-combined', so on
            day_check = {};
            if size(param.dayList{dayIter},1) == 2
                if contains(subfold,dayNum_strPattern1) | contains(subfold,dayNum_strPattern2)
                    day_check{1,1} = dayNum_strPattern1;
                    dayNum_found_flag = 1;
                    break
                end
            elseif size(param.dayList{dayIter},1) > 2
                if (contains(subfold,dayNum_strPattern1)|contains(subfold,dayNum_strPattern2)) & contains(subfold,dayNum_strPattern3)
                    day_check{1,1} = dayNum_strPattern1;
                    day_check{2,1} = dayNum_strPattern3;
                    dayNum_found_flag = 1;
                    break
                elseif contains(subfold,dayNum_strPattern3) & ~(contains(subfold,'6 week')|contains(subfold,'6week'))
                    % in case of '1week-distraor' or '1week-combined'
                    % '1week' was sometimes not included
                    day_check{1,1} = dayNum_strPattern1;
                    day_check{2,1} = dayNum_strPattern3;
                    dayNum_found_flag = 1;
                    break
                end
                
            end
        end          
        
        if ~isempty(day_check)
            dayNum_found_flag = 1;
            break
        end
    end
    
    
end