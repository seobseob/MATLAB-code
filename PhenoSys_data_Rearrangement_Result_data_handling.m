% we assume that we have result data table after running 
% 'VR_Excel_Rearrangement_May_2019_Ver03.m', and
% the result data table is named 'dtCell_batch_leak_count' with cell type
% variable

%%
% if it is required, rearrange 'Leak count by time' column in dtCell_batch_leak_count var.
leak_count_time = 0:0.5:5;
for ii = 2:1:size(dtCell_batch_leak_count,1)
   for ctxtIter = 1:1:3
       if ~isnan(dtCell_batch_leak_count{ii,ctxtIter+5})
           time_data = dtCell_batch_leak_count{ii,ctxtIter+5};
           if size(time_data,2) ~= length(leak_count_time)
               % reference vector
               leak_count_time = 0:0.5:5;
               leak_count_time(2,:) = zeros(1,length(leak_count_time));
               % rearrange time_data by reference vector
               leak_count_time(2,1:size(time_data,2)) = time_data(2,:);
               dtCell_batch_leak_count{ii,ctxtIter+5} = leak_count_time;
           end
       end
   end
end

%%  data rearrangement

FAD_grp = {'Animal 1','Animal 4','Animal 7','Animal 10'};
WT_grp = {'Animal 2','Animal 3','Animal 6','Animal 16','Animal 17'};
Day = {'Day2','Day3','Day4','Day5','Day7','Day8','Day9','Day10','Day18','Day19','Day20'};
%Day = {'Day18','Day19','Day20'};

dtCell_batch_leak_total_sum_result = {'Phenotype','Day','Leak count position in C1',...
        'Leak count position in C2','Leak count position in C3',...
        'Leak count time in C1','Leak count time in C2','Leak count time in C3'};
dtCell_idx = 1;

for phenoIter = 1:1:2
    switch phenoIter
        case 1  
            pheno = FAD_grp;
            dtCell_batch_leak_total_sum_result{dtCell_idx+1,1} = '5xFAD';
        case 2  
            pheno = WT_grp;
            dtCell_batch_leak_total_sum_result{dtCell_idx+1,1} = 'Wild type';
    end
        
    for dayIter = 1:1:length(Day)    
        dtCell_batch_leak_total_sum_result{dtCell_idx+1,2} = Day{dayIter};
        
        for ctxtIter = 1:1:3
            dtMat_leak_count_pos = 500:100:2700;
            dtMat_leak_count_time = 0:0.5:5;
            
            for grpIter = 1:1:length(pheno)
                idx = find(strcmp(dtCell_batch_leak_count(2:end,1),pheno{grpIter}) & ...
                            strcmp(dtCell_batch_leak_count(2:end,2),Day{dayIter}));
                
                leak_count_pos = dtCell_batch_leak_count{idx+1,ctxtIter+2};
                leak_count_time = dtCell_batch_leak_count{idx+1,ctxtIter+5};
                if ~isnan(leak_count_pos)
                    dtMat_leak_count_pos = [dtMat_leak_count_pos; leak_count_pos(2:end,:)];
                end
                
                if ~isnan(leak_count_time)
                    dtMat_leak_count_time = [dtMat_leak_count_time; leak_count_time(2:end,:)];
                end
            end
            
            if size(dtMat_leak_count_pos,1) > 1
                dtCell_batch_leak_total_sum_result{dtCell_idx+1,ctxtIter+2} = ...
                    [dtMat_leak_count_pos(1,:); sum(dtMat_leak_count_pos(2:end,:),1)];
            else
                dtCell_batch_leak_total_sum_result{dtCell_idx+1,ctxtIter+2} = NaN;
            end
            if size(dtMat_leak_count_time,1) > 1
                dtCell_batch_leak_total_sum_result{dtCell_idx+1,ctxtIter+5} = ...
                    [dtMat_leak_count_time(1,:); sum(dtMat_leak_count_time(2:end,:),1)];
            else
                dtCell_batch_leak_total_sum_result{dtCell_idx+1,ctxtIter+5} = NaN;
            end
            
        end
        dtCell_idx = dtCell_idx + 1;
        
    end
end

%% plot the rearranged data

for dtCell_idx = 2:1:size(dtCell_batch_leak_total_sum_result,1)
    if ~isempty(dtCell_batch_leak_total_sum_result{dtCell_idx,1})
        pheno = dtCell_batch_leak_total_sum_result{dtCell_idx,1};
    end
    
    if ~isempty(dtCell_batch_leak_total_sum_result{dtCell_idx,2})
        day = dtCell_batch_leak_total_sum_result{dtCell_idx,2};
    end
    
    for ctxtIter = 3:1:5
        pos_data = dtCell_batch_leak_total_sum_result{dtCell_idx,ctxtIter};
        time_data = dtCell_batch_leak_total_sum_result{dtCell_idx,ctxtIter+3};
        
        if isnan(pos_data)
           pos_data = [0:100:2700; zeros(1,length(0:100:2700))];
        end
        if isnan(time_data)
           time_data = [0:0.5:5; zeros(1,length(0:0.5:5))];
        end
        
        plot_data = [pos_data, time_data];  % mix position and time data
        xticklabels_vec = {'50','100','150','200','250cm','0','1','2','3','4','5sec'};
        
        f = figure;
        bar(plot_data(2,:),0.8)
        xticks([1 6 11 16 21 24 26 28 30 32 34]); % xticks([0 6 11 16 21 26 29 31 33 35 37 39]);
        xticklabels(xticklabels_vec);
        ylim([0 200]); xlim([0 size(plot_data,2)]);
        txt = [pheno,'-',day,'-context',num2str(ctxtIter-2)];
        title(txt)
    
        saveas(gcf,txt,'jpeg')
        close(f)
    end
end
