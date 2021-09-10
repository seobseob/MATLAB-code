function [dtCell_batch_speed,dtCell_batch_lick_count] = reOrg_data_by_context(dtCell_spd_essen_data,...
                dtCell_batch_speed,dtCell_batch_lick_count,dtCell_lick_count_data,dtCell_batch_idx,param)

    posRange_to_save = param.posRange_to_save;          % position range to save(50-270cm)
    timeRange_to_save = param.timeRange_to_save;        % time range to save(0-2.5sec)
    
    dtMat_ctxt = cell2mat(dtCell_spd_essen_data(2:end,2));
    for ctxtIter = 1:1:3
        ctxt_idx = find(dtMat_ctxt == ctxtIter);
%         dtCell_batch_speed{dtCell_batch_idx+1,ctxtIter+2} = mean(cell2mat(dtCell_spd_essen_data(ctxt_idx+1,12)),'omitnan');     % speed between start run and EndTrial
%         dtCell_batch_speed{dtCell_batch_idx+1,ctxtIter+5} = mean(cell2mat(dtCell_spd_essen_data(ctxt_idx+1,13)),'omitnan');     % speed between BlackStart and EndTrial
%         dtCell_batch_speed{dtCell_batch_idx+1,ctxtIter+8} = mean(cell2mat(dtCell_spd_essen_data(ctxt_idx+1,14)),'omitnan');     % speed between start run and BlackStart
%         dtCell_batch_speed{dtCell_batch_idx+1,ctxtIter+11} = mean(cell2mat(dtCell_spd_essen_data(ctxt_idx+1,15)),'omitnan');    % speed in anticipation area
        
        dtCell_batch_speed{dtCell_batch_idx+1,ctxtIter+2} = cell2mat(dtCell_spd_essen_data(ctxt_idx+1,12));
        dtCell_batch_speed{dtCell_batch_idx+1,ctxtIter+5} = cell2mat(dtCell_spd_essen_data(ctxt_idx+1,13));
        dtCell_batch_speed{dtCell_batch_idx+1,ctxtIter+8} = cell2mat(dtCell_spd_essen_data(ctxt_idx+1,14));
        dtCell_batch_speed{dtCell_batch_idx+1,ctxtIter+11} = cell2mat(dtCell_spd_essen_data(ctxt_idx+1,15));
        
        if param.lick_searching_flag      % reward was given
            % two measurement: 
            % i) licking count based on position bin(50-270cm before 'BlackStart')
            % total sum of licking count(separated by position; from 'start run' to 'BlackStart') over trial
            pos_lick_temp = dtCell_lick_count_data(ctxt_idx+1,3);
            flag = 1; ii = 1;
            while flag
               if ~isnan(pos_lick_temp{ii,1}) 
                   pos_sep = pos_lick_temp{ii,1}(1,:);
                   flag = 0; 
                   pos_sep_len = size(pos_sep,2);
               else
                   if size(pos_lick_temp,1) ~= ii
                      ii = ii + 1;
                   else
                      pos_sep = [];
                      flag = 0;
                   end
               end
            end
            pos_sep_start_idx = find(pos_sep(1,:)==posRange_to_save(1));
            pos_sep_end_idx = find(pos_sep(1,:)==posRange_to_save(2));

            pos_lick_count = [];
            for ii = 1:1:size(pos_lick_temp,1)
                if ~isnan(pos_lick_temp{ii,1})
                    pos_lick_count = [pos_lick_count; pos_lick_temp{ii,1}(2,:)];
                else
                    pos_lick_count = [pos_lick_count; nan(1,pos_sep_len)];
                end
            end
    
            pos_sep(2:size(pos_lick_count,1)+1,:) = pos_lick_count;                 % not sum, but store all of them
            pos_sep = pos_sep(:,pos_sep_start_idx:pos_sep_end_idx);                 % user determined position range to save(here 50-270cm)
            dtCell_batch_lick_count{dtCell_batch_idx+1,ctxtIter+2} = pos_sep;       % licking count by position; from 'start run' to 'BlackStart'
            
            % ii) licking count based on time bin(after 'BlackStart')
            % total sum of licking count(separated by time; from 'BlackStart' to 'EndTrial') over trial
            time_lick_temp = dtCell_lick_count_data(ctxt_idx+1,4);
            time_lick_count_temp = {}; time_lick_count_len = [];
            % cf.) licking count in time separation in each
            % trial has different size of data
            % eg.) in 1st trial, 1-by-11 size of data, 2nd
            % trial, 1-by-8 size of data, so on
            % therefore, spread out the variable size data in
            % a cell variable
            for ii = 1:1:size(time_lick_temp,1)
                if ~isnan(time_lick_temp{ii,1})
                   time_lick_count_temp(ii,1:length(time_lick_temp{ii,1}(2,:))) = num2cell(time_lick_temp{ii,1}(2,:)); 
                   time_lick_count_len = [time_lick_count_len; length(time_lick_temp{ii,1}(2,:))];
                else
                   time_lick_count_len = [time_lick_count_len; 0];
                end
            end
            time_lick_count_temp = cell_empty_fill_zero(time_lick_count_temp);

            % it is possible that a specific context doesn't have licking info.
            if ~isempty(find(time_lick_count_len))
                [~,maxIdx] = max(time_lick_count_len);
                time_sep_start_idx = find(time_lick_temp{maxIdx,1}(1,:)==timeRange_to_save(1));
                time_sep_end_idx = find(time_lick_temp{maxIdx,1}(1,:)==timeRange_to_save(2));
                if isempty(time_sep_end_idx)    % if time_sep_end_idx is not found, the index depicts the end column 
                   time_sep_end_idx = length(time_lick_temp{maxIdx,1}(1,:));
                end
                time_sep = time_lick_temp{maxIdx,1}(1,time_sep_start_idx:time_sep_end_idx); % use 0-2.5sec. time bin arbitary 

                time_lick_count = []; 
                for ii = time_sep_start_idx:1:time_sep_end_idx % use 0-2.5sec. time bin arbitary % size(time_lick_count_temp,2) % all time bin (0-5sec.)
                   temp = cell2mat(time_lick_count_temp(:,ii));
                   time_lick_count = [time_lick_count, temp];  % not sum, but store all of them
                end
                time_sep(2:size(time_lick_count,1)+1,:) = time_lick_count;
                dtCell_batch_lick_count{dtCell_batch_idx+1,ctxtIter+5} = time_sep;        % licking count by time

            else
                dtCell_batch_lick_count{dtCell_batch_idx+1,ctxtIter+5} = NaN;
            end


        else                          % reward was not given
            dtCell_batch_lick_count{dtCell_batch_idx+1,ctxtIter+2} = NaN;
            dtCell_batch_lick_count{dtCell_batch_idx+1,ctxtIter+5} = NaN;
        end
    
    end
    
end

function [time_lick_count_temp] = cell_empty_fill_zero(time_lick_count_temp)

% the input variable(cell type) has empty element( '[ ]' ), and this
% function fill the empty element with '0'

    [row,col] = size(time_lick_count_temp);
    
    for rowIter = 1:1:row
        for colIter = 1:1:col
            if isempty(time_lick_count_temp{rowIter,colIter})
                time_lick_count_temp{rowIter,colIter} = 0;
            end
        end
    end

end