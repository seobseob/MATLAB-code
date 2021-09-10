function Selected_Cell_Mean_Flour_LineGraph4(param,dataTable,varargin)

% this function draws line graphs using mean dF/F with selected cells -
% which most activated cells
% 
% this function follows most of code from 'VR_Excel_Rearrangement_HeatMapCal' function

% heatMapRange: start pos:bin size:end position in each contexts
% dataTable:
% if there are 5 mice, then 5 rows depict 5 mice in a day; 
% from next 5 rows depict 5 mice in another day.
% 1st col: 1st context, 2nd col: 2nd context, 3rd col: 3rd context
%               context1    context2    context3
% day1 mice1      data        data        data
%      mice2      data        data        data
%       ...       ...         ...         ...
% day7 mice1      data        data        data
%      micen      data        data        data
%
% and each cell has the same structure of data:
% 1st trial#, 2nd col: time, 3rd col: x-pos, 4th: velocity, 5th: dF/F(or spike #) in cell1, 6th: dF/F(or spike #) in cell2, so on
% this variable returns data in whole x-position range

if ~isequal(length(varargin),0)
    maxNumOfSelecCell = varargin{1};
else
    maxNumOfSelecCell = 0;
end

heatMapRange2 = 1700:10:1800;

cellSelec_also_diff_ctxt = param.cellSelec_also_diff_ctxt;  % cell selection(C1>C2,C3, so on); selected cells also chose in different contexts
   
param_sub.ctxtCol = 1;                        % context number column in eachData var.
param_sub.timeCol = 2;                        % time column
param_sub.posCol = 3;                         % position column
param_sub.spdCol = 4;                         % speed column
param_sub.cellCol = 5;                        % cell activity column start
param_sub.heatMapRange = param.heatMapRange;
param_sub.trial_lim = [19; 14; 14];           % limitation of trial number: day1: 19, day4: 14, day7: 14 trials
param_sub.animal_number = length(param.miceList);
param_sub.xPos_offset = param.xPos_offset;
param_sub.dayList = param.dayList;
param_sub.miceList = param.miceList;
param_sub.cellSelec_also_diff_ctxt = cellSelec_also_diff_ctxt;

%% data rearrangement for drawing graph

% if cellSelec_also_diff_ctxt == 0
%     dataMiceWiseTable = cell(length(param.miceList)*length(param.dayList),3); % this cell type var. stores all data which satisfied condition
% else            % cell selection(C1>C2,C3, so on); selected cells also chose in different contexts
%     dataMiceWiseTable = cell(length(param.miceList)*length(param.dayList),9);
% end
dtCell_spaceBin = cell(size(dataTable));
dtCell_spaceBin_1800 = dtCell_spaceBin;

% dtCell_real_place_cell_tuning_curve = dtCell_spaceBin;
% dtCell_real_place_cell_activity = dtCell_spaceBin;
% dtCell_real_place_cell_num = dtCell_spaceBin;
dtCell_real_place_cell_SI_activity = dtCell_spaceBin;
dtCell_real_place_cell_SI_num = dtCell_spaceBin;
dtCell_real_place_cell_PF = dtCell_spaceBin;

dtCell_timeBin = cell(size(dataTable));
dtCell_spdBin = cell(size(dataTable));
dtCell_spd_avg = cell(size(dataTable));
dtCell_spd_avg_all_trial = cell(size(dataTable));

dtCell_spaceBin_viewCell = cell(size(dataTable));
dtCell_spaceBin_viewCell_1800 = cell(size(dataTable));
dtCell_3timePhase = cell(size(dataTable));
dtCell_3timePhase_DA = dtCell_3timePhase;
dtCell_time_space = cell(size(dataTable,1),6);
dtCell_avg_act_lickingTime = cell(size(dataTable));

% temporal vars.
dtCell_eachData_before_excl_outlier_speed = cell(size(dataTable));
dtCell_eachData_after_excl_outlier_speed = cell(size(dataTable));

% how much slow speed down in the anticipation area(1700mm-(1st)1790mm)
dtCell_spd_slowDown = cell(size(dataTable));

% to store cell number in each animal in each day
cell_num_animal = [];

f_place_field = waitbar(0,'Place-field processing. Please wait...');
% import data and mean calculation over each bins
for dayIter = 1:1:length(param.dayList)   
     for miceIter = 1:1:length(param.miceList)
        loadingData_idx = ((dayIter-1)*length(param.miceList))+miceIter;   
        
        if cellSelec_also_diff_ctxt == 0
            ctxtIterEnd = 3;
        else                    % cell selection(C1>C2,C3, so on); selected cells also chose in different contexts
            ctxtIterEnd = 9;
        end
        
        for ctxtIter = 1:1:ctxtIterEnd
            param_sub.ctxtIterEnd = ctxtIterEnd;
            param_sub.dayIter = dayIter;
            param_sub.miceIter = miceIter;
            param_sub.ctxtIter = ctxtIter;

            % the data structure of each cell in dataTable is 
            % eachData: ['Trial #', 'Time', 'X-pos', 'Velocity', and 'Selected cells' dF/F,'in cell2', ... 'in celln'];
            eachData = cell2mat(dataTable(loadingData_idx,ctxtIter));   % import data from 'dataTable' - cell type
            
            % speed in eachData is mm/sec unit,thus we have to convert it to cm/sec
            eachData(:,param_sub.spdCol) = eachData(:,param_sub.spdCol) / 10;   % [mm/sec] -> [cm/sec]
            % temporal var. to see data after removing zero and outlier in speed
            idx_tmp = (dayIter-1)*5 + miceIter;
            dtCell_eachData_before_excl_outlier_speed{idx_tmp, ctxtIter} = eachData;
            
            % position data separation by trial
            %
            % this function finds essential position index and 
            % its result contains accumulated essential position index of all trials
            % essen_pos_idx:
            % 1st: start position of each trial, 2nd: position index of 1700, 3rd: 1st 1790, 
            % 4th: starting position index of 3 sec. interval, 5th: end position index of 1790,
            % 6th: 1sec. before 3sec. interval
            essen_pos_idx = finding_essen_pos_idx(eachData,param_sub);
            param_sub.essen_pos_idx = essen_pos_idx; 
            
            %%%%%%%%%%%
            % speed data correction - this function is still controversal 
            % thus, we have to inactivate this paragraph for a while
            %
            % due to VR system technical problem(bottleneck between data
            % acquisition and transferring via National Instruments device and 
            % VR operating computer through USB port, the speed is calculated 
            % inaccurate, such as suddenly speed was too high especially beginning
            % part of each trial
            %
            % we assume that 0-300mm in corridor is beginning part of each trial
%             outlier_thresh = 400;   % [mm] not [cm], arbitary threshold 
% %             eachData = correct_speed_outlier(eachData,param_sub,outlier_thresh);
%             eachData = correct_speed_outlier2(eachData,param_sub,outlier_thresh);   % remove zero and outlier in speed
%             % temporal var. to see data after removing zero and outlier in speed
%             dtCell_eachData_after_excl_outlier_speed{idx_tmp, ctxtIter} = eachData;
            
            %%%%%%%%%%%
            % separate data into user determined speed bins
            % 0:1:40cm 
            param_speed.spd_edges = 0:1:40;
            param_speed.dayIter = dayIter;
            dtMat_spdBin_data = data_reOrg_by_speedBin(eachData,param_sub,param_speed);
            cell_idx = (dayIter-1)*param_sub.animal_number + miceIter;
            % dtMat_spdBin_data stores essential data for each animal,
            % each row: speed bin range, 1st bin: 0<bin<=1cm, 2nd: 1<bin<=2cm, so on
            % 1st col: trial number, 2nd: speed bin number, 3rd: average speed within a bin
            % 4th-end: averaged cell activity
            dtCell_spdBin{cell_idx,ctxtIter} = dtMat_spdBin_data;
                        
            %%%%%%%%%%%
            % speed measurement in different region
            % i) speed in the anticipation area
            % ii) speed entire corridor
            % iii) speed in range of 80-90cm in corridor
            %
            % speed_avg_1Animal stores averaged speed measurement over trials 
            % in each animal, each context
            %
            % dtMat_spd_all_trial: rows: number of trial, 1st col: speed of
            % entire corridor(0-1800mm), 2nd: speed of middle area(800-900mm),
            % 3rd: speed in the anticipation area(1700mm-(1st)1790mm)
            %
            % dtMat_spd_slowDown_all_trial: how much slow speed down in the 
            % anticipation area = speed at 1700mm - speed at (1st) 1790mm 
            [speed_avg_1Animal,dtMat_spd_all_trial,dtMat_spd_slowDown_all_trial] = speed_measurement(eachData,param_sub,param_speed);
            dtCell_spd_slowDown{cell_idx,ctxtIter} = [dtMat_spd_slowDown_all_trial, dtMat_spd_all_trial(:,3)];
            
            % dtCell_spd_avg stores averaged speed measurement over trials in all animal,
            % each row: averaged speed over trials in each animal, 
            % each col: context 1/2/3
            dtCell_spd_avg{cell_idx,ctxtIter} = speed_avg_1Animal;
            % dtCell_spd_avg_all_trial stores speed measurement all trials
            dtCell_spd_avg_all_trial{cell_idx,ctxtIter} = dtMat_spd_all_trial;
            
            %%%%%%%%%%%
            % Spatial Information(SI) - in paper, the deconvolved time courses are 
            %                           circularly shifted by a random interval for 1,000 times
            % Spatial Information(SI) - in our case, we changed the definition
            %                           randomly pick signal in a position bin up without repetition for 1,000 times
            % eachData: ['Trial #', 'Time', 'X-pos', 'Velocity', and 'Selected cells' dF/F,'in cell2', ... 'in celln'];
