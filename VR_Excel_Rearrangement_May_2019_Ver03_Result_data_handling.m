function VR_Excel_Rearrangement_May_2019_Ver03_Result_data_handling(lick_count_data,FAD_grp,WT_grp,save_flag)

% we assume that we have result data table after running 
% 'VR_Excel_Rearrangement_May_2019_Ver03.m', and
% the result data table is named 'dtCell_batch_lick_count' with cell type
% variable

% e.g.)
% lick_count_data = dtCell_batch_count_allAnimal_allDay;
% FAD_grp = {'Animal1','Animal4','Animal7','Animal10'};
% WT_grp = {'Animal2','Animal3','Animal6','Animal16','Animal17'};
% save_flag = 0;    % 1: save bar graphs in disk, 0: not save
% VR_Excel_Rearrangement_May_2019_Ver03_Result_data_handling(lick_count_data,FAD_grp,WT_grp,save_flag);

%%

dtCell_batch_lick_count = lick_count_data;

% if it is required, rearrange 'lick count by time' column in dtCell_batch_lick_count var.
lick_count_time = 0:0.5:2.5; %0:0.5:5;
for ii = 2:1:size(dtCell_batch_lick_count,1)
   for ctxtIter = 1:1:3
       if ~isnan(dtCell_batch_lick_count{ii,ctxtIter+5})
           time_data = dtCell_batch_lick_count{ii,ctxtIter+5};
           if size(time_data,2) ~= length(lick_count_time)
               % reference vector
               lick_count_time = 0:0.5:5;
               lick_count_time(2,:) = zeros(1,length(lick_count_time));
               % rearrange time_data by reference vector
               lick_count_time(2,1:size(time_data,2)) = time_data(2,:);
               dtCell_batch_lick_count{ii,ctxtIter+5} = lick_count_time;
           end
       end
   end
end

%%  data rearrangement

%FAD_grp = {'Animal1','Animal4','Animal7','Animal10'};
%WT_grp = {'Animal2','Animal3','Animal6','Animal16','Animal17'};
Day = {'Day2','Day3','Day4','Day5','Day7','Day8','Day9','Day10',...
       '1 week-distractor','1 week-combined','1 week',...
       '6 week-distractor','6 week-combined','6 week'};

dtCell_batch_lick_total_sum_result = {'Phenotype','Day','lick count position in C1',...
        'lick count position in C2','lick count position in C3',...
        'lick count time in C1','lick count time in C2','lick count time in C3'};
dtCell_idx = 1;

for phenoIter = 1:1:2
    switch phenoIter
        case 1  
            pheno = FAD_grp;
            dtCell_batch_lick_total_sum_result{dtCell_idx+1,1} = '5xFAD';
        case 2  
            pheno = WT_grp;
            dtCell_batch_lick_total_sum_result{dtCell_idx+1,1} = 'Wild type';
    end
        
    for dayIter = 1:1:length(Day)    
        dtCell_batch_lick_total_sum_result{dtCell_idx+1,2} = Day{dayIter};
        
        for ctxtIter = 1:1:3
            dtMat_lick_count_pos = 500:100:2700; %0:100:2700;
            dtMat_lick_count_time = 0:0.5:2.5;
            
            for grpIter = 1:1:3
                idx = find(strcmp(dtCell_batch_lick_count(2:end,1),pheno{grpIter}) & ...
                            strcmp(dtCell_batch_lick_count(2:end,2),Day{dayIter}));
                if ~isempty(idx)
                    lick_count_pos = dtCell_batch_lick_count{idx+1,ctxtIter+2};
                    lick_count_time = dtCell_batch_lick_count{idx+1,ctxtIter+5};
                    if ~isnan(lick_count_pos)
                        dtMat_lick_count_pos = [dtMat_lick_count_pos; sum(lick_count_pos(2:end,:),1)];
                    end

                    if ~isnan(lick_count_time)
                        dtMat_lick_count_time = [dtMat_lick_count_time; sum(lick_count_time(2:end,:),1)];
                    end
                end
            end
            
            if size(dtMat_lick_count_pos,1) > 1
                dtCell_batch_lick_total_sum_result{dtCell_idx+1,ctxtIter+2} = ...
                    [dtMat_lick_count_pos(1,:); sum(dtMat_lick_count_pos(2:end,:),1)];
            else
                dtCell_batch_lick_total_sum_result{dtCell_idx+1,ctxtIter+2} = NaN;
            end
            if size(dtMat_lick_count_time,1) > 1
                dtCell_batch_lick_total_sum_result{dtCell_idx+1,ctxtIter+5} = ...
                    [dtMat_lick_count_time(1,:); sum(dtMat_lick_count_time(2:end,:),1)];
            else
                dtCell_batch_lick_total_sum_result{dtCell_idx+1,ctxtIter+5} = NaN;
            end
            
        end
        dtCell_idx = dtCell_idx + 1;
        
    end
end

%% plot the rearranged data

for dtCell_idx = 1:1:size(dtCell_batch_lick_total_sum_result,1)
    if ~isempty(dtCell_batch_lick_total_sum_result{dtCell_idx,1})
        pheno = dtCell_batch_lick_total_sum_result{dtCell_idx,1};
    end
    
    if ~isempty(dtCell_batch_lick_total_sum_result{dtCell_idx,2})
        day = dtCell_batch_lick_total_sum_result{dtCell_idx,2};
    end
    
    for ctxtIter = 3:1:5
        pos_data = dtCell_batch_lick_total_sum_result{dtCell_idx,ctxtIter};
        time_data = dtCell_batch_lick_total_sum_result{dtCell_idx,ctxtIter+3};
        
        if isnan(pos_data)
           pos_data = [500:100:2700; zeros(1,length(500:100:2700))];
        end
        if isnan(time_data)
           time_data = [0:0.5:2.5; zeros(1,length(0:0.5:2.5))];
        end
        
        plot_data = [pos_data, time_data];  % mix position and time data
        xticklabels_vec = {'50','100','150','200','250cm','0','1','2','3'}; %,'4','5sec'};
        
        f = figure;
        bar(plot_data(2,:),0.8)
        xticks([1 6 11 16 21 24 26 28 30]);
        xticklabels(xticklabels_vec);
        ylim([0 400]); xlim([0 size(plot_data,2)+2]);
        txt = [pheno,'-',day,'-context',num2str(ctxtIter-2)];
        title(txt)
    
        if save_flag
            saveas(gcf,txt,'jpeg')
        end
        close(f)
    end
end
