function [lick_count_data,lick_count_mean,lick_count_sem] = licking_count_organization(dtCell_lick_count_each_animal_data,animal_grp,varargin)

% e.g.)
% lick_count_data = dtCell_batch_lick_count_allAnimal_allDay;
% FAD_grp = {'Animal1','Animal4','Animal7','Animal10'};
% WT_grp = {'Animal2','Animal3','Animal6','Animal16','Animal17'};
% anti_range = [2600, 2700];
% [lick_count_dataTable,lick_count_mean,lick_count_sem] = licking_count_organization(lick_count_data,FAD_grp,anti_range)

%% variable initialization

if ~isempty(varargin{1})
    anti_range = varargin{1};       % set anticipation area by user
end

if ~exist('anti_range','var')
    lick_count_data = {'Animal','Day','lick count in Context1 < BlackStart','lick count in Context2','lick count in Context3',...
                       'lick count in Context1 > BlackStart','lick count in Context2','lick count in Context3'};
else
    lick_count_data = {'Animal','Day','lick count in anticipation area','lick count in Context2','lick count in Context3',...
                       'lick count in Context1 > BlackStart','lick count in Context2','lick count in Context3'};
end

Day = {'Day2','Day3','Day4','Day5','Day7','Day8','Day9','Day10',...
       '1 week-distractor','1 week-combined','1 week',...
       '6 week-distractor','6 week-combined','6 week'};

lick_count_mean = lick_count_data;
lick_count_sem = lick_count_data;   
   
%FAD_grp = {'Animal1','Animal4','Animal7','Animal10'};
%WT_grp = {'Animal2','Animal3','Animal6','Animal16','Animal17'};   

ctxt_num = 3;
day_col = 2; animal_col = 1; pos_data_col = 3; time_data_col = pos_data_col+ctxt_num;
cell_idx = size(lick_count_data,1)+1;

%% data handling

for dayIter = 1:1:length(Day)  % number of day
    
    day_idx = strcmpi(dtCell_lick_count_each_animal_data(:,day_col),Day{dayIter});
    
    for animalIter = 1:1:length(animal_grp)  % number of animal
        animal_idx = strcmpi(dtCell_lick_count_each_animal_data(:,animal_col),animal_grp{animalIter});
        common_idx = animal_idx & day_idx;
        
        for ctxtIter = 1:1:ctxt_num          
            animal_data = dtCell_lick_count_each_animal_data{common_idx,ctxtIter+2};
            
            if ~isempty(animal_data)
                if ~exist('anti_range','var')       % anticipation area is not designated
                    pos_animal_data = animal_data(2:end,:);
                else                                % anticipation area is designated
                    pos_bin_range = animal_data(1,:);             % 1st row: position bin (500 - 2700mm)
                    pos_bin_idx = [find(pos_bin_range == anti_range(1)), find(pos_bin_range == anti_range(2))]; % column number where anticipation range(2600-2700mm)  
                    pos_animal_data = animal_data(2:end,pos_bin_idx(1):pos_bin_idx(2));
                end
                
                % two measurement: 
                % i) licking count based on position bin(50-270cm before 'BlackStart')
                if isequal(size(pos_animal_data,1),1)
                    pos_count_len = length(find(~isnan(pos_animal_data)));
                    pos_avg_count = sum(pos_animal_data,2,'omitnan') / pos_count_len; 
                else
                    pos_avg_count = mean(sum(pos_animal_data,2,'omitnan'),1,'omitnan');      
                end
                lick_count_data{cell_idx,ctxtIter+(pos_data_col-1)} = pos_avg_count;
            else
                lick_count_data{cell_idx,ctxtIter+(pos_data_col-1)} = NaN;
            end
                
            time_animal_data = dtCell_lick_count_each_animal_data{common_idx,ctxtIter+5}(2:end,:);
            if ~isempty(time_animal_data)
                % ii) licking count based on time bin(after 'BlackStart')
                if isequal(size(time_animal_data,1),1)
                    time_count_len = length(find(~isnan(time_animal_data)));
                    time_avg_count = sum(time_animal_data,2,'omitnan') / time_count_len;
                else
                    time_avg_count = mean(sum(time_animal_data,2,'omitnan'),1,'omitnan');
                end              
                lick_count_data{cell_idx,ctxtIter+(time_data_col-1)} = time_avg_count;
            else
                lick_count_data{cell_idx,ctxtIter+(time_data_col-1)} = NaN;
            end
        end
        
        lick_count_data{cell_idx,day_col} = Day{dayIter};
        lick_count_data{cell_idx,animal_col} = animal_grp{animalIter};
        cell_idx = cell_idx + 1;
    end
    
end


for dayIter = 1:1:length(Day)  % number of day
    day_idx = strcmpi(lick_count_data(:,day_col),Day{dayIter});
    lick_count_mean{dayIter+1,day_col} = Day{dayIter};
    lick_count_sem{dayIter+1,day_col} = Day{dayIter};
    
    for ctxtIter = 1:1:3
        % lickcing count based on position bin(50-270cm before 'BlackStart') in all animals in the same day
        pos_count = cell2mat(lick_count_data(day_idx,ctxtIter+(pos_data_col-1)));
        % lickcing count based on time bin(after 'BlackStart') in all animals in the same day
        time_count = cell2mat(lick_count_data(day_idx,ctxtIter+(time_data_col-1)));
        
        % averaging licking count in all animals in the same day
        pos_avg_count = mean(pos_count,1,'omitnan');
        time_avg_count = mean(time_count,1,'omitnan');
        lick_count_mean{dayIter+1,ctxtIter+(pos_data_col-1)} = pos_avg_count;
        lick_count_mean{dayIter+1,ctxtIter+(time_data_col-1)} = time_avg_count;
        
        % length of licking count in all animals in the same day, excluding NaN element
        pos_count_len = length(find(~isnan(pos_count)));
        time_count_len = length(find(~isnan(time_count)));
        
        % standard error of the mean in all animals in the same day
        pos_sem_count = std(pos_count,1,'omitnan') / sqrt(pos_count_len);
        time_sem_count = std(time_count,1','omitnan') / sqrt(time_count_len);
        lick_count_sem{dayIter+1,ctxtIter+(pos_data_col-1)} = pos_sem_count;
        lick_count_sem{dayIter+1,ctxtIter+(time_data_col-1)} = time_sem_count;
    end
end