%             waitbar(((dayIter-1)*length(param.miceList)+miceIter)/(length(param.dayList)*length(param.miceList)), f_place_field)
%             param_sub.SI_random = 1;
%             dtCell_random_SI = cell(1000,1);
%             for randIter = 1:1:1000
%                 random_SI_data = [];
%                 for trialIter = 1:1:param_sub.trial_lim(dayIter)                        % randomly pick up signal in each trial
%                     random_trial_data = eachData(eachData(:,1)==trialIter,5:end);
% 
%                     % code for new definition of SI (see above)
%                     random_trial_data_idx = randperm(size(random_trial_data,1));        % set up random index without repetition
%                     random_trial_data = random_trial_data(random_trial_data_idx,:);     % randomly pick up signal and data structure was re-organized
%                                         
%                     % code for previous definition of SI (see above)
%                     %rand_intvl = randi([1,size(random_trial_data,1)],1,1);             % setting random shifting interval
%                     %random_trial_data = circshift(random_trial_data,rand_intvl,1);    % circularly shifting with random interval
%                     random_SI_data = [random_SI_data; eachData(eachData(:,1)==trialIter,1:4), random_trial_data];
%                 end
%                 % calculate SI with shifted_SI_data 
%                 % shifted_eachData{shiftIter,1} = shifted_SI_data;
%                 [dtCell_spaceBin,dtCell_spaceBin_1800,dtMat_shifted_SI] = ...
%                             data_reOrg_by_spaceBin(random_SI_data,dtCell_spaceBin,param_sub,dtCell_spaceBin_1800);
%                 dtCell_random_SI{randIter,1} = dtMat_shifted_SI;
%             end
            %%%%%%%%%%%
            % separate data into user determined space bins
            % c.f) we have to consider the end range of x-position which is (1st) 1790 
            % dtCell_spaceBin: heat-map range(0:100:1800)*trial number-by-cell number(+four additional column: space bin
            % number, context number, trial number, average speed in a particular space bin)
            % 1st col: space bin number, 2nd: context number, 3rd: trial number,
            % 4th: average speed(cm/s, outlier could be excluded-check code before),
            % 5th-end: selected cells' activity
            %
            %xcc dtCell_spaceBin_1800 var. considers  the end range of
            % x-position which is (end) 1790
            param_spaceBin.mode = 'normal';%'peak';       % 'normal': using normal dF/F, 'peak': using amplitude of peak
            [dtCell_spaceBin,dtCell_spaceBin_1800] = data_reOrg_by_spaceBin(eachData,dtCell_spaceBin,param_sub,dtCell_spaceBin_1800,param_spaceBin);
            
            %%%%%%%%%%%%
%             % real place cells defined by place field
%             param_sub.SI_on = 0;    % off searching function for Spatial Information(SI) based place cells
%             if isequal(param_sub.SI_on,0)
%                 param_sub.SI_random = 0;
%             end
%             [dtStruct_real_place_cell_PF_output] = place_field_cells(eachData,param_sub);
%                         
%             dtCell_idx_tmp = (dayIter-1)*length(param.miceList) + miceIter;           
%             dtCell_real_place_cell_PF{dtCell_idx_tmp,ctxtIter} = dtStruct_real_place_cell_PF_output;
%             real_place_cell_PF_idx = dtCell_real_place_cell_PF{dtCell_idx_tmp,ctxtIter}.dtMat_PF_place_cell_index;
%             if ~isempty(real_place_cell_PF_idx)
%                 dtCell_real_place_cell_PF{dtCell_idx_tmp,ctxtIter}.dtMat_real_place_cell_raw_activity = eachData(:,[1:4,real_place_cell_PF_idx+4]);
%             end
%             
%             % the original SI(dtMat_SI) is compared against the shuffled SI(dtMat_shifted_SI) distribution.
%             % If the original SI was greater than 95 percentile of the shuffled SI, the neuron is considered 
%             % to carry significant spatial information and identified as a potential place cell
%             % In normal distribution, 95% of data is included between < mu+2*sigma and > mu-2*sigma
% %             dtMat_SI_binary = [];
% %             for randIter = 1:1:1000
% %                 mu = mean(dtCell_random_SI{randIter,1}); 
% %                 sigma = std(dtCell_random_SI{randIter,1});
% %                 dtMat_SI_binary = [dtMat_SI_binary, (dtMat_SI > mu+2*sigma) | (dtMat_SI < mu-2*sigma)];
% %             end
% %             dtMat_SI_cell = find(sum(dtMat_SI_binary,2)==1000);
% %             if ~isempty(dtMat_SI_cell)
% %                 dtCell_real_place_cell_SI_num{dtCell_idx_tmp,ctxtIter} = dtMat_SI_cell;
% %                 dtCell_real_place_cell_SI_activity{dtCell_idx_tmp,ctxtIter} = eachData(:,[1:4,dtMat_SI_cell'+4]);
% %             end
%             % the place field related data are re-organized and analzed in
%             % fraction_of_place_cell_by_different_methods.m
%             
%             % dtCell_spaceBin_viewCell is re-organized data of dtCell_spaceBin, and 
%             % it contains cell wise data set following heat-map space range
%             % range of x-position 0-(1st)1790mm
%             % dtCell_spaceBin_viewCell:
%             % number of cell-by-heat-map space range(0:100:1800),
%             % 1st row: cell1, 2nd: cell2, 3rd: cell3 activity, so on
%             % 1st col: space bin1, 2nd: bin2, 3rd: bin3, so on
%             dtCell_spaceBin_viewCell = data_reOrg_by_spaceBin_viewCell(dtCell_spaceBin,dtCell_spaceBin_viewCell,param_sub);
%             
%             % range of x-position 0-(end)1800mm
%             dtCell_spaceBin_viewCell_1800 = data_reOrg_by_spaceBin_viewCell(dtCell_spaceBin_1800,dtCell_spaceBin_viewCell_1800,param_sub);
            
            %%%%%%%%%%%
            % separate data into user determined time bins
            % dtCell_timeBin: time range(0:0.5:variable end)*trial number-by-cell number(+four additional column: time bin
            % number, context number, trial number, average speed in a particular time bin)
            % 1st col: time bin number, 2nd: context number, 3rd: trial number,
            % 4th: average speed(cm/s, outlier could be excluded-check code before),
            % 5th-end: selected cells' activity
            param_time.timeBin_scale = 0.5;
            [dtCell_timeBin] = data_reOrg_by_timeBin(eachData,dtCell_timeBin,param_sub,param_time);
            
            
            %%%%%%%%%%%
            % three time phases: i) 1700-(1st)1790, ii) licking time; (2nd)1790-before 3sec interval, iii) 3sec interval 
            param_three_time_phases.bigTable_idx = loadingData_idx;
            
            % user determined hyper-parameters
            param_three_time_phases.timeBin_Dur = 0.2;              % 0.1 sec. = 1 bin in heat-map data table
            param_three_time_phases.trial_lim = [19; 14; 14];       % limitation of trial number: day1: 19, day4: 14, day7: 14 trials

            % I got these min. time period manually using 'Find_time_period.m'
            param_three_time_phases.min_lick_time = 0.988;          % min licking time over all animal, all day, all trial
            param_three_time_phases.min_anti_time = 0.179;          % min anticipation area remaining time
            param_three_time_phases.min_threeSec_time = 3.0;        % min three second interval animal remaining

            % time_phase_mode = 1/2/3/31: data table has only one specific time phase data
            % time_phase_mode = 1: anticipation area, 2: licking time, 3: 3sec. interval time phase
            % 31: 1sec. before 3sec. interval time phase
            % time_phase_mode = 4: data table has all time phase data
            param_three_time_phases.time_phase_mode = 3;            

            % mode = 1: normal mode - using general time period in each time phase
            % mode = 2: min time mode - using min time period in each time phase
            % (see vars. 'min_lick_time', 'min_anti_time', 
            % and 'min_threeSec_time')
            param_three_time_phases.time_mode = 2;      
            
            % mode = 1: normal mode - time bin
            % mode = 2: ITI(Inter-Trial-Interval) mode - time bin in ITI 
            param_three_time_phases.time_bin_organization_mode = 1;
            [~, dtCell_3timePhase_DA] = three_time_phases(eachData, dtCell_3timePhase_DA, param_sub,param_three_time_phases);
            
            %%%%%%%%%%%
