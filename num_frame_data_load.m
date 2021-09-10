function [num_frame_data,param,animal,day] = num_frame_data_load(session_fullPath,param)

% navigate a data which contains number of frame in all animal in all day
% which consists of *.mat file
% I manually made this data; it might possibly made automatically using
% header of *.raw data, however I do not know how to do in MATLAB.
% I opened individual *.raw data in Fiji with virtual stack, and recorded
% number of frame in an excel sheet, and then, pasted the data into a *.mat
% file.
% e.g.) num_frame_allAnimal_allDay: 6-by-1 (Animal1/4/6/7/10/17)

% e.g.) num_frame_allAnimal_allDay{1,1}: 
% 'Animal1','# of frame',[],[]
% 'Day',        'part1', 'part2', 'part3'
%  1,           90000,   [],      []
%  2,           122630,  [],      []
%  .....................................
% '1week',      24973,   23202,   []
% 'distractor', 25259,   23861,   []
% 'combined',   25411,   21596,   []
% '6weeks',     27536,   28657,   []

%% load data

    if ~isfield(param,'dtCell_num_frame_data')
        [FileName,PathName] = uigetfile('*.mat','Select the num_frame_allAnimal_allDay.mat');
        fullPath = [PathName,FileName];
        data_temp = load(fullPath);
        data_temp = data_temp.num_frame_allAnimal_allDay;

        animalList = {'Animal1','Animal 1';'Animal4','Animal 4';'Animal6','Animal 6';...
                      'Animal7','Animal 7';'Animal10','Animal 10';'Animal17','Animal 17'};
        dtCell_num_frame_data = [animalList, data_temp];
        param.dtCell_num_frame_data = dtCell_num_frame_data;
    else
        dtCell_num_frame_data = param.dtCell_num_frame_data;
    end
    
%% separate loaded data by Animal ID and Day#

% I HATE THIS CODE!!!!!!! Develop program more systematically 

    day = {};
    session_fullPath_split = strsplit(session_fullPath,{'\','/','-','_'},'CollapseDelimiters',true);
    for ii = 1:1:length(session_fullPath_split)
        if contains(session_fullPath_split{ii},'day','IgnoreCase',true) | contains(session_fullPath_split{ii},'week','IgnoreCase',true) | ...
           contains(session_fullPath_split{ii},'dist','IgnoreCase',true)| contains(session_fullPath_split{ii},'comb','IgnoreCase',true)
            day = [day; session_fullPath_split{ii}];
        end
        if contains(session_fullPath_split{ii},'anim','IgnoreCase',true)
            animal = session_fullPath_split{ii};
        end
    end
    if size(day,1) > 1          % merging multiple strings into a string
        temp = {};
        for ii = 1:1:size(day,1)-1
            temp = [temp, [day{ii,1},' ',day{ii+1}]];
        end
        day = temp;
    end
    
    % animal index
    animal_idx = 0;
    for rowIter = 1:1:size(dtCell_num_frame_data,1)     
        if contains(dtCell_num_frame_data{rowIter,1},animal,'IgnoreCase',true) | ...
                contains(dtCell_num_frame_data{rowIter,2},animal,'IgnoreCase',true)
           animal_idx = rowIter; 
           break
        end
    end
    if isequal(animal_idx,0)
        error('Animal data is not found in num_frame_data_load()')
    end
    
    % day index
    if contains(day{1,1},'day','IgnoreCase',true)   % Day1-10
        day_num = numeric_in_string(day{1,1});
    end
   
    % tricky path to recognize day
    % e.g.) '/media/choii/SSD/PhenoSys DATA/Animal 1/Animal 1-1 week after relearning/SessionLog-19.05.28-Animal 1-Day18-IS modified.xlsx'
    % this one has keywords both of 'day' and 'week', therefore, if-condition works twice
    if contains(day{1,1},'dist','IgnoreCase',true) | contains(day{1,1},'comb','IgnoreCase',true)
        if contains(day{1,1},'week','IgnoreCase',true)          % Nweek-distractor or Nweek-combined
            week_num = numeric_in_string(day{1,1});
            if isequal(week_num,1)
                day_num = 18;
            elseif isequal(week_num,6)
                day_num = 53;
            end
        else                                                    % 1week-distractor or 1week-combined
            day_num = 18;
        end
        if contains(day{1,1},'dist','IgnoreCase',true)
            day_num = day_num + 1;
        elseif contains(day{1,1},'comb','IgnoreCase',true)
            day_num = day_num + 2;
        end
    
    elseif contains(day{1,1},'week','IgnoreCase',true)      % Nweek
        week_num = numeric_in_string(day{1,1});
        if isequal(week_num,1)
            day_num = 18;
        elseif isequal(week_num,6)
            day_num = 53;
        end
    end
    day_idx = day_indexing(day_num);
    
    % return data - number of frame in the specific animal# in the specific day#
    num_frame_data = dtCell_num_frame_data{animal_idx,3}(day_idx,2:end);
    animal = dtCell_num_frame_data{animal_idx,1};
    day = dtCell_num_frame_data{animal_idx,3}{day_idx,1};
    
end

function [day_idx] = day_indexing(day_num)

    switch day_num
        case 1
            day_idx = 3;
        case 2
            day_idx = 4;
        case 3
            day_idx = 5;
        case 4
            day_idx = 6;
        case 5
            day_idx = 7;
        case 7
            day_idx = 8;
        case 8
            day_idx = 9;
        case 9
            day_idx = 10;
        case 10
            day_idx = 11;
        case 18
            day_idx = 12;
        case 19
            day_idx = 13;
        case 20
            day_idx = 14;
        case 53
            day_idx = 15;
        case 54
            day_idx = 16;
        case 55
            day_idx = 17;
    end

end