%             % mean activity (dF/F) only in licking time: (2nd)1790-before 3sec interval
%             % using result data we will draw bar graphs or heat-map of 
%             % average cell activity (dF/F)
%             [dtCell_avg_act_lickingTime] = avg_activity_in_lickingTime(eachData, ...
%                         dtCell_avg_act_lickingTime, param_sub,param_three_time_phases); 
          
            %%%%%%%%%%%
            % space - time relationship; space on x-axis, time on y-axis, and vice versa. 
            % e.g. For each 10 cm space bin matches mean of corresponding time duration
            % and vice versa
            %
            % cell selection or all cells is not matter here because each cell activity is not interested in

%             param_spc_time.timeBin_scale = 0.50;                % 0.25/0.50 sec. = 1 bin
%             param_spc_time.diagram_show = 0;                    % show diagram in the end(True=1) or not(False=0)?
%             param_spc_time.diagram_show_axisOff = 0;            % show axis off images
%             param_spc_time.loadingData_idx = loadingData_idx;
%     
%             dtCell_time_space = space_time_fun(eachData,param_sub,param_spc_time);
            
            if isequal(ctxtIter,1)
                cell_num_animal = [cell_num_animal; (size(eachData,2)-4)];
            end
        end
        
    end
end
delete(f_place_field)

% dtCell_spd_avg_summary stores averaged speed over animals within a day, 
% in each context
dtCell_spd_avg_summary = cell(length(param.dayList),ctxtIterEnd*2);
for dayIter = 1:1:length(param.dayList)
    for ctxtIter = 1:1:ctxtIterEnd
        for animalIter = 1:1:param_sub.animal_number
            animal_idx = ((dayIter-1)*param_sub.animal_number + 1):dayIter*param_sub.animal_number;
            ctxt_idx = (ctxtIter-1)*2 + 1;
            dtCell_spd_avg_summary{dayIter,ctxt_idx} = mean(cell2mat(dtCell_spd_avg(animal_idx,ctxtIter)),1);
            dtCell_spd_avg_summary{dayIter,ctxt_idx+1} = ...
                            std(cell2mat(dtCell_spd_avg(animal_idx,ctxtIter)),1) / sqrt(length(animal_idx));
        end
    end
end

param_sub.cell_num_animal = cell_num_animal;

% test code for real place cell defined by Place Field visualization
[dtCell_overlapped_cell_over_context_all_animal,dtCell_overlapped_cell_over_context,dtCell_heatMap_yTickLabel_eachDay_eachCtxt, ...
    dtCell_heatMap_eachDay_eachCtxt,dtMat_fraction_place_cell,dtMat_fraction_place_cell_result,dtCell_none_overlap_posBin,dtCell_overlap_posBin]...
     = place_cell_PF_support_func(dtCell_real_place_cell_PF,param_sub);
place_cell_PF_visual_func   % private function

% % mean activity (dF/F) only in licking time: (2nd)1790-before 3sec interval
% % using result data we will do summary of average cell activity (dF/F) in 
% % each animal and context
% param_avg_act_in_lickingTime.ctxtIterEnd = ctxtIterEnd;
% avg_activity_each_trial_day = avg_activity_in_lickingTime_summary(dtCell_avg_act_lickingTime,...
%                                                         param_sub,param_avg_act_in_lickingTime);

%% average activity in context predicting with 3 seconds interval, avg. dF/F in context1 vs. context2

% % param_three_time_phases.min_lick_time = 0.988;          % min licking time over all animal, all day, all trial
% % param_three_time_phases.min_anti_time = 0.179;          % min anticipation area remaining time
% % param_three_time_phases.min_threeSec_time = 3.0;        % min three second interval animal remaining
% %
% % param_three_time_phases.time_mode:
% % mode = 1: normal mode - using general time period in each time phase
% % mode = 2: min time mode - using min time period in each time phase
% %
% % dtCell_3timePhase_DA: 
% % Day1: animal number-by-three contexts
% % Day4 and Day7 are stacked in row
% % each element: 
% % 1st col: time bin, 2nd: context, 3rd: trial, 4th: reward flag(True/False) 
% % 5th: weight by reward flag, 6th-end: mean dF/F each cell 
% 
% param_ctxt_cell_3sec.figure_show = 1;                                      % show diagram in the end(True=1) or not(False=0)?
% param_ctxt_cell_3sec.figure_show_axisOff = 0;                              % show axis off images
% [avg_activity_comp,avg_activity] = avg_activity_compare_ctxt_cell_in_3sec(dtCell_3timePhase_DA, ...
%                                     param_three_time_phases.trial_lim, param_sub,param_ctxt_cell_3sec);

%% average activity in whole x-position, 0-(1st)1790mm and 0-(end)1800mm

% %%%%%%%%%%%
% % mean activity (dF/F) only in licking time: (2nd)1790-before 3sec interval
% % using result data we will draw bar graphs or heat-map of 
% % average cell activity (dF/F)
% %
% % eachData must be sorted by cell_sorting()
% % option1: cell sorting by big value in each columns, 
% % option2: inverse of option1, cell sorting by big value only in the last column
% % option3: cell sorting by entropy, 
% %          equation: % -sum((ni/N)*log2((ni/N))) = log2(N) - (1/N)*sum(ni*log2(ni))
% %                    where N: sum, ni: element
% % option4: cell sorting by median
% % option5: cell sorting by mean activity each cell
% param_mean_act.sorting_flag = 5;
% param_mean_act.figure_show = 0;
% param_mean_act.figure_show_axisOff = 0;
% 
% % dtCell_avg_act_whole_pos contains average activity in whole position 
% % in each animal in each day in each context
% % 1st col: day, 2nd: animal number, 3rd: context number, 4th: average
% % activity(dF/F) in whole position 0-(1st)1790mm, 5th: standard deviation of 4th col   
% [dtCell_avg_act_whole_pos] = avg_activity_whole_position(dtCell_spaceBin_viewCell,param_sub,param_mean_act);
% 
% % range of x-position 0-(end)1800mm
% [dtCell_avg_act_whole_pos_1800] = avg_activity_whole_position(dtCell_spaceBin_viewCell_1800,param_sub,param_mean_act);
% 
% % summarize the previous stage(avg_activity_whole_position())
% % range of x-position 0-(1st)1790mm
% % dtCell_avg_act_whole_pos_summary:
% % 1st col: day, 2nd: context number, 3rd: average activity (dF/F) of all
% % animal in a day in a context, 4th: standard error of the mean of 3rd col
% [dtCell_avg_act_whole_pos_summary] = avg_activity_whole_position_summary(dtCell_avg_act_whole_pos,param_sub);
% 
% % range of x-position 0-(end)1800mm
% [dtCell_avg_act_whole_pos_summary_1800] = avg_activity_whole_position_summary(dtCell_avg_act_whole_pos_1800,param_sub);

%% view predicting cells

param_view.shuffle_spcBin_flag = 0;                              % user determined flag whether shuffle space bin in each cell or not
param_view.zero_pad_size = 5;                                    % zero padding in front of signal for signal shifting         
param_view.pValue_level = 0.01;                                  % Spearman p-value level
param_view.figure_show = 0;                                      % show diagram in the end(True=1) or not(False=0)?
param_view.figure_show_axisOff = 0;                              % show axis off images

% ctxtDataCellWise must be sorted by cell_sorting()
% option1: cell sorting by big value in each columns, 
% option2: inverse of option1, cell sorting by big value only in the last column
% option3: cell sorting by entropy, 
%          equation: % -sum((ni/N)*log2((ni/N))) = log2(N) - (1/N)*sum(ni*log2(ni))
%                    where N: sum, ni: element
% option4: cell sorting by median
%
% in this case of sorting_flag = 3, return var. of 'sortOrder' has cumulative sum and
% edges data of entropy over cells, eg) sortOrder 1st row: cumsum, 2nd row: edges
param_view.sorting_flag = 1;

% sig_cell_total: 
% 1st col: ctxt-day, 2nd: number of significant cells, 3rd: number of total cells each day,
% 4th: percentage of significant cells, 5th: mean of significant cells' rho^2,
% 6th: standard deviation of significant cells' rho^2, 
% 7th: standard error of mean. Prof.'s suggestion but I don't agree with him 
% 8th: significant cells' rho^2

% sig_cell_total2:
% 1st cell: ctxt-day, 2nd/3rd: reference signal and its SEM, 4/5th:
% averaged signal and its SEM

% view_cell_total: 
% 1st cell: ctxt-day, 2nd: data cell
%
% each element in view_cell_total:
% 1st col: cell number, 2nd: p-value, 3rd: one-hot encoding(eg. p-value < level, '1' otherwise '0')

% percentage of overlapped cells between contexts  
% overlapped_view_cell: 
% 1st col: day, 2nd: % of overlapped cells between context 1&2, 3rd: between context 1&3,
% 4th: between context 2&3, 5th: between all contexts, 6th: % of none overlapped cells

% temporal var.: shuffle_data = dataCellWiseTable_shuffle_spacebin_eachcell;
[sig_cell_total,sig_cell_total2,view_cell_total,overlapped_view_cell,dtCell_spaceBin_viewCell_shuffled,none_overlapped_view_cell]...
            = view_cell_func(dtCell_spaceBin_viewCell,param_sub,param_view); % (dataCellWiseTable_shuffle_spacebin_eachcell,param_sub,param_view);

param_view2.pValue_threshold = 0.007; %[0.01/7, 0.007];
% rho_max lag threshold: 
% i) if lags are all positive: bigger or equal to -3 or smaller or equal to 3
% ii) if lags has negative: smaller or equal to 7
param_view2.lags_threshold = [3, 7];
% wall paper with three different patterns in each row
% option 1) pattern change black->white: 1, other: 0
% option 2) pattern with intensities: wall-paper pattern is not exactly matched to the position bin(10cm),
% thus, expand scale to 1e-5m and re-group into 10cm bins;
% each bins includes average intensity within bin; black colored bar in
% wall-paper1 & 2 has 1, white colored bar has 0
% option 3) we assume that the wall-paper is 0.3333 ratio shifted to the left
% option 4) we assume that the wall-paper is not shifted 
param_view2.wallPaper_pattern = 1;
% normalization by min-max scaling with input data set;
% controlled by flag_normal
param_view2.flag_normalization = 1;
% calculation of point-biserial or rank-biserial correlation; 
% controlled by flag_point_biserial & flag_rank_biserial
param_view2.flag_point_biserial = 0;
param_view2.flag_rank_biserial = 0;
param_view2.flag_visual_func = 0;


[dtCell_sigCell_activity_allFactor2,dtCell_sigCell_pVal_allFactor2,...
    dtCell_sigCell_rho_lags_allDay2,overlapped_view_cell] = view_cell_xcorr_func(dtCell_spaceBin_viewCell,param_sub,param_view2);

[dtStruct_output] = view_cell_xcorr_func_temp2(dtCell_spaceBin_viewCell,param_sub,param_view2);

[dtCell_sigCell_activity_allFactor2,dtCell_sigCell_pVal_allFactor2,...
    dtCell_sigCell_rho_lags_allDay2,overlapped_view_cell] = view_cell_xcorr_animal_based_func(dtCell_spaceBin_viewCell,param_sub);


% % chi-square test
% [chi_square_result] = chi_sq_calculation_fcn(sig_cell_total,param.dayList,ctxtIterEnd);



%% activity(dF/F) ratio(between context1 and 2) calculation in each categorization - Context, Position, and View prediction

% dtCell_view_cell contains view cell list
% cf) view cell is categorized by a data table all cells from all animal in a day integrated 
% thus, we have to consider separation of view cells by each animal
param_avg_activity_comp.factorList = {'context','position','view','speed'};
param_avg_activity_comp.trial_lim = param_three_time_phases.trial_lim;

% temopral function to find and store common context predicting cells 
% from *.excel and *.mat file which contain context predicting cells in 
% 0-(1st) 1790mm and 3sec interval region
dtCell_common_ctxt_cell = common_ctxt_cell();
param_avg_activity_comp.common_ctxt_cell = dtCell_common_ctxt_cell;

% dtCell_spaceBin var. considers  the end range of x-position which is (1st) 1790
% ratio_compare returns result of one single value, but
% ratio_comp_spaceBin returns result of matrix in 18 space bins
[ratio_compare,ratio_comp_posBin] = avg_activity_compare_ctxt_pos_view(dtCell_spaceBin,param_sub,param_avg_activity_comp);

% this function summarize ratio_comp_posBin variable
ratio_comp_posBin_summary = ratio_comp_posBin_func(ratio_comp_posBin,param_sub,param_avg_activity_comp);

% calculation only for context cell in 3sec interval
% caution!! if you want to calculate avgerage activity for 1sec before 3sec interval 
% you have to set "time_phase_mode = 31: 1sec. before 3sec. interval time phase"
% for three_time_phases() function above
% otherwise set "time_phase_mode = 3" as a default
ratio_compare_with_ctxtCell_3secIntvl = avg_activity_compare_ctxt_pos_view_ctxt_cell_in_3sec_intvl(dtCell_3timePhase_DA,param_sub,param_avg_activity_comp);

%% speed by position bin (0-(1st)1790mm)

% this function requires that outlier in speed must be excluded and 
% inactivate three_time_phases() section above
param_spd_by_pos.trial_lim = param_three_time_phases.trial_lim;   % [19;14;14];
param_spd_by_pos.figure_show_axisOff = 0;  
param_spd_by_pos.day = 1;
param_spd_by_pos.animal = 1;
spd_over_trial = speed_by_pos(dtCell_spaceBin,param_sub,param_spd_by_pos);

%% factors combination using one-hot encoding information

% eg.) factorList = {'context','position','view'} and in case of 
% factor combination = 'context' * 'position'. In general, factor comparison 
% take place 'context'==1 & 'position'==1 & 'view'==0, however, if
% excl_flag is true(=1) factor comparison take place 'context'==1 &
% 'position'==1, exclude 'view' factor

%param_factors_combi.factorList = {'context','position','view','speed','time'};
param_factors_combi.factorList = {'context','position','view','speed'};
param_factors_combi.excl_flag = 0;
param_sub.dayList = {'day1','day4','day7'};     % temporally - delete this code later
param_sub.miceList = {'13118','13696','13775','13776','14228'};   % temoporally - delete this code later

% dtCell_factor_combination: 
% 1st col: factor combination, 2nd: one-hot-encoding data of combinated
% factors in all animals on day1, 3rd: on day4, 4th: on day7, 
% 5th: calculation by factor combination in all animals on day1, 
% 6th: on day4, 7th: on day7
% 
% mode=1: multiple factors combinations comparison,
% mode=2: get one-hot encoding information from specific factors
mode = 1;
dtCell_factor_combination = factors_combination_for_vennDiagram2(param_sub,param_factors_combi,mode);

if isequal(mode,1)
    % calculate average % of factors combination and SEM in dtCell_factor_combination
    dtCell_factor_combination = reOrg_factors_combination_for_vennDiagram(dtCell_factor_combination,param_sub.dayList);
end

% [input parameters]
% deCell_spdBin includes speed binned data all animal all day all context
% each element, which is dtMat_spdBin_data, stores essential data for each animal,
% each row: speed bin range, 1st bin: 0<bin<=1cm, 2nd: 1<bin<=2cm, so on
% 1st col: trial number, 2nd: speed bin number, 3rd: average speed within a bin
% 4th-end: averaged cell activity
%
% dtCell_factor_combination: 
% 1st col: factor combination, 2nd: one-hot-encoding data of combinated
% factors in all animals on day1, 3rd: on day4, 4th: on day7, 
% 5th: calculation by factor combination in all animals on day1, 
% 6th: on day4, 7th: on day7

% [output]:
% dtCell_spd_act includes averaged speed over trials(equation is described below section)
% from speed cells in each animal in each context in each day
% each row: each animal in each day, each col: context 1/2/3
% eq:  sum_bin(1):bin(end) avg.speed*avg.activity within i-th bin  /
%         sum_bin(1):bin(end) avg.activity within i-th bin
%
% dtCell_cum_spd_category includes data which consists of categorization of speed using cumulative probability
% all animals in each context in each day
% each row: each animal in each day, each col: context 1/2/3
%
% dtMat_cum_spd_category_summary_by_day includes data summarized over
% animals in each context in each day
% each row: days, 1st col: averaged % of speed cells(slow/mid/fast) in context1, 
% 2nd: SEM of speed cells(slow/mid/fast) in context1, 3rd: avg. % of
% speed cells in context2, 4th: SEM of speed cells in context3, so on
[dtCell_spd_act,dtCell_cum_spd_category,dtCell_cum_spd_category_summary_by_day] = ...
            speed_extra_cal(dtCell_spdBin,dtCell_factor_combination,param_sub,param_speed);

%% 
    % extra function - speed 
    % D7 M5 C3 => bigTable{15,9}
    % D1 M2 C2 => bigTable{2,5}
    
    param_speed.figure_show = 1;            % show figures in the end(True=1) or not(False=0)?
	param_speed.figure_show_axisOff = 0;    % show axis off in figures
    param_speed.speed_bin_interval = 0:1:40; % speed cell bin, 0 to 40cm/s with 1cm/s interval
    
    % Using XLSTAT which is add-on in the MS Excel, we found good example 
    % e.g) i) day7, animal5, context3, ii) day1, animal2, context2
    % However, we have to show good example of single cell, thus we do
    % discriminant analysis over all cells. This is time consuming manual
    % work so we replace by MATLAB code with fitlm command below
    %
    % The code below returns good example of single cells when user gives
    % [day,animal,context] information to the sub function
    % when users do not know which day, animal is good example,
    % good_example is remained empty vector
    good_example = []; %[1,2,3; 7,5,3];      % [day,animal,context]
    
    [good_example_reOrg] = spd_cell_varInit(good_example,param_sub.animal_number);
    param_speed.rSq_thresh = 0.45;
    
    % find good example of single cell
    [dtTable_rSq] = spd_cell_singleCell(good_example,good_example_reOrg,...
        dtCell_spaceBin,param_speed.rSq_thresh,param_sub.animal_number);
    % dtTable_rSq: [day,animal,context,cell,r-squared value]
    % if there are cells satisfied user determined r-square
    % threshold(param_speed.rSq_thresh) the cell number is recorded in
    % dtTable_rSq, otherwise it is recorded as 0
    dtTable_rSq = table2array(dtTable_rSq(:,1:4));
    good_example_cell_idx = find(dtTable_rSq(:,4));
    param_speed.good_example = dtTable_rSq(good_example_cell_idx,:);
    
%     % good example 
%     % D7 M5 C3 => dataTable{15,3}   % dataTable{15,9}
%     % D1 M2 C2 => dataTable{2,2}    % dataTable{2,5}, 5th cell
%     param_speed.good_example = [1,2,2,5;7,5,3,x];   % [day,animal,context,cell]
    
    % dtCell_spaceBin consists of separated data into user determined space bins
    % the data structure of each cell in the dtCell_spaceBin is 
    % 1st col: space bin(0-180cm, 10cm bin each), 2nd: context number, 
    % 3rd: trial number, 4th: speed(cm/sec), 5th-end: cell activity(dF/F)
    speed_cell(dtCell_spaceBin,param_sub,param_speed);
    
 %% extra function - context cells

    % integrate all context data in one data table
    % D7 M3 2/8/12/26/27/30/43th cells 
    % D1 M3 6/8/10/15/19/26/33/40/41/43/45/56th cells
    % D4 M2 2/10/27/30/31/32/38/72th cells
    % D4 M3 2/5/9/10/13/16/18/20/25/26/27/28/31/47th cells
    % D7 M5 11/13/15/16/20/23th cells
    
%------ correct way - Alexander prefer    
    % context1
    % dt_tmp: 1st col: space bin, 2nd: context #, 3rd: trial #, 4th: velocity, 5th-end: cells' activity
    dt_tmp = dtCell_spaceBin{15,1};     % D7 M3: bigTable{13,1:3};, D1 M3: bigTable{3,1:3};
    idx_tmp = find(dt_tmp(:,3) == 14); % D1: 19 trials, D4/7: 14 trials
    dt_ctxt1 = dt_tmp(1:max(idx_tmp),:);
    dt_ctxt1_heat = zeros(14,18);   % 18 space bin on x-axis, 14 trials on y-axis
    
    % context2
    dt_tmp = dtCell_spaceBin{15,2};
    idx_tmp = find(dt_tmp(:,3) == 14);
    dt_ctxt2 = dt_tmp(1:max(idx_tmp),:);
    dt_ctxt2_heat = zeros(14,18);
    
    % context3
    dt_tmp = dtCell_spaceBin{15,3};
    idx_tmp = find(dt_tmp(:,3) == 14);
    dt_ctxt3 = dt_tmp(1:max(idx_tmp),:);
    dt_ctxt3_heat = zeros(14,18);
    
    cell_list= [11,13,15,16,20,23];
    for trialIter = 1:1:length(cell_list)
        for cellIter = 1:1:14
            % context1
            idx_tmp = find(dt_ctxt1(:,3) == cellIter);     % find trial#
            dt_ctxt1_heat(cellIter,:) = dt_ctxt1(idx_tmp,cell_list(trialIter)+4)';    % 8th cell: 8+4, 12th cell: 12+4, so on
            
            % context2
            idx_tmp = find(dt_ctxt2(:,3) == cellIter);
            dt_ctxt2_heat(cellIter,:) = dt_ctxt2(idx_tmp,cell_list(trialIter)+4)';
            
            % context3
            idx_tmp = find(dt_ctxt3(:,3) == cellIter);
            dt_ctxt3_heat(cellIter,:) = dt_ctxt3(idx_tmp,cell_list(trialIter)+4)';
        end
        
        % context1
        figure, imagesc(dt_ctxt1_heat); caxis([0 1]); colormap('parula');
        xlabel('Position in VR (cm)'); ylabel('Trial');
        xticks([]); xticklabels({});
        yticks([]); yticklabels({});
        %colorbar('Ticks',[0,0.2, 0.4,0.6,0.8,1.0])
        %title('30th cell - day7-animal3-context1')
%         fileName = ['context cells - ',num2str(cell_list(jj)),'th cell - day4-animal3-context1.tif'];
%         saveas(gcf,fileName);
%         close(gcf)
        
        % context2
        figure, imagesc(dt_ctxt2_heat); caxis([0 1]); colormap('parula');
        xlabel('Position in VR (cm)'); ylabel('Trial');
        xticks([]); xticklabels({});
        yticks([]); yticklabels({});
        %colorbar('Ticks',[0,0.2, 0.4,0.6,0.8,1.0])
        %title('30th cell - day7-animal3-context2')
%         fileName = ['context cells - ',num2str(cell_list(jj)),'th cell - day4-animal2-context2.tif'];
%         saveas(gcf,fileName);
%         close(gcf)
        
        % context3
        figure, imagesc(dt_ctxt3_heat); caxis([0 1]); colormap('parula');
        xlabel('Position in VR (cm)'); ylabel('Trial');
        xticks([]); xticklabels({});
        yticks([]); yticklabels({});
        %colorbar('Ticks',[0,0.2, 0.4,0.6,0.8,1.0])
        %title('30th cell - day7-animal3-context3')
%         fileName = ['context cells - ',num2str(cell_list(jj)),'th cell - day4-animal2-context3.tif'];
%         saveas(gcf,fileName);
%         close(gcf)
    end
%-----------    
    
%------ different way
    dt_tmp = dtCell_spaceBin{13,1};     % D7 M3: bigTable{13,1:3};, D1 M3: bigTable{3,1:3};
    idx_tmp = find(dt_tmp(:,3) == 14);
    dt_inte = dt_tmp(1:max(idx_tmp),:);
    
    dt_tmp = dtCell_spaceBin{13,2};
    idx_tmp = find(dt_tmp(:,3) == 14);
    dt_inte = [dt_inte; dt_tmp(1:max(idx_tmp),:)];
    
    dt_tmp = dtCell_spaceBin{13,3};
    idx_tmp = find(dt_tmp(:,3) == 14);
    dt_inte = [dt_inte; dt_tmp(1:max(idx_tmp),:)];
        
    data = zeros(14,3);     % D1: 19 trials zeros(19,3);, D4/7: 14 trials zeros(14,3);
    for cellIter = 1:14 
        idx_tmp = find(dt_inte(:,2)==1 & dt_inte(:,3)==cellIter);       % 2nd col: context #, 3rd: trial #
        mean_tmp = mean(dt_inte(idx_tmp,47),1);      % 8th cell: mean(dt_inte(idx_tmp,12),1);, 26th cell: mean(dt_inte(idx_tmp,30),1);, cell no.: cell + 4
        data(cellIter,1) = mean_tmp; 
        idx_tmp = find(dt_inte(:,2)==2 & dt_inte(:,3)==cellIter);  % context2
        mean_tmp = mean(dt_inte(idx_tmp,47),1);
        data(cellIter,2) = mean_tmp; 
        idx_tmp = find(dt_inte(:,2)==3 & dt_inte(:,3)==cellIter);  % context3
        mean_tmp = mean(dt_inte(idx_tmp,47),1);
        data(cellIter,3) = mean_tmp;
    end

    figure, imagesc(data); caxis([0 1]); colormap('parula'); 
    xlabel('Context'); ylabel('Trial'); 
    xticks([1 2 3]); xticklabels({'1','2','3'});
    colorbar('Ticks',[0,0.2, 0.4,0.6,0.8,1.0])
    title('43rd cell - day7-animal3')
%     % I will work on this later"!!!
%     % extra function - time cell 
%     % be careful! here bigTable is re-organized data set by 0.25 sec time bin
%     % D1 M5 C1 => bigTable{5,1}
%----------------   

%% time predicting cells

param_time_cell.high_rSq_num = 10;           % user determined number of high r-squared value, eg) top 5 high r-squared value
param_time_cell.figure_show = 1;
param_time_cell.figure_show_axisOff = 1;
[rSq,rSq_cellNo] = time_cell_func(dtCell_timeBin,param_sub,param_time_cell);

%     % I will work on this later"!!!
%     % extra function - time cell 
%     % be careful! here bigTable is re-organized data set by 0.25 sec time bin
%     % D1 M5 C1 => bigTable{5,1}
%     % D4 M2 C3 => bigTable{7,9}
%     % D7 M1 C1 => bigTable{11,1}
%     
%     % bigTable2:
%     % save data re-organized by licking time info, 1st col: time bin, 2nd: context,
%     % 3rd: trial, 4th: reward(1/0), 5th: weight(1/2), 6th to end: cell dF/F
%     time = bigTable{5,1}(:,1);
%     rSq = [];
%     for ii = 1:length(bigTable{5,1}(1,:))-5
%         activity = bigTable{5,1}(:,5+ii);
%         mdl = fitlm(activity,time);
%         rSq = [rSq; mdl.Rsquared.Ordinary];
%     end
%     % D1 M5 C1, 11th cell R2: [0.1353]
%     
%     timeIntvl = 0:10:400;
%     actIntvl = zeros(14,length(timeIntvl));
%     
%     cellIter = 4;
% 
%     for trialIter = 1:14
%         trialIdx = find(trialIter==bigTable{15,7}(:,3));    % D7 M5 C3 => bigTable{15,9}, D1 M2 C2 => bigTable{2,5}
%         vel = bigTable{15,7}(trialIdx,4);
%         activity = bigTable{15,7}(trialIdx,cellIter+4); % 1st cell: (trialIdx,5), 5th cell: (trialIdx,9);, 14th cell: (trialIdx,18);
%         
%         for spdIter = 1:1:length(timeIntvl)
%             if spdIter <= length(timeIntvl)-1
%                 idxTmp = find(vel >= timeIntvl(timeIter) & vel < timeIntvl(timeIter+1));
%             else
%                 idxTmp = find(vel >= timeIntvl(timeIter));
%             end
%             
%             if ~isempty(idxTmp)
%                 actTmp = activity(idxTmp,:);
%                 actIntvl(trialIter,timeIter) = mean(actTmp,1);
%             end
%         end
%     end
%     
%     figure, imagesc(actIntvl); caxis([0 1]); colormap('parula');
%     xticks([]); xticklabels({}); yticks([]); yticklabels({});

%% extra function - reward cells

    % integrate all context data in one data table
    
    % consider only anticiapation area
    % D4 M1 1/2/6/22/37/38/39/45th cells
    % D7 M1 1/12/23/24/25/43th cells
    % D4 M5 3/17/22/41th cells
    % D7 M5 1/13/15/33th cells    
    
    % consider all area
    % D4 M3 2,13,16,20,25,26th cells
    % D4 M4 1,7,12,13,29,30,33,34,35,36,43th cells
    % D4 M1 2,10,13,17,18,20,22,24,34,38,39,48,49,53th cells
    %
    % D7 M3 1,2,12,19,20,35,36,43th cells
    % D7 M4 3,8,10,14,29,30,33,35,36th cells
    % D7 M1 1,5,7,11,17,18,25

%--------- Alexander's way: normal heat-map 0-(1st)1790mm range ----------%
% context1
    % dt_tmp: 1st col: space bin, 2nd: context #, 3rd: trial #, 4th: velocity, 5th-end: cells' activity
    dt_tmp = dtCell_spaceBin{13,1};     % D7 M1: bigTable{11,1:3};, D4 M1: bigTable{6,1:3};
    idx_tmp = find(dt_tmp(:,3) == 14); % D1: 19 trials, D4/7: 14 trials
    dt_ctxt1 = dt_tmp(1:max(idx_tmp),:);
    dt_ctxt1_heat = zeros(14,18);   % 18 space bin on x-axis, 14 trials on y-axis
    
    % context2
    dt_tmp = dtCell_spaceBin{13,2};
    idx_tmp = find(dt_tmp(:,3) == 14);
    dt_ctxt2 = dt_tmp(1:max(idx_tmp),:);
    dt_ctxt2_heat = zeros(14,18);
    
    % context3
    dt_tmp = dtCell_spaceBin{13,3};
    idx_tmp = find(dt_tmp(:,3) == 14);
    dt_ctxt3 = dt_tmp(1:max(idx_tmp),:);
    dt_ctxt3_heat = zeros(14,18);
    
    cell_list= [35,43];
    for trialIter = 1:1:length(cell_list)
        for cellIter = 1:1:14
            % context1
            idx_tmp = find(dt_ctxt1(:,3) == cellIter);     % find trial#
            dt_ctxt1_heat(cellIter,:) = dt_ctxt1(idx_tmp,cell_list(trialIter)+4)';    % 8th cell: 8+4, 12th cell: 12+4, so on
            
            % context2
            idx_tmp = find(dt_ctxt2(:,3) == cellIter);
            dt_ctxt2_heat(cellIter,:) = dt_ctxt2(idx_tmp,cell_list(trialIter)+4)';
            
            % context3
            idx_tmp = find(dt_ctxt3(:,3) == cellIter);
            dt_ctxt3_heat(cellIter,:) = dt_ctxt3(idx_tmp,cell_list(trialIter)+4)';
        end
        
        % context1
        figure, imagesc(dt_ctxt1_heat); caxis([0 1]); colormap('parula');
%         xlabel('Position in VR (cm)'); ylabel('Trial');
        xticks([]); xticklabels({});
        yticks([]); yticklabels({});
%         colorbar('Ticks',[0,0.2, 0.4,0.6,0.8,1.0])
%         title([num2str(cell_list(jj)),'th cell - day4-animal1-context1'])
        
        % context2
        figure, imagesc(dt_ctxt2_heat); caxis([0 1]); colormap('parula');
%         xlabel('Position in VR (cm)'); ylabel('Trial');
        xticks([]); xticklabels({});
        yticks([]); yticklabels({});
%         colorbar('Ticks',[0,0.2, 0.4,0.6,0.8,1.0])
%         title([num2str(cell_list(jj)),'th cell - day4-animal1-context2'])
        
        % context3
        figure, imagesc(dt_ctxt3_heat); caxis([0 1]); colormap('parula');
%         xlabel('Position in VR (cm)'); ylabel('Trial');
        xticks([]); xticklabels({});
        yticks([]); yticklabels({});
%         colorbar('Ticks',[0,0.2, 0.4,0.6,0.8,1.0])
%         title([num2str(cell_list(jj)),'th cell - day4-animal1-context3'])
    end

%-----------
    
%--------- Weilun's way: heat-map bewteen 1700-(1st)1790mm range ----------%    
    % re-organization of data with different space bin(170-180cm, 1cm bin)
    % below
    
    % data rearrangement for drawing graph
    bin180_trial = [];
    bin180_trial_cell = cell(size(dataTable));
    dtCell_3timePhase = cell(size(dataTable));

    % import data and mean calculation over each bins
    for dayIter = 1:1:length(param.dayList)
        for miceIter = 1:1:length(param.miceList)
            loadingData_idx = ((dayIter-1)*length(param.miceList))+miceIter;   

            if cellSelec_also_diff_ctxt == 0
                ctxtIterEnd = 3;
            else                    % cell selection(C1>C2,C3, so on); selected cells also chose in different contexts
                ctxtIterEnd = 9;
            end

            for ctxtIter = 1:1:ctxtIterEnd
                eachData = cell2mat(dataTable(loadingData_idx,ctxtIter));   % import data from 'dataTable' - cell type

                if ~isempty(eachData)                 
                    bigTable_tmp2 = zeros(11*max(eachData(:,1)),4+size(eachData(:,5:end),2));      % temporal var. 
                    % bigTable_tmp structure:
                    % 1st col: space bin(170-180cm, 1cm bin), 2nd: context, 3rd: trial #, 4th: velocity,
                    % 5-nth: mean dF/F in cell1,..,n

                    % considering calculation of NS18 and mean(NS18)
                    for trialIter = 1:1:max(eachData(:,1))
                       binTmp = [];      % saving mean dF/F in each bin and each trial
                       for xPosIter = 1:1:length(heatMapRange2)-1
                            bigTb_idx = (trialIter-1)*(length(heatMapRange2)-1) + xPosIter;  % temporal var.
                            idxTmp = find(eachData(:,1)==trialIter & eachData(:,3)>=heatMapRange2(xPosIter) & eachData(:,3)<heatMapRange2(xPosIter+1));   
                            if ~isempty(idxTmp)
                                if isequal(xPosIter, length(heatMapRange2)-1)
                                    tableTmp = eachData(idxTmp,:);
                                    max_Xpos_idx = find(tableTmp(:,3) == max(tableTmp(:,3)));
                                    binTmp = [binTmp mean(tableTmp(1:max_Xpos_idx(1),5:end),1)'];

                                    % binTmp data structure:
                                    %                cell1                cell2    ...        cellm
                                    % trial1 | mean dF/F at bin180 | mean dF/F at bin180
                                    % trial2 | mean dF/F at bin180 | mean dF/F at bin180
                                    %  ...          .........             .........
                                    % trialn | mean dF/F at bin180 | mean dF/F at bin180
                                    bigTable_tmp2(bigTb_idx,4) = (tableTmp(max_Xpos_idx(1),3)-tableTmp(1,3)) / (tableTmp(max_Xpos_idx(1),2)-tableTmp(1,2));   % velocity = x-pos range / time interval
                                    bigTable_tmp2(bigTb_idx,5:end) = mean(tableTmp(1:max_Xpos_idx(1),5:end),1);
                                else
                                    binTmp = [binTmp mean(eachData(idxTmp,5:end),1)'];
                                    if ~isequal(length(idxTmp),1)
                                        bigTable_tmp2(bigTb_idx,4) = (eachData(idxTmp(end),3)-eachData(idxTmp(1),3)) / (eachData(idxTmp(end),2)-eachData(idxTmp(1),2)); % velocity
                                    end
                                    bigTable_tmp2(bigTb_idx,5:end) = mean(eachData(idxTmp,5:end),1);
                                end

                            else
                                binTmp = [binTmp zeros(size(eachData(:,5:end),2),1)];
                            end
                            bigTable_tmp2(bigTb_idx,1) = heatMapRange2(xPosIter);      % temporal var., space bin
                            bigTable_tmp2(bigTb_idx,2) = ctxtIter;        % context # 
                            bigTable_tmp2(bigTb_idx,3) = trialIter;       % trial #

                            % bigTable_tmp structure:
                            % 1st col: space bin(1-18), 2nd: context, 3rd: trial #, 4th: velocity

                            % binTmp data structure:
                            % i-th trial
                            % cell1 | mean dF/F at bin1 | bin2 | bin3 | ... 
                            % cell2 | mean dF/F at bin1 | bin2 | bin3 | ...
                            %  ...             ..................
                            % celln | mean dF/F at bin1 | bin2 | bin3 | ...
                       end
                    end

                    dtCell_3timePhase{loadingData_idx,ctxtIter} = bigTable_tmp2;    % temporal var.
                    bigTable_tmp2 = zeros(11*max(eachData(:,1)),4);
                end

            end
        end
    end
     
    % D4 M1 1/2/6/22/37/38/39/45th cells
    % D7 M1 1/12/23/24/25/43th cells
    
    % consider all area
    % D4 M3 2,13,16,20,25,26th cells
    % D4 M4 1,7,12,13,29,30,33,34,35,36,43th cells
    % D4 M1 2,10,13,17,18,20,22,24,34,38,39,48,49,53th cells
    %
    % D7 M3 1,2,12,19,20,35,36,43th cells
    % D7 M4 3,8,10,14,29,30,33,35,36th cells
    % D7 M1 1,5,7,11,17,18,25
    
    % context1
    % dt_tmp: 1st col: space bin, 2nd: context #, 3rd: trial #, 4th: velocity, 5th-end: cells' activity
    dt_tmp = dtCell_3timePhase{13,1};     % D4 M1: bigTable{6,1:3};, D7 M1: bigTable{11,1:3};
    idx_tmp = find(dt_tmp(:,3)<=14); % D1: 19 trials, D4/7: 14 trials
    dt_ctxt1 = dt_tmp(idx_tmp,:);
    dt_ctxt1_heat = zeros(14,10);   % # of selected cells on x-axis, 14 trials on y-axis
    
    % context2
    dt_tmp = dtCell_3timePhase{13,2};
    idx_tmp = find(dt_tmp(:,3)<=14);
    dt_ctxt2 = dt_tmp(idx_tmp,:);
    dt_ctxt2_heat = zeros(14,10);
    
    % context3
    dt_tmp = dtCell_3timePhase{13,3};
    idx_tmp = find(dt_tmp(:,3)<=14);
    dt_ctxt3 = dt_tmp(idx_tmp,:);
    dt_ctxt3_heat = zeros(14,10);
    
   % cell_tmp = [1,2,6,22,37,38,39,45];     % find cell#, day4
   % cell_tmp = [1,12,23,24,25,43];      % day7
   cell_tmp = [1,2,12,19,20,35,36,43];
    
    for cellIter = 1:1:length(cell_tmp)      % day4: 8 cells, day7: 6 cells
        for trialIter = 1:1:14
           % context1
           idx_tmp = find(trialIter==dt_ctxt1(:,3));
           dt_ctxt1_heat(trialIter,:) = dt_ctxt1(idx_tmp,cell_tmp(cellIter)+4)';    % 8th cell: 8+4, 12th cell: 12+4, so on

           % context2
           idx_tmp = find(trialIter==dt_ctxt2(:,3));
           dt_ctxt2_heat(trialIter,:) = dt_ctxt2(idx_tmp,cell_tmp(cellIter)+4)';

           % context3
           idx_tmp = find(trialIter==dt_ctxt3(:,3));
           dt_ctxt3_heat(trialIter,:) = dt_ctxt3(idx_tmp,cell_tmp(cellIter)+4)';
        end
        
        % context1
        figure, imagesc(dt_ctxt1_heat); caxis([0 1]); colormap('parula');
        xlabel('Position in VR (cm)'); ylabel('Trial'); 
        xticks([2 4 6 8 10]); xticklabels({'171','173','176','178','180'});
        colorbar('Ticks',[0,0.2, 0.4,0.6,0.8,1.0])
        title([num2str(cell_tmp(cellIter)),'th cell - day7-animal3-context1'])

        % context2
        figure, imagesc(dt_ctxt2_heat); caxis([0 1]); colormap('parula');
        xlabel('Position in VR (cm)'); ylabel('Trial'); 
        xticks([2 4 6 8 10]); xticklabels({'171','173','176','178','180'});
        colorbar('Ticks',[0,0.2, 0.4,0.6,0.8,1.0])
        title([num2str(cell_tmp(cellIter)),'th cell - day7-animal3-context2'])

        % context3
        figure, imagesc(dt_ctxt3_heat); caxis([0 1]); colormap('parula');
        xlabel('Position in VR (cm)'); ylabel('Trial'); 
        xticks([2 4 6 8 10]); xticklabels({'171','173','176','178','180'});
        colorbar('Ticks',[0,0.2, 0.4,0.6,0.8,1.0])
        title([num2str(cell_tmp(cellIter)),'th cell - day7-animal3-context3'])
    end
%-----------------   

%-----------------   DREADDs vs. DREADDs-Control heat-map

% Day4 in DREADDs: bigTable2(7:12,1:3), 7-12th row, 1-3rd column (context1,2,3)
% Day4 in DREADDs-Control: bigTable2(6:10,1:3), 6-10th row, 1-3rd column (context1,2,3)
%
% time bin in each trial is variable, therefore, find maximum time duration first
% the heat-map shows all cells and all trials for the licking time 
% making heat-map iterates for three contexts and number of animals
%
% bigTable2: 
% 1st column: time bin, 2nd: context, 3rd: trial, 4th: reward(True/False), 
% 5th: weight(2: true/1: false), 6th-end: dF/F of each cells

% cell selection has not been done in VR_Excel_Rearrangement_CellBias_combiningCells4.m
% which means, "ctxtTableAllMice{idx,ctxtItr} = ctxtTable11(:,2:end);"
% reward cell in licking time area selection is done by "load('reward_cells_licking_binaray.mat')"
                
% tb_idx = [7,12];    % day4 in DREADDs
tb_idx = [6,10];    % day4 in DREADDs-Control
trial_lim = 14;     % limitation of trial number: 14 in case of day4

load('reward_cells_licking_binaray.mat')    % only for DREADDs-Control group
     
for miceIter = tb_idx(1):1:tb_idx(2)
    % reward cell selection - day4 or day7
    % only for DREADDs-Control group
    switch miceIter
        case tb_idx(1)
            reward_cell_sel = reward_cells_licking_binaray.Day4_animal1;
        case tb_idx(1)+1
            reward_cell_sel = reward_cells_licking_binaray.Day4_animal2;
        case tb_idx(1)+2
            reward_cell_sel = reward_cells_licking_binaray.Day4_animal3;
        case tb_idx(1)+3
            reward_cell_sel = reward_cells_licking_binaray.Day4_animal4;
        case tb_idx(1)+4
            reward_cell_sel = reward_cells_licking_binaray.Day4_animal5;
    end
    
    for ctxtIter = 1:1:3
        % bigTable2 has information of licking time area
        dt_temp = dtCell_3timePhase{miceIter,ctxtIter};     % get rid of unnecessary trial info.
        dt_temp_logic = dt_temp(:,3)<= trial_lim;
        dt_temp = dt_temp(dt_temp_logic,:);
        
        % bigTable has information of all area with 10cm bin
        dt_temp2 = dtCell_spaceBin{miceIter,ctxtIter};     % get rid of unnecessary trial info.
        dt_temp_logic = dt_temp2(:,3) <= trial_lim;
        dt_temp2 = dt_temp2(dt_temp_logic,:);
        
        if isequal(ctxtIter,1)      % we are interested in context1 where reward context on Day4
        %-------- for scatter plot; 0-180cm(X1), 170-180cm(X2) vs. activity in licking time area(Y)
            cell_sel_no = length(find(reward_cell_sel));
            non_cell_sel_no = length(find(~reward_cell_sel));   % non-reward cell selection
            
            % scatter_dt:
            % 1st col: mean activity in 0-180cm(X1), 2nd: in 170-180cm(X2),
            % 3rd: in licking time area(Y)
            scatter_dt = zeros(trial_lim*cell_sel_no,3);
            non_scatter_dt = zeros(trial_lim*non_cell_sel_no,3);    % non-reward cell scatter data
            
            for trialIter = 1:1:trial_lim
                trial_logic = dt_temp(:,3) == trialIter;
                dt_temp_trial = dt_temp(trial_logic,6:end);                     % specific trial number and selected reward cells' activity
                non_dt_temp_trial = dt_temp_trial(:,~reward_cell_sel==1);       % non-reward cell
                dt_temp_trial = dt_temp_trial(:,reward_cell_sel==1);
                                
                trial_logic = dt_temp2(:,3) == trialIter;
                dt_temp_trial2 = dt_temp2(trial_logic,5:end);                   % same manner above but in all area(0-180cm) with 10cm bin
                non_dt_temp_trial2 = dt_temp_trial2(:,~reward_cell_sel==1);     % non-reward cell
                dt_temp_trial2 = dt_temp_trial2(:,reward_cell_sel==1);
                                
                anti_area_logic = (dt_temp2(:,1)==17) & trial_logic;
                dt_temp_trial3 = dt_temp2(anti_area_logic,5:end);
                non_dt_temp_trial3 = dt_temp_trial3(:,~reward_cell_sel==1);     % non-reward cell
                dt_temp_trial3 = dt_temp_trial3(:,reward_cell_sel==1);          % same manner above but anticipation area factor added(170-180cm)
                            
                scatter_idx = (trialIter-1)*cell_sel_no+1:trialIter*cell_sel_no;
                scatter_dt(scatter_idx,1) = mean(dt_temp_trial2,1)';            % mean activity in 0-180cm(X1)      
                scatter_dt(scatter_idx,2) = mean(dt_temp_trial3,1)';            % in 170-180cm(X2)
                scatter_dt(scatter_idx,3) = mean(dt_temp_trial,1)';             % in licking time area(Y)
                                
                % non-reward cell
                scatter_idx = (trialIter-1)*non_cell_sel_no+1:trialIter*non_cell_sel_no;    
                non_scatter_dt(scatter_idx,1) = mean(non_dt_temp_trial2,1)';     % mean activity in 0-180cm(X1)      
                non_scatter_dt(scatter_idx,2) = mean(non_dt_temp_trial3,1)';     % in 170-180cm(X2)
                non_scatter_dt(scatter_idx,3) = mean(non_dt_temp_trial,1)';      % in licking time area(Y)
            end
            
            figure
            scatter(scatter_dt(:,1),scatter_dt(:,3),25,'r','filled'); hold on;          % mean activity in 0-180cm(X1) and licking time area(Y) with reward cells
            scatter(scatter_dt(:,2),scatter_dt(:,3),25,'b','filled'); hold off;         % mean activity in 170-180cm(X2) and licking time area(Y) with reward cells
            title('Reward cells');
            xlim([0 2]); ylim([0 2]);
            xticks([0 0.5 1 1.5 2]); yticks([0 0.5 1 1.5 2]);
            legend('0-180cm','170-180cm')
            
%             % pearson correlation between X1 and Y, and X2 and Y
%             txt = ['mice',num2str(miceIter),'_0-180cm_correlation: ',num2str(corr(scatter_dt(:,1),scatter_dt(:,3)))];
%             disp(txt)
%             txt = ['mice',num2str(miceIter),'_170-180cm_correlation: ',num2str(corr(scatter_dt(:,2),scatter_dt(:,3)))];
%             disp(txt)
            
%             % mean activity calculation
%             txt = ['mice',num2str(miceIter),'_0-180cm_mean activity: ',num2str(mean(scatter_dt(:,1),1))];
%             disp(txt)
%             txt = ['mice',num2str(miceIter),'_170-180cm_mean activity: ',num2str(mean(scatter_dt(:,2),1))];
%             disp(txt)
%             txt = ['mice',num2str(miceIter),'_licking time area_mean activity: ',num2str(mean(scatter_dt(:,3),1))];
%             disp(txt)
                        
            figure
            scatter(non_scatter_dt(:,1),non_scatter_dt(:,3),25,'r','filled'); hold on;  % with non-reward cells
            scatter(non_scatter_dt(:,2),non_scatter_dt(:,3),25,'b','filled'); hold off; % with non-reward cells
            title('Non-Reward cells');
            xlim([0 2]); ylim([0 2]);
            xticks([0 0.5 1 1.5 2]); yticks([0 0.5 1 1.5 2]);
            legend('0-180cm','170-180cm')
            
%             % pearson correlation between X1 and Y, and X2 and Y
%             txt = ['non-reward-mice',num2str(miceIter),'_0-180cm_correlation: ',num2str(corr(non_scatter_dt(:,1),non_scatter_dt(:,3)))];
%             disp(txt)
%             txt = ['non-reward-mice',num2str(miceIter),'_170-180cm_correlation: ',num2str(corr(non_scatter_dt(:,2),non_scatter_dt(:,3)))];
%             disp(txt)
            
%             % mean activity calculation
%             txt = ['non-reward-mice',num2str(miceIter),'_0-180cm_mean activity: ',num2str(mean(non_scatter_dt(:,1),1))];
%             disp(txt)
%             txt = ['non-reward-mice',num2str(miceIter),'_170-180cm_mean activity: ',num2str(mean(non_scatter_dt(:,2),1))];
%             disp(txt)
%             txt = ['non-reward-mice',num2str(miceIter),'_licking time area_mean activity: ',num2str(mean(non_scatter_dt(:,3),1))];
%             disp(txt)
        %-------- end scatter plot
        

%             %------ for drawing heat-map
%             % lickTimeBin = 1:1:max(dt_temp(:,3));
%             [~,col] = size(dt_temp);
%             cell_no = col-5;
%             heatMap_dt = zeros(trial_lim*cell_no,max(dt_temp(:,1)));
%             % cell wise heat-map
%             for trialIter = 1:1:trial_lim
%                 trial_logic = dt_temp(:,3) == trialIter;
%                 dt_temp_trial = dt_temp(trial_logic,6:end);            
%                 [ro,~] = size(dt_temp_trial);
%                 heatMap_dt(trialIter:trial_lim:end,1:ro) = dt_temp_trial';
%             end

%             % show heat-map from 3 sec before 2nd 1790 to 3 sec duration in licking time
%             figure, imagesc(heatMap_dt(:,1:6)); colormap('parula'); caxis([0 1]);
%             xlabel('Time bin'); ylabel('Trial * Cell number');
%             xticklabels({'-3','-2','-1','lick','lick+1','lick+2'})
%             
%             % mean dF/F between 3 sec before 2nd 1790 and 3 sec duration in licking time
%             three_before_2nd1790 = mean(mean(heatMap_dt(:,1:3)));
%             three_licking = mean(mean(heatMap_dt(:,4:6)));
%             disp([num2str(three_before_2nd1790),'-',num2str(three_licking)]);
%             %------ end heat-map
            
        end
      
    end
end
%-----------------   

%% extra function - context cells distance

    % raw data is stored on disk, named 'ctxt_cell_dist_D1 M1.mat' and so on
    % data structure: 
    % 1st row: spacee bin 1-18
    % 2nd row: context number 1-3
    % 3rd row: statistically calculated result
    % eg.) space bin: 1   1  1   2   2   2  3  3  3 ...
    %      ctxt #:    1   2  3   1   2   3  1  2  3 ...
    %      stat. val: x1 x2 x3 x11 x22 x33 ...