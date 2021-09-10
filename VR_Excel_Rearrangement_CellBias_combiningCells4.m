 function [contextTtestPtg] = VR_Excel_Rearrangement_CellBias_combiningCells4()

%%

% for calculation of cell bias - T-test2 between each contexts
% Cell#  |  T-test2 between Context1 & 2(all trial)   |  Context2 & 3   |  Context1 & 3 

xPosOffset = 1700; 
param.xPos_offset = xPosOffset;

param.miceList = {'13118','13696','13775','13776','14228'}; % DREADDs-Control  % {'9485','9993','9995','10062','10065','10515'}; % DREADDs  % {'8679','8680','8682','8969','9230'}; % non-DREADDs    
param.dayList = {'day1','day4','day7'}; % DREADDs-Control % {'day1','day4','day5','day8','day9','day12','day13','day16','day17'}; % DREADDs  % {'day1','day4','day7'}; % non-DREADDs  

% variables for heat-map set
heatMapFlag = 1;                % if heatMapFlag=1 draw heat-map, =0 do not draw heat-map
xPosStart = 0;                  % user-defined range of x-position in corridor
xPosRange = 100;                 % range of x-position in corridor; this parameter is used when we draw heat-map
xPosEnd = 2000 - xPosRange;     % end range of x-position in corridor; this parameter is used when we draw heat-map
% this var. set position bin by user determined bin size (5mm/10mm/so on) 
param.heatMapRange = xPosStart:xPosRange:xPosEnd;  % heat-map range eg) bin size, start/end point
param.timeHeatMapRange = 5:-0.1:0.1;
param.ColorLimit = 1;            % color-bar magnitude limit
param.SaveImgFlag = 0;           % if SaveImgFlag is '0' Saving Images does not work
param.ColorbarFlag = 1;          % put color-bar or not
param.time_space = 0;            % time-space plot activation option
param.time_space_range = 15;     % time-space plot activation option, time [sec]
param.cellSelec_also_diff_ctxt = 0;     % cell selection(C1>C2,C3, so on); selected cells also chose in different contexts
heatMapData = cell(length(param.dayList),3);   % this struct data will store HeatMapData in different context
param.place_cells = 0;
param.place_ctxt_specific_cells = 0;
if param.place_cells
    load('place_cells.mat')
    param.place_ctxt_specific_cells = 0;
elseif param.place_ctxt_specific_cells
    load('place_ctxt_specific_cells.mat')
end

param.velocity_cells = 0;
param.vel_ctxt_specific_cells = 0;
if param.velocity_cells
    load('velocity_cells.mat')
    param.vel_ctxt_specific_cells = 0;
elseif param.vel_ctxt_specific_cells
    load('vel_ctxt_specific_cells.mat')
end

param.context_cells = 0;
if param.context_cells
   load('context_cells.mat') 
end

param.time_cells = 0;
param.time_ctxt_specific_cells = 0;
if param.time_cells
    load('time_cells.mat')
    param.time_ctxt_specific_cells = 0;
elseif param.time_ctxt_specific_cells
    load('time_ctxt_specific_cells.mat')
end


ctxtTableAllMice = cell(length(param.miceList)*length(param.dayList),3); % this cell type var. stores all data which satisfied condition
ctxtTableAllMice2 = ctxtTableAllMice; ctxtTableAllMice3 = ctxtTableAllMice; ctxtTableAllMice4 = ctxtTableAllMice;
if param.cellSelec_also_diff_ctxt == 1
    ctxtTableAllMice_diff_ctxt = cell(length(param.miceList)*length(param.dayList),9);
end

dirList = dir;      % dirList has structure data type
modeSet = 11;        % 1: normal - mean dF/F 0-1800mm, 2: spike - # of spike 0-1800mm, 3: normal S2 - mean dF/F xPosOffset(1700)-1800mm, 
                    % 4: spike S2 - # of spike xPosOffset(1700)-1800mm, 5: mean dF/F S2(xPosOffset(1700)-1800mm) > S1(0-xPosOffset(1700)), 
                    % 6: # of spike S2(xPosOffset(1700)-1800mm) > S1(0-xPosOffset(1700))
                    % 7: # of spike S2(xPosOffset(1700)-1800mm) / # of spike in whole x-pos(0-1800mm)
                    % 8: fraction of active cell - more than 0.05 calcium transients per second
                    %
                    % 11: normal considering end of x-position - mean dF/F 0-1800mm 1st 1790mm, 12: spike x-pos - # of spike 0-1800mm 1st 1790mm, 
                    % 13: normal S2 - mean dF/F xPosOffset(1700)-1800mm 1st 1790mm, 14: spike S2 x-pos: # of spike xPosOffset(1700)-1800mm 1st 1790mm
                    % 15: mean dF/F S2(xPosOffset(1700)-1800mm) > S1(0-xPosOffset(1700)) 1st 1790mm, 
                    % 16: # of spike S2(xPosOffset(1700)-1800mm) > S1(0-xPosOffset(1700)) 1st 1790mm 

compModeSet = 1;    % 1: normal - comparison C1 > (C2 & C3), so on,  2: not comparison - C1, C2, C3, 
                    % 3: comparison C1: % of S2>S1, C2: % of S2>S1, C3: % of S2>S1
                    % 4: C1>(C2+C3)/2, C2>(C1+C3)/2, C3>(C1+C2)/2 
                    % 5: comparison C1: % of sum all activity/area 200mm in S2 > sum all activity/area xPosOffset(1700) in S1, C2: % of S2>S1, C3: S2>S1
                    % 6: C1-(C2+C3)/2, C2-(C1+C3)/2, C3-(C1+C2)/2
                    % 7: (same as modeSet=7) # of spike S2(xPosOffset(1700)-1800mm) / # of spike in whole x-pos(0-1800mm)

% [modeSet, compModeSet]
% scenario1: Mean dF/F for each context(0-1800mm) (C1/C2/C3) [1,2];
% scenario2: Mean dF/F for each context(1600-1800mm) (C1/C2/C3) [3,2];
% scenario3: Spike number for each context(0-1800mm) (C1/C2/C3) [2,2];
% scenario4: Spike number for each context(1600-1800mm) (C1/C2/C3) [4,2];
% scenario5: Mean dF/F significant % (0-1800mm) (C1>C2&C3, C2>C1&C3, C3>C1&C2) [1,1];
% scenario6: Mean dF/F significant % (1600-1800mm) (C1>C2&C3, C2>C1&C3, C3>C1&C2) [3,1];
% scenario7: Mean dF/F significant % (0-1800mm) (C1>(C2+C3)/2, C2>(C1+C3)/2, C3>(C1+C2)/2) [1,4];
% scenario8: Mean dF/F significant % (0-1800mm) (C1-(C2+C3)/2, C2-(C1+C3)/2, C3-(C1+C2)/2) [1,6];
% scenario9: S2(1600-1800mm) > S1(0-1600mm) using mean dF/F for each context (C1/C2/C3) [5,3];
% scenario10: S2(1600-1800mm)/200mm > S1(0-1600mm)/1600mm using mean dF/F for each context (C1/C2/C3) [5,5];

% scenario list - 10-by-2 matrix - for batch-mode of all mice
% scenario = [1,2; 3,2; 2,2; 4,2; 1,1; 3,1; 1,4; 1,6; 5,3; 5,5];


if isequal(compModeSet,1) || isequal(compModeSet,4)
    contextTtestPtg = {'Day-cell','Context1 vs 2&3','Context2 vs 1&3','Context3 vs 1&2','Total cell number'};   % it stores percentage of significant difference between contexts
    contingencyTbl2 = contextTtestPtg;
elseif isequal(compModeSet,2) || isequal(compModeSet,7)
    contextTtestPtg = {'Day-cell','Context1','Context2','Context3','Total cell number'};
elseif isequal(compModeSet,3) || isequal(compModeSet,5)
    contextTtestPtg = {'Day-cell','S2>S1 in Context1','Context2','Context3','Total cell number'};    
elseif isequal(compModeSet,6)
    contextTtestPtg = {'Day-cell','C1-(C2+C3)/2','C2-(C1+C3)/2','C3-(C1+C2)/2','Total cell number'};    
end

if isequal(compModeSet,2) || isequal(compModeSet,6) || isequal(compModeSet,7)  % for accumulation of 'Total cell number'
   cellAcc = zeros(length(param.dayList),1); 
end

if isequal(modeSet,8)
   actCellTable = {'Day','miceID','active cell % in C1','in C2','in C3','total cell #'}; 
   actCell_idx = 1;
   actCellTable2 = {'Day','miceID','active cell %','total cell #'}; 
   actCell_idx2 = 1;
end
compBinListAllMice = []; compPvalueListAllMice = []; compMeanEachCtxt = [];
compBinListAllMiceTable = cell(length(param.dayList),3);
ctxtMeanAllTrialTable = cell(length(param.dayList),3); 
ctxtMeanAllTrialTable_S1 = cell(length(param.dayList),3); 

for dayIter = 1:1:length(param.dayList)
    % temporal for time-space graphs
    if param.time_space == 1
        listTimeSpaceHeatMap1 = []; listTimeSpaceHeatMap2 = []; listTimeSpaceHeatMap3 = [];
    end
    
    for miceIter =1:1:length(param.miceList)
        
        % finding & loading initial data from current path
        fileNameTemp = [param.miceList{miceIter},'-',param.dayList{dayIter},'-new DataInte.mat']; % [param.miceList{miceIter},'-',param.dayList{dayIter},'-common-cell-across-days-DataInte.mat']; 
        tempVar = [];
        for dirIter = 1:1:size(dirList,1)   % finding fileName in structure
            tempVar = [tempVar; strcmp(fileNameTemp,dirList(dirIter).name)];
        end
                
        % if there is loaded file, then run code below, if not skip it
        if ~isempty(find(tempVar))
            tempLoadData = load(fileNameTemp);
            DataInte = tempLoadData.DataInte;
                
            ctxtCol = 5; %find(strcmpi(DataInte(1,:),'Context'));
            timeCol = 8; %find(strcmpi(DataInte(1,:),'Times(s)'));
            trialCol = 7; %find(strcmpi(DataInte(1,:),'Trial #'));
            posCol = 9; %find(strcmpi(DataInte(1,:),'Position(mm)'));
            velCol = 10; 
            cellCol = 13; %find(strcmpi(DataInte(1,:),'cell1'));
            
%             % if it is necessary, normalize input data
%             min_max_scaling_func = @(x) (x-min(x))/(max(x)-min(x));     % min_max_scaling
%             for cellIter = cellCol:2:size(DataInte,2)
%                 DataInte(2:end,cellIter) = num2cell(min_max_scaling_func(cell2mat(DataInte(2:end,cellIter))));
%             end
                        
            % in case of mean dF/F: "cellCol:2:length(DataInte(1,:))"
            % in case of spike #: "cellCol+1:2:length(DataInte(1,:))"
            if isequal(modeSet,1) || isequal(modeSet,3) || isequal(modeSet,5) || isequal(modeSet,11) || isequal(modeSet,13) || isequal(modeSet,15)
                importColList = [ctxtCol, trialCol, timeCol, posCol, velCol, cellCol:2:length(DataInte(1,:))];
            elseif isequal(modeSet,2) || isequal(modeSet,4) || isequal(modeSet,6) || isequal(modeSet,7) || isequal(modeSet,12) || isequal(modeSet,14) || isequal(modeSet,16)
                importColList = [ctxtCol, trialCol, timeCol, posCol, velCol, cellCol+1:2:length(DataInte(1,:))];
            elseif isequal(modeSet,8)
                importColList = [ctxtCol, trialCol, timeCol, posCol, velCol, cellCol:length(DataInte(1,:))];
            end
            txtTmp = [param.miceList{miceIter},'-',param.dayList{dayIter}];
           
            
%             % plot raw signal, position, and velocity together
%             % param.miceList = {'13118','13696','13775','13776','14228'};
%             if isequal(dayIter,1) & isequal(miceIter,1)
%                 param_rawSignal_Pos_Speed.xPosOffset = xPosOffset;
%                 param_rawSignal_Pos_Speed.timeCol = timeCol;
%                 param_rawSignal_Pos_Speed.posCol = posCol;
%                 param_rawSignal_Pos_Speed.spdCol = velCol;
%                 param_rawSignal_Pos_Speed.cellCol = cellCol;
%                 param_rawSignal_Pos_Speed.figure_show = 1;                   % show diagram in the end(True=1) or not(False=0)?
%                 param_rawSignal_Pos_Speed.figure_show_axisOff = 0;           % show axis off images
%             
%                 [bigData_tbl] = rawSignal_Pos_Speed(DataInte,param_rawSignal_Pos_Speed);
%             end
            
            
            if isequal(modeSet, 8)
                dTable_modeSet8 = cell2mat(DataInte(2:end,importColList));
                % dTable_modeSet8:
                % 1st col: context, 2nd col: trial#, 3rd col: time, 4th col: x-pos, 5th col: velocity,
                % 6th col: dF/F in cell1, 7th col: spike # in cell1, 8th: dF/F in cell2, 9th: spike # in cell2, so on

                data_tmp = sum(dTable_modeSet8(:,7:2:end),1);                                   % calcium transient is expressed by '1' each row in ctxtTable
                data_tmp = data_tmp / (dTable_modeSet8(end,3)-dTable_modeSet8(1,3));     % calcium transient / time interval all cells
                data_tmp = data_tmp >= 0.05;           % selection active cells; (calcium activity/time duration) >= 0.05  
                actCellTable2{actCell_idx2+1,1} = param.dayList{dayIter};
                actCellTable2{actCell_idx2+1,2} = param.miceList{miceIter};
                actCellTable2{actCell_idx2+1,3} = length(find(data_tmp)) / length(data_tmp) * 100;
                actCellTable2{actCell_idx2+1,4} = length(data_tmp);
                actCell_idx2 = actCell_idx2 + 1;
            end
            
            for ctxtItr = 1:1:3
                % search for information of corresponding context#  
                % 5th col: context number
                ctxtIdx = find(cell2mat(DataInte(2:end,5))== ctxtItr);
                
                % ctxtTableN:
                % 1st col: context, 2nd col: trial#, 3rd col: time, 4th col: x-pos, 5th col: velocity, 
                % 6th col: dF/F(or spike #) in cell1, 7th col: dF/F(or spike #) in cell2, so on
                % this variable returns data in user-defined x-position range
                % on the other hand, ctxtTable11/22/33 return data in whole x-position range
                switch ctxtItr
                    case 1
                        ctxtTable1 = [];
                        temp_dt = DataInte(ctxtIdx+1,importColList);
                        for iter = 1:1:size(temp_dt,2)
                            ctxtTable1(:,iter) = double(cell2mat(temp_dt(:,iter)));
                        end
                        %ctxtTable1 = cell2mat(DataInte(ctxtIdx+1,importColList));
                                                
                        if isequal(modeSet,5) || isequal(modeSet,6)|| isequal(modeSet,7) || isequal(modeSet,15) || isequal(modeSet,16)
                            [ctxtTable1,ctxtTable1_S1] = xPos_set(ctxtTable1,modeSet,xPosOffset);       % when modeSet = 7, ctxtTable_S1 has range of 0-1800mm, not 0-1700mm
                        elseif ~isequal(modeSet,1) && ~isequal(modeSet,2) && ~isequal(modeSet,8)      % in case of modeSet: 3,4,11,12,13,14
                            % 'ctxtTable11' is independent from 'modeSet' whether its range 1700mm or 0-1800mm
                            [ctxtTable1,~,ctxtTable11] = xPos_set(ctxtTable1,modeSet,xPosOffset);
                        elseif isequal(modeSet,8)
                            % temporal for modeSet 8 - active cell selection 
                            % [ctxtTable1,~,ctxtTable11] = xPos_set(ctxtTable1,modeSet,xPosOffset); % usable in condition of different position after 1700mm
                            [~,~,ctxtTable11] = xPos_set(ctxtTable1,modeSet,xPosOffset);
                        elseif isequal(modeSet,1) 
                            [~,~,ctxtTable11] = xPos_set(ctxtTable1,modeSet,xPosOffset);
                        end
                        
                        % heat-map treatment
                        if isequal(heatMapFlag,1)
                            % give specific scenario set here, if isequal(modeSet
                            param.context = ctxtItr;       % which context
                            param.day = dayIter;            % which day
                            param.dataAccType = 1;  % data access type in data table; the type depends on data structure in different program
                            [heatMapData] = VR_Excel_Rearrangement_HeatMapCal(param,ctxtTable1,heatMapData);
                        end
                        
                        % 'ctxtMeanList' includes mean of each trial in accumulation: # of trial-by-# of cells
                        % 'ctxtMeanAllTrial' returns mean of all trials in each cells: 1-by-# of cells
                        % cf) if 'modeSet' is 5, then 'ctxtMeanAllTrial' returns mean of all trials in each cells only in S2 area
                        % 'ctxtMeanAllTrial_S1' returns mean of all trials in each cells only in S1 area: 1-by-# of cells
                        if ~isequal(modeSet,5) && ~isequal(modeSet,8) && ~isequal(modeSet,15) && ~isequal(modeSet,6) && ~isequal(modeSet,16) && ~isequal(modeSet,7)        % in case of modeSet: 1,2,3,4,11,12,13,14
                            if isequal(param.time_space,0)
                                [ctxtMeanList1, ctxtMeanAllTrial1] = trialFcn(ctxtTable1); 
                            else
                                [ctxtMeanList1, ctxtMeanAllTrial1,~,~,timeSpaceHeatMap1] = trialFcn(ctxtTable1,[],param.time_space,param.time_space_range);  % temporal for time-space graphs
                            end
                        elseif isequal(modeSet,8)
                            % temporal for modeSet 8 - active cell selection 
                            [ctxtMeanList1, ctxtMeanAllTrial1] = trialFcn(ctxtTable1,'modeSet8');
                        else
                            [ctxtMeanList1,ctxtMeanAllTrial1,ctxtMeanList1_S1,ctxtMeanAllTrial1_S1] = trialFcn(ctxtTable1,ctxtTable1_S1,compModeSet);
                            paramStruct1 = struct('ctxtMeanList1',ctxtMeanList1,'ctxtMeanList1_S1',ctxtMeanList1_S1,...
                                'ctxtMeanAllTrial1',ctxtMeanAllTrial1,'ctxtMeanAllTrial1_S1',ctxtMeanAllTrial1_S1,'xPosOffset',xPosOffset);
                        end
                        
                    case 2
                        ctxtTable2 = [];
                        temp_dt = DataInte(ctxtIdx+1,importColList);
                        for iter = 1:1:size(temp_dt,2)
                            ctxtTable2(:,iter) = double(cell2mat(temp_dt(:,iter)));
                        end
                        
                        %ctxtTable2 = cell2mat(DataInte(ctxtIdx+1,importColList));
                        
                        if isequal(modeSet,5) || isequal(modeSet,6) || isequal(modeSet,7) || isequal(modeSet,15) || isequal(modeSet,16)
                            [ctxtTable2,ctxtTable2_S1] = xPos_set(ctxtTable2,modeSet,xPosOffset);       % when modeSet = 7, ctxtTable_S1 has range of 0-1800mm, not 0-1700mm
                        elseif ~isequal(modeSet,1) && ~isequal(modeSet,2) && ~isequal(modeSet,8)
                            % 'ctxtTable22' is independent from 'modeSet' whether its range 1700mm or 0-1800mm
                            [ctxtTable2,~,ctxtTable22] = xPos_set(ctxtTable2,modeSet,xPosOffset);
                        elseif isequal(modeSet,8)
                            % temporal for modeSet 8 - active cell selection 
                            % [ctxtTable2,~,ctxtTable22] = xPos_set(ctxtTable2,modeSet,xPosOffset); % usable in condition of different position after 1700mm
                            [~,~,ctxtTable22] = xPos_set(ctxtTable2,modeSet,xPosOffset);
                        elseif isequal(modeSet,1) 
                            [~,~,ctxtTable22] = xPos_set(ctxtTable2,modeSet,xPosOffset);
                        end
                        
                        % heat-map treatment
                        if isequal(heatMapFlag,1)
                            % give specific scenario set here, if isequal(modeSet
                            param.context = ctxtItr;       % which context
                            param.day = dayIter;            % which day
                            [heatMapData] = VR_Excel_Rearrangement_HeatMapCal(param,ctxtTable2,heatMapData);
                        end
                        
                        if ~isequal(modeSet,5) && ~isequal(modeSet,8) && ~isequal(modeSet,15) && ~isequal(modeSet,6) && ~isequal(modeSet,16) && ~isequal(modeSet,7)
                            if isequal(param.time_space,0)
                                [ctxtMeanList2, ctxtMeanAllTrial2] = trialFcn(ctxtTable2);
                            else
                                [ctxtMeanList2, ctxtMeanAllTrial2,~,~,timeSpaceHeatMap2] = trialFcn(ctxtTable2,[],param.time_space,param.time_space_range);  % temporal for time-space graphs
                            end
                        elseif isequal(modeSet,8)
                            % temporal for modeSet 8 - active cell selection 
                            [ctxtMeanList2, ctxtMeanAllTrial2] = trialFcn(ctxtTable2,'modeSet8');
                        else
                            [ctxtMeanList2,ctxtMeanAllTrial2,ctxtMeanList2_S1,ctxtMeanAllTrial2_S1] = trialFcn(ctxtTable2,ctxtTable2_S1,compModeSet);
                            paramStruct2 = struct('ctxtMeanList2',ctxtMeanList2,'ctxtMeanList2_S1',ctxtMeanList2_S1,...
                                'ctxtMeanAllTrial2',ctxtMeanAllTrial2,'ctxtMeanAllTrial2_S1',ctxtMeanAllTrial2_S1,'xPosOffset',xPosOffset);
                        end
                        
                    case 3
                        ctxtTable3 = [];
                        temp_dt = DataInte(ctxtIdx+1,importColList);
                        for iter = 1:1:size(temp_dt,2)
                            ctxtTable3(:,iter) = double(cell2mat(temp_dt(:,iter)));
                        end
                        
                        % ctxtTable3 = cell2mat(DataInte(ctxtIdx+1,importColList));
                        
                        if isequal(modeSet,5) || isequal(modeSet,6) || isequal(modeSet,7) || isequal(modeSet,15) || isequal(modeSet,16)
                            [ctxtTable3,ctxtTable3_S1] = xPos_set(ctxtTable3,modeSet,xPosOffset);       % when modeSet = 7, ctxtTable_S1 has range of 0-1800mm, not 0-1700mm
                        elseif ~isequal(modeSet,1) && ~isequal(modeSet,2) && ~isequal(modeSet,8)
                            % 'ctxtTable33' is independent from 'modeSet' whether its range 1700mm or 0-1800mm
                            [ctxtTable3,~,ctxtTable33] = xPos_set(ctxtTable3,modeSet,xPosOffset);
                        elseif isequal(modeSet,8)
                            % temporal for modeSet 8 - active cell selection 
                            % [ctxtTable3,~,ctxtTable33] = xPos_set(ctxtTable3,modeSet,xPosOffset); % usable in condition of different position after 1700mm
                            [~,~,ctxtTable33] = xPos_set(ctxtTable3,modeSet,xPosOffset);
                        elseif isequal(modeSet,1) 
                            [~,~,ctxtTable33] = xPos_set(ctxtTable3,modeSet,xPosOffset);    
                        end
                        
                        % heat-map treatment
                        if isequal(heatMapFlag,1)
                            % give specific scenario set here, if isequal(modeSet
                            param.context = ctxtItr;       % which context
                            param.day = dayIter;            % which day
                            [heatMapData] = VR_Excel_Rearrangement_HeatMapCal(param,ctxtTable3,heatMapData);
                        end
                        
                        if ~isequal(modeSet,5) && ~isequal(modeSet,8) && ~isequal(modeSet,15) && ~isequal(modeSet,6) && ~isequal(modeSet,16) && ~isequal(modeSet,7)
                            if isequal(param.time_space,0)
                                [ctxtMeanList3, ctxtMeanAllTrial3] = trialFcn(ctxtTable3);
                            else
                                [ctxtMeanList3, ctxtMeanAllTrial3,~,~,timeSpaceHeatMap3] = trialFcn(ctxtTable3,[],param.time_space,param.time_space_range);  % temporal for time-space graphs
                            end
                        elseif isequal(modeSet,8)
                            % temporal for modeSet 8 - active cell selection 
                            [ctxtMeanList3, ctxtMeanAllTrial3] = trialFcn(ctxtTable3,'modeSet8');    
                        else
                            [ctxtMeanList3,ctxtMeanAllTrial3,ctxtMeanList3_S1,ctxtMeanAllTrial3_S1] = trialFcn(ctxtTable3,ctxtTable3_S1,compModeSet);
                            paramStruct3 = struct('ctxtMeanList3',ctxtMeanList3,'ctxtMeanList3_S1',ctxtMeanList3_S1,...
                                'ctxtMeanAllTrial3',ctxtMeanAllTrial3,'ctxtMeanAllTrial3_S1',ctxtMeanAllTrial3_S1,'xPosOffset',xPosOffset);
                        end    
                end
                
            end
            
            if isequal(modeSet,8)
                actCellTable{actCell_idx+1,1} = param.dayList{dayIter};
                actCellTable{actCell_idx+1,2} = param.miceList{miceIter};
                actCellTable{actCell_idx+1,3} = length(find(ctxtMeanAllTrial1)) / length(ctxtMeanAllTrial1) * 100;
                actCellTable{actCell_idx+1,4} = length(find(ctxtMeanAllTrial2)) / length(ctxtMeanAllTrial2) * 100;
                actCellTable{actCell_idx+1,5} = length(find(ctxtMeanAllTrial3)) / length(ctxtMeanAllTrial3) * 100;
                actCellTable{actCell_idx+1,6} = length(ctxtMeanAllTrial1);
                actCell_idx = actCell_idx + 1;
            end
            
            % for calculation of cumulative probabilities
            ctxtMeanAllTrialTable{dayIter,1} = [ctxtMeanAllTrialTable{dayIter,1}; ctxtMeanAllTrial1'];
            ctxtMeanAllTrialTable{dayIter,2} = [ctxtMeanAllTrialTable{dayIter,2}; ctxtMeanAllTrial2'];
            ctxtMeanAllTrialTable{dayIter,3} = [ctxtMeanAllTrialTable{dayIter,3}; ctxtMeanAllTrial3'];
%             if isequal(modeSet,5) || isequal(modeSet,15)
%                 ctxtMeanAllTrialTable_S1{dayIter,1} = [ctxtMeanAllTrialTable_S1{dayIter,1}; ctxtMeanAllTrial1_S1'];
%                 ctxtMeanAllTrialTable_S1{dayIter,2} = [ctxtMeanAllTrialTable_S1{dayIter,2}; ctxtMeanAllTrial2_S1'];
%                 ctxtMeanAllTrialTable_S1{dayIter,3} = [ctxtMeanAllTrialTable_S1{dayIter,3}; ctxtMeanAllTrial3_S1'];
%             end
            
            % temporal for time-space graphs
            if param.time_space == 1
                listTimeSpaceHeatMap1 = [listTimeSpaceHeatMap1; timeSpaceHeatMap1];
                listTimeSpaceHeatMap2 = [listTimeSpaceHeatMap2; timeSpaceHeatMap2];
                listTimeSpaceHeatMap3 = [listTimeSpaceHeatMap3; timeSpaceHeatMap3];
            end
            
            
            if isequal(compModeSet,1) || isequal(compModeSet,3) || isequal(compModeSet,4) || isequal(compModeSet,5)
                
                if isequal(compModeSet,1) || isequal(compModeSet,4)
                    % 3 scenarios to compare 
                    % 1) % of cells which are significantly (p<0.05) more active in context1 as compared to both context2 and context3
                    % 2) % of cells which are significantly more active in context2 as compared to both context1 and context3
                    % 3) % of cells which are significantly more active in context3 as compared to both context1 and context2
                    [compBinListEachMice,compPvalueListEachMice] = comparison(ctxtMeanList1,ctxtMeanList2,ctxtMeanList3,...
                                                                ctxtMeanAllTrial1,ctxtMeanAllTrial2,ctxtMeanAllTrial3,txtTmp,compModeSet);
                    % compBinListEachMice: # of cell-by-3(context1 vs 2&3, context2 vs 1&3, context3 vs 1&2
                    % compPvalueListEachMice: # of cell-by-6(p-value of ttest2 between context1 & 2, 1&3, 2&1, 2&3, so on. 
            
                elseif isequal(compModeSet,3) || isequal(compModeSet,5)
                    % compare three contexts using % of S2(1600-1800mm) > S1(0-1600mm) with mean dF/F
                    [compBinListEachMice,compPvalueListEachMice] = comparison3(paramStruct1,paramStruct2,paramStruct3,txtTmp,compModeSet);  
                    
                    % compBinListEachMice: # of cell-by-3(context1,context2, context3)
                    % compPvalueListEachMice: # of cell-by-3(p-value of ttest2 between S2(1600-1800mm) and S1(0-1600mm) in context1, in context2, in context3 
                end
                                
                % ctxtTableN:     % most activated cells selection
                % 1st col: context, 2nd col: trial#, 3rd col: time, 4th col: x-pos, 5th col: velocity, 
                % 6th col: dF/F(or spike #) in cell1, 7th col: dF/F(or spike #) in cell2, so on
                % this variable returns data in user-defined x-position range
                % on the other hand, ctxtTable11/22/33 return data in whole x-position range
                %
                % 'ctxtTableAllMice' has information of selected cells, whereas 'ctxtTableAllMice2' has all cells.
                % 'ctxtTableAllMice3' has the same cells but from different contexts
                % ctxtTableAllMice, ctxtTableAllMice2, ctxtTableAllMice3:
                % if there are 5 mice, then 5 rows depict 5 mice in a day; 
                % from next 5 rows depict 5 mice in another day.
                % 1st col: 1st context, 2nd col: 2nd context, 3rd col: 3rd context
                idx = ((dayIter-1)*length(param.miceList))+miceIter;    % idx for 'ctxtTableAllMice'
                                
                for ctxtItr = 1:1:3
                    selCellNo = find(compBinListEachMice(:,ctxtItr));   % if the condition is satisfied (eg. C1 > C2&C3), those cells were selected
                    if param.place_cells
                       selCellNo = find(place_cells{dayIter,miceIter}(:,ctxtItr));
                    elseif param.place_ctxt_specific_cells
                       selCellNo = find(place_ctxt_specific_cells{dayIter,miceIter}(:,ctxtItr));
                    end
                      
                    if param.velocity_cells
                       selCellNo = find(velocity_cells{dayIter,miceIter}(:,ctxtItr));
                    elseif param.vel_ctxt_specific_cells
                       selCellNo = find(vel_ctxt_specific_cells{dayIter,miceIter}(:,ctxtItr));
                    end
                    
                    if param.context_cells
                       selCellNo = find(context_cells{dayIter,miceIter});  % cf.) context cells are context free 
                    end
                    
                    if param.time_cells
                       selCellNo = find(time_cells{dayIter,miceIter}(:,ctxtItr));
                    elseif param.time_ctxt_specific_cells
                       selCellNo = find(time_ctxt_specific_cells{dayIter,miceIter}(:,ctxtItr));
                    end
                    
                    % 'ctxtTable11' is independent from 'modeSet' whether its range 1700mm or 0-1800mm
                    %if ~isempty(selCellNo)
                        switch ctxtItr
                            case 1
                                % we need data of 'Trial #', 'Time', 'X-pos', 'Velocity', and 'Selected cells' dF/F'
                                % we give corresponding column number above in 'ctxtTable'
                                % 'ctxtTableAllMice' has information of selected cells, 
                                if param.cellSelec_also_diff_ctxt == 0
                                    ctxtTableAllMice{idx,ctxtItr} = ctxtTable11(:,2:end); % ctxtTable11(:,[2:5,selCellNo'+5]); % 
                                else        % cell selection(C1>C2,C3, so on); selected cells also chose in different contexts
                                    ctxtTableAllMice_diff_ctxt{idx,ctxtItr} = ctxtTable11(:,[2:5,selCellNo'+5]);  % ctxtTable11(:,2:end); 
                                    ctxtTableAllMice_diff_ctxt{idx,ctxtItr+1} = ctxtTable22(:,[2:5,selCellNo'+5]); % ctxtTable22(:,2:end);      
                                    ctxtTableAllMice_diff_ctxt{idx,ctxtItr+2} = ctxtTable33(:,[2:5,selCellNo'+5]); % ctxtTable33(:,2:end);  
                                end
                                
                            case 2
                                if param.cellSelec_also_diff_ctxt == 0
                                    ctxtTableAllMice{idx,ctxtItr} = ctxtTable22(:,2:end); % ctxtTable22(:,[2:5,selCellNo'+5]); %  
                                else        % cell selection(C1>C2,C3, so on); selected cells also chose in different contexts
                                    ctxtTableAllMice_diff_ctxt{idx,ctxtItr+2} = ctxtTable11(:,[2:5,selCellNo'+5]); % ctxtTable11(:,2:end); 
                                    ctxtTableAllMice_diff_ctxt{idx,ctxtItr+3} = ctxtTable22(:,[2:5,selCellNo'+5]); % ctxtTable22(:,2:end); 
                                    ctxtTableAllMice_diff_ctxt{idx,ctxtItr+4} = ctxtTable33(:,[2:5,selCellNo'+5]); % ctxtTable33(:,2:end);  
                                end

                            case 3
                                if param.cellSelec_also_diff_ctxt == 0
                                    ctxtTableAllMice{idx,ctxtItr} = ctxtTable33(:,2:end); % ctxtTable33(:,[2:5,selCellNo'+5]); % 
                                else        % cell selection(C1>C2,C3, so on); selected cells also chose in different contexts
                                    ctxtTableAllMice_diff_ctxt{idx,ctxtItr+4} = ctxtTable11(:,[2:5,selCellNo'+5]);  % ctxtTable11(:,2:end); 
                                    ctxtTableAllMice_diff_ctxt{idx,ctxtItr+5} = ctxtTable22(:,[2:5,selCellNo'+5]);  % ctxtTable22(:,2:end); 
                                    ctxtTableAllMice_diff_ctxt{idx,ctxtItr+6} = ctxtTable33(:,[2:5,selCellNo'+5]);  % ctxtTable33(:,2:end); 
                                end
                        end
                        
                        % we need data of 'X-pos' and 'Selected cells' dF/F'
                        % 'heatMapData' has 1-by-# of heatMapData bins
                        heatMapData11 = HeatMapData_Arrangement(param, ctxtTable11(:,[4,selCellNo'+5]));
                        heatMapData22 = HeatMapData_Arrangement(param, ctxtTable22(:,[4,selCellNo'+5]));
                        heatMapData33 = HeatMapData_Arrangement(param, ctxtTable33(:,[4,selCellNo'+5]));
                        ctxtTableAllMice3{idx,ctxtItr} = [heatMapData11;heatMapData22;heatMapData33];
                    %end
                    
                    switch ctxtItr
                        case 1
                            % we need data of 'Trial #', 'Time', 'X-pos', 'Velocity', and 'All cells' dF/F'
                            % we give corresponding column number above in 'ctxtTable'
                            % whereas 'ctxtTableAllMice2' has all cells
                            ctxtTableAllMice2{idx,ctxtItr} = ctxtTable11(:, 2:end);
                        case 2
                            ctxtTableAllMice2{idx,ctxtItr} = ctxtTable22(:, 2:end);
                        case 3
                            ctxtTableAllMice2{idx,ctxtItr} = ctxtTable33(:, 2:end);
                    end
                    
                end
                                
                % compBinListAllMice accumulates compBinListEachMice data in a
                % matrix, and it compose a single day data
                compBinListAllMice = [compBinListAllMice; compBinListEachMice]; 
                compPvalueListAllMice = [compPvalueListAllMice; compPvalueListEachMice];
                
            elseif isequal(compModeSet,2) || isequal(compModeSet,6) || isequal(compModeSet,7)   % when compModeSet=7, we are only interested in variables of 'ctxtMeanList' & 'ctxtMeanAllTrial' 
                % only 1 scenario to compare
                % compare three contexts using mean value of each contexts,
                % eg)mean value in context1 / context2 / context3
                if isequal(compModeSet,2) || isequal(compModeSet,7)
                    compMeanEachCtxt = [compMeanEachCtxt; mean(ctxtMeanAllTrial1(:),'omitnan'), mean(ctxtMeanAllTrial2(:),'omitnan'), mean(ctxtMeanAllTrial3(:),'omitnan')];
                end
                                
                if isequal(compModeSet,6)
                    % mean dF/F. C1 - (C2+C3)/2, C2 - (C1+C3)/2, C3 - (C1+C2)/2
                    tempMean1 = mean(ctxtMeanAllTrial1(:),'omitnan'); tempMean2 = mean(ctxtMeanAllTrial2(:),'omitnan'); tempMean3 = mean(ctxtMeanAllTrial3(:),'omitnan');
                    tempCtxt1 = tempMean1 - (tempMean2+tempMean3)/2;
                    tempCtxt2 = tempMean2 - (tempMean1+tempMean3)/2;
                    tempCtxt3 = tempMean3 - (tempMean1+tempMean2)/2;
                    compMeanEachCtxt = [compMeanEachCtxt; tempCtxt1, tempCtxt2, tempCtxt3];
                    clear tempMean1 tempMean2 tempMean3 tempCtxt1 tempCtxt2 tempCtxt3
                end
                
                cellAcc(dayIter,1) = cellAcc(dayIter,1) + size(ctxtMeanAllTrial1,2);
            end
            
        end
    end

    % temporal for time-space graphs
    if param.time_space == 1
        % normalization of listTimeSpaceHeatMap1 - normalization using max
        % value on each row, then 40% rescaling for caxis(0-0.5)
        max_listTimeSpaceHeatMap1 = max(listTimeSpaceHeatMap1,[],2);
        listTimeSpaceHeatMap1 = (listTimeSpaceHeatMap1 ./ max_listTimeSpaceHeatMap1) .* 0.4;
        listTimeSpaceHeatMap1 = cell_sorting(listTimeSpaceHeatMap1);
                
        figure
        imagesc(listTimeSpaceHeatMap1(:,1:end-1));
        caxis([0 0.5]);
        colormap(jet);
        fig = gca;
        switch param.time_space_range
            case 5
                fig.XTickLabel = {'-4','-3','-2','-1','0'}; % -5 ~ 0 sec
            case 10
                fig.XTickLabel = {'-8','-6','-4','-2','0'}; % -10 ~ 0 sec
            case 15
                fig.XTickLabel = {'-12','-9','-6','-3','0'}; % -15 ~ 0 sec
            case 20
                fig.XTickLabel = {'-16','-12','-8','-4','0'}; % -20 ~ 0 sec
            case 30
                fig.XTickLabel = {'-24','-18','-12','-6','0'}; % -30 ~ 0 sec
        end
        
        xlabel('time (sec.)');
        ylabel('trials from all mice'); % ylabel('mice * trials comb.'); 
        title(['Time-Space Heat-map -',param.dayList{dayIter},' - context1']);
        colorbar('Ticks',[0,0.1,0.2,0.3,0.4,0.5])
%         if SaveImgFlag
%             filename = [DayFlag,'-Context1-fluorescence.tif'];
%             saveas(fig,filename);
%         end 
        
        % normalization of listTimeSpaceHeatMap2
        max_listTimeSpaceHeatMap2 = max(listTimeSpaceHeatMap2,[],2);
        listTimeSpaceHeatMap2 = (listTimeSpaceHeatMap2 ./ max_listTimeSpaceHeatMap2) .* 0.4;
        listTimeSpaceHeatMap2 = cell_sorting(listTimeSpaceHeatMap2);
                
        figure
        imagesc(listTimeSpaceHeatMap2(:,1:end-1));
        caxis([0 0.5]);
        colormap(jet);
        fig = gca;
        switch param.time_space_range
            case 5
                fig.XTickLabel = {'-4','-3','-2','-1','0'}; % -5 ~ 0 sec
            case 10
                fig.XTickLabel = {'-8','-6','-4','-2','0'}; % -10 ~ 0 sec
            case 15
                fig.XTickLabel = {'-12','-9','-6','-3','0'}; % -15 ~ 0 sec
            case 20
                fig.XTickLabel = {'-16','-12','-8','-4','0'}; % -20 ~ 0 sec
            case 30
                fig.XTickLabel = {'-24','-18','-12','-6','0'}; % -30 ~ 0 sec
        end        
        
        xlabel('time (sec.)');
        ylabel('trials from all mice'); % ylabel('mice * trials comb.'); 
        title(['Time-Space Heat-map -',param.dayList{dayIter},' - context2']);
        colorbar('Ticks',[0,0.1,0.2,0.3,0.4,0.5])
        
        
        % normalization of listTimeSpaceHeatMap3
        max_listTimeSpaceHeatMap3 = max(listTimeSpaceHeatMap3,[],2);
        listTimeSpaceHeatMap3 = (listTimeSpaceHeatMap3 ./ max_listTimeSpaceHeatMap3) .* 0.4;
        listTimeSpaceHeatMap3 = cell_sorting(listTimeSpaceHeatMap3);
        
        figure
        imagesc(listTimeSpaceHeatMap3(:,1:end-1));
        caxis([0 0.5]);
        colormap(jet);
        fig = gca;
        switch param.time_space_range
            case 5
                fig.XTickLabel = {'-4','-3','-2','-1','0'}; % -5 ~ 0 sec
            case 10
                fig.XTickLabel = {'-8','-6','-4','-2','0'}; % -10 ~ 0 sec
            case 15
                fig.XTickLabel = {'-12','-9','-6','-3','0'}; % -15 ~ 0 sec
            case 20
                fig.XTickLabel = {'-16','-12','-8','-4','0'}; % -20 ~ 0 sec
            case 30
                fig.XTickLabel = {'-24','-18','-12','-6','0'}; % -30 ~ 0 sec
        end
        
        xlabel('time (sec.)');
        ylabel('trials from all mice'); % ylabel('mice * trials comb.'); 
        title(['Time-Space Heat-map -',param.dayList{dayIter},' - context3']);
        colorbar('Ticks',[0,0.1,0.2,0.3,0.4,0.5])
        
    end
    
    
    
    if isequal(compModeSet,1) || isequal(compModeSet,3) || isequal(compModeSet,4) || isequal(compModeSet,5)
        contextTtestPtg{dayIter+1,1} = param.dayList{dayIter};
        contextTtestPtg{dayIter+1,2} = length(find(compBinListAllMice(:,1))) / length(compBinListAllMice(:,1)) * 100;
        contextTtestPtg{dayIter+1,3} = length(find(compBinListAllMice(:,2))) / length(compBinListAllMice(:,2)) * 100;
        contextTtestPtg{dayIter+1,4} = length(find(compBinListAllMice(:,3))) / length(compBinListAllMice(:,3)) * 100;
        contextTtestPtg{dayIter+1,5} = length(compBinListAllMice(:,1));

        % # of selected cells in each contexts in each days
        compBinListAllMiceTable{dayIter,1} = length(find(compBinListAllMice(:,1)));   % here data depicts how many times given condition satisfied in context1
        compBinListAllMiceTable{dayIter,2} = length(find(compBinListAllMice(:,2)));   % in context2
        compBinListAllMiceTable{dayIter,3} = length(find(compBinListAllMice(:,3)));   % in context3
        compBinListAllMice = [];        % this var. must be initialized 
        compPvalueListAllMice = [];     % this var. must be initialized
    
    elseif isequal(compModeSet,2) || isequal(compModeSet,6) || isequal(compModeSet,7)
        compMeanEachCtxtAllMice = mean(compMeanEachCtxt,'omitnan');
        
        contextTtestPtg{dayIter+1,1} = param.dayList{dayIter};
        contextTtestPtg{dayIter+1,2} = compMeanEachCtxtAllMice(1);
        contextTtestPtg{dayIter+1,3} = compMeanEachCtxtAllMice(2);
        contextTtestPtg{dayIter+1,4} = compMeanEachCtxtAllMice(3);
        contextTtestPtg{dayIter+1,5} = cellAcc(dayIter,1);
        
        compMeanEachCtxt = [];          % this var. must be initialized
    end
    
end     % end of all loop for data calculation

NumOfSelecCell = cell2mat(compBinListAllMiceTable);
if param.cellSelec_also_diff_ctxt == 0
    Selected_Cell_Mean_Flour_LineGraph4(param,ctxtTableAllMice,max(NumOfSelecCell(:)))
    % Selected_Cell_Mean_Flour_LineGraph(param,ctxtTableAllMice)     % draw line graphs using selected cells 
else                % cell selection(C1>C2,C3, so on); selected cells also chose in different contexts
    [meanNS18,semNS18,varZNS18] = Selected_Cell_Mean_Flour_LineGraph3(param,ctxtTableAllMice_diff_ctxt,max(NumOfSelecCell(:)));
end

% heat-map drawing
if isequal(heatMapFlag,1)
    param.CorFlag = 3;
    for ii = 1:1:length(param.dayList)
        param.day = ii;     % which day
        VR_Excel_Rearrnagement_plotHeatMap2(param,heatMapData(ii,:))
    end
end

% % Kolmogorov-Smirnov test
% if isequal(modeSet,1) || isequal(modeSet,3)
%     KS_test_fcn(param,ctxtMeanAllTrialTable)
% elseif isequal(modeSet,5)
% end
    
% chi-square test
% we do not use % data from 'contextTtestPtg' variable)
%     KS_test_fcn(param,ctxtMeanAllTrialTable,ctxtMeanAllTrialTable_S1
% we use data of i) mean dF/F in different days & contexts
%       Context1     Context2    Context3
% day1 mean dF/F    mean dF/F   mean dF/F
% day4 mean dF/F    mean dF/F   mean dF/F
% ...   ....          ....        ....
%
% ii) descrete number of condition satification
%         Context1           Context2          Context3
% day1 # of C1>(C2&C3)    # of C2>(C1&C3)   # of C3>(C1&C2)
% day4 # of C1>(C2&C3)    # of C2>(C1&C3)   # of C3>(C1&C2)
% ...       ....                ....            ....

for ii = 1:1:numel(ctxtMeanAllTrialTable)
    ctxtMeanAllTrialTable{ii} = mean(cell2mat(ctxtMeanAllTrialTable(ii)));
end
[chi2_result_table,chi2_result_table2] = chi_square_fcn(param,ctxtMeanAllTrialTable,compBinListAllMiceTable);

% % important!!!!
% % xlswrite function works only in MS Windows system 
% % therefore, I searched for this issue on the internet, and the solution
% % is described on a web-site below
% % https://undocumentedmatlab.com/blog/xlswrite-for-mac-linux
% % javaaddpath('/home/choii/Documents/MatlabExcelMac/Archive/jxl.jar')
% % javaaddpath('/home/choii/Documents/MatlabExcelMac/Archive/MXL.jar')
fileName = ['Combining_Cells_mode',num2str(modeSet),'_compMode',num2str(compModeSet),'_chi2_result_table.xls'];
xlwrite(fileName,chi2_result_table);
fileName = ['Combining_Cells_mode',num2str(modeSet),'_compMode',num2str(compModeSet),'_chi2_result_table2.xls'];
xlwrite(fileName,chi2_result_table2);


function [ctxtTable,ctxtTable_S1,ctxtTable2] = xPos_set(ctxtTable,mode,xPos_offset)

% ctxtTable:
% 1st col: context, 2nd col: trial#, 3rd col: time, 4th col: x-pos, 5th col: velocity, 
% 6th col: dF/F(or spike #) in cell1, 7th col: dF/F(or spike #) in cell2, so on
% this variable returns data in user-defined x-position range
% on the other hand, ctxtTable2 returns data in whole x-position range

% mode:
% 1: normal - mean dF/F 0-1800mm, 2: spike - # of spike 0-1800mm, 3: normal S2 - mean dF/F xPosOffset(1700)-1800mm, 
% 4: spike S2 - # of spike xPosOffset(1700)-1800mm, 5: mean dF/F S2(xPosOffset(1700)-1800mm) > S1(0-xPosOffset(1700)), 
% 6: # of spike S2(xPosOffset(1700)-1800mm) > S1(0-xPosOffset(1700))
% 7: # of spike S2(xPosOffset(1700)-1800mm) / # of spike in whole x-pos(0-1800mm)
% 8: fraction of active cell - more than 0.05 calcium transients per second
%
% 11: normal considering end of x-position - mean dF/F 0-1800mm 1st 1790mm, 12: spike x-pos - # of spike 0-1800mm 1st 1790mm, 
% 13: normal S2 - mean dF/F xPosOffset(1700)-1800mm 1st 1790mm, 14: spike S2 x-pos: # of spike xPosOffset(1700)-1800mm 1st 1790mm
% 15: mean dF/F S2(xPosOffset(1700)-1800mm) > S1(0-xPosOffset(1700)) 1st 1790mm, 
% 16: # of spike S2(xPosOffset(1700)-1800mm) > S1(0-xPosOffset(1700)) 1st 1790mm 
% Mice usually stay at end of x-position - around 1790mm - for a while, therefore we set range of data from 0 to (first) 1790mm.
% This is available in mode 11-14
ctxtTable_S1 = []; ctxtTable2 = ctxtTable; % we need all x-pos info. therefore 'ctxtTable2' is the same as just 'DataInte' table

if isequal(mode,3) || isequal(mode,4) || isequal(mode,5) || isequal(mode,6) || isequal(mode,7)
    if isequal(mode,5) || isequal(mode,6)
        xPosIdx = find(ctxtTable(:,4) < xPos_offset);
        ctxtTable_S1 = ctxtTable(xPosIdx,:);
    elseif isequal(mode,7)
        ctxtTable_S1 = ctxtTable;
    end
    xPosIdx = find(ctxtTable(:,4) >= xPos_offset);      % repeat these two line code - think simple way
    ctxtTable = ctxtTable(xPosIdx,:);
    
elseif isequal(mode,11) || isequal(mode,12) || isequal(mode,13) || isequal(mode,14) || isequal(mode,15) || isequal(mode,16)
    tempTable2 = [];
    for trialItr = 1:1:max(ctxtTable(:,2))
      trialIdx = find(ctxtTable(:,2) == trialItr);
      if ~isempty(trialIdx)
          tempTable = ctxtTable(trialIdx,:);
          max_xPos = max(tempTable(:,4));
          max_xPos_idx = find(max_xPos == tempTable(:,4));
          tempTable = tempTable(1:max_xPos_idx(1),:);
          tempTable2 = [tempTable2; tempTable];
          
%           % temporal data organization
%           % return output data which has x-pos from 1700 to end  
%           tempTable = ctxtTable(trialIdx,:);
%           over_xPos_idx = tempTable(:,4)>= xPos_offset;
%           tempTable = tempTable(over_xPos_idx,:);
%           tempTable2 = [tempTable2; tempTable];
      end
    end
    ctxtTable = tempTable2;
    
    if isequal(mode,13) || isequal(mode,14) || isequal(mode,15) || isequal(mode,16)
        if isequal(mode,15) || isequal(mode,16)
            xPosIdx = find(ctxtTable(:,4) < xPos_offset);
            ctxtTable_S1 = ctxtTable(xPosIdx,:);
        end
        xPosIdx = find(ctxtTable(:,4) >= xPos_offset);        % repeat these two line code - think simple way
        ctxtTable = ctxtTable(xPosIdx,:);
    end
    
%     % temporal for three phases: i) 1700-(1st)1790, ii) licking time; (2nd)1790-before 3sec interval, iii) 3sec interval 
%     tempTable2 = [];
%     for trialItr = 1:1:max(ctxtTable(:,2))
%         trialIdx = find(ctxtTable(:,2) == trialItr);
%         if ~isempty(trialIdx) && (ctxtTable(trialIdx(end),4)>= xPos_offset)   % few trial data has unfinished trial
%             tempTable = ctxtTable(trialIdx,:);
%             grp1790_idx = find(max(tempTable(:,4)) == tempTable(:,4));       % find 1790mm - usually max. x-pos - index
%             threeSec_Intvl = tempTable(grp1790_idx(end),3) - 3;              % 3 sec. before the end of x-position
%             temp = abs(tempTable(:,3) - tempTable(grp1790_idx(end),3)); 
%             if tempTable(grp1790_idx(1),3) < threeSec_Intvl                   % correct condition
%                 threeSec_Intvl_idx = find(temp>=0 & temp<= 3);                % find index where less than three_sec_end 
%                 licking_idx = (grp1790_idx(2):threeSec_Intvl_idx(1)-1)';
%                 %tempTable2 = [tempTable2; tempTable(licking_idx,:)];
%             else                                                              % incorrect condition
%                 threeSec_Intvl_idx = grp1790_idx(2):grp1790_idx(end);
%             end
%             tempTable2 = [tempTable2; tempTable(licking_idx,:)];
%         end
%     end
%     ctxtTable = tempTable2;
    
end


function [meanList,meanAllTrial,meanList_S1,meanAllTrial_S1,listTimeHeatMap] = trialFcn(ctxtTable,varargin)

% ctxtTable:
% 1st col: context, 2nd col: trial#, 3rd col: time, 4th col: x-pos, 5th col: velocity,
% 6th col: dF/F(or spike #) in cell1, 7th col: dF/F(or spike #) in cell2, so on

% 'meanList' includes mean of each trial in accumulation: # of trial-by-# of cells
% eg.) [mean dF/F in 1st trial in cell1, cell2, ..., celln;
%       mean dF/F in 2nd trial in cell1, cell2, ..., celln;
%                      ...................
%       mean dF/F in n-th trial in cell1, cell2, ..., celln]
meanList = []; meanList_S1 = []; meanAllTrial_S1 = []; ctxtTable_S1 = []; meanAllTrial = [];
compModeSet = 0; timeHeatMapRange = []; listTimeHeatMap = []; modeSet = 0;
meanList_tmp1 = []; meanList_tmp2 = []; meanList_tmp3 = []; 
meanAllTrial_tmp1 = []; meanAllTrial_tmp2 = []; meanAllTrial_tmp3 = [];

if ~isequal(length(varargin),0)
%     ctxtTable_S1 = varargin{1};
    
    % temporal for modeSet 8 - active cell selection 
    if strcmpi(varargin{1},'modeset8')
        modeSet = 8;
    end

    % temporal for time-space graphs
    if length(varargin) >= 2
        if varargin{2} == 1     
            timeHeatMapRange = 0:varargin{3}/50:varargin{3}; %varargin{3}/50:varargin{3}/50:varargin{3};   % temporal for time-space graphs
            listTimeHeatMap = zeros(1,length(timeHeatMapRange));            % temporal for time-space graphs
        end
    end
    
%     if isequal(length(varargin),2)
%         compModeSet = varargin{2};
%         % 5: comparison C1: % of sum all activity/area 200mm in S2 > sum all activity/area 1600mm in S1, C2: % of S2>S1, C3: S2>S1
%         % 7: # of spike S2(xPosOffset(1700)-1800mm) / # of spike in whole x-pos(0-1800mm)
%         
%     end
end

for trialItr = 1:1:max(ctxtTable(:,2))
   trialIdx = find(ctxtTable(:,2) == trialItr);
   
%    % temporal for three phases: i) 1700-(1st)1790, ii) licking time; (2nd)1790-before 3sec interval, iii) 3sec interval 
%    % for this condition, modeSet=13, compModeSet=1
%     grp1790_idx = find(max(ctxtTable(trialIdx,4)) == ctxtTable(trialIdx,4));    % find 1790mm - usually max. x-pos - index
%     threeSec_Intvl = ctxtTable(trialIdx(end),3) - 3;             % 3 sec. before the end of x-position
%     temp = abs(ctxtTable(trialIdx,3) - ctxtTable(trialIdx(end),3)); 
%     if ctxtTable(trialIdx(grp1790_idx(1)),3) < threeSec_Intvl         % correct condition
%         threeSec_Intvl_idx = find(temp>=0 & temp<= 3);                    % find index where less than three_sec_end 
%         licking_idx = (trialIdx(grp1790_idx(2):threeSec_Intvl_idx(1)-1))';
% %         three_idx = find(ctxtTable(trialIdx,3) <= threeSec_Intvl);  % find index where less than three_sec_end 
%         threeSec_Intvl_idx = trialIdx(threeSec_Intvl_idx)';
% %         trialIdx2 = trialIdx(threeSec_Intvl_idx(end)):trialIdx(end);     % new idx var. has idx info. from 3 sec before and end of x-position
%         
%     else                                                            % incorrect condition
%         threeSec_Intvl_idx = trialIdx(grp1790_idx(2):end);
%         licking_idx = [];
%     end
%     trialIdx = trialIdx(1):trialIdx(grp1790_idx(1));
% %     trialIdx = trialIdx(1):trialIdx(max_xPos_idx(1));           % including by only 1st 1790mm; trialIdx(max_xPos_idx(1))

   
   antiPt_flag = 1;    % temporal for time-space graphs
    
   if ~isempty(trialIdx)
       if isequal(compModeSet,5) || isequal(compModeSet,7)
           meanList = [meanList; sum(ctxtTable(trialIdx,6:end),1,'omitnan')];
       elseif isequal(modeSet,8)                                                        % temporal for modeSet 8 - active cell selection 
            % ctxtTable:
            % 1st col: context, 2nd col: trial#, 3rd col: time, 4th col: x-pos, 5th col: velocity,
            % 6th col: dF/F in cell1, 7th col: spike # in cell1, 8th: dF/F in cell2, 9th: spike # in cell2, so on

            % 'meanList' includes mean of each trial in accumulation: # of trial-by-# of cells
            % eg.) [mean spike # in 1st trial in cell1, cell2, ..., celln;
            %       mean spike # in 2nd trial in cell1, cell2, ..., celln;
            %                      ...................
            %       mean spike # in n-th trial in cell1, cell2, ..., celln]

           data_tmp = sum(ctxtTable(trialIdx,7:2:end),1);                                   % calcium transient is expressed by '1' each row in ctxtTable
           data_tmp = data_tmp / (ctxtTable(trialIdx(end),3)-ctxtTable(trialIdx(1),3));     % calcium transient / time interval all cells
           meanList = [meanList; data_tmp];                                                 % meanList stores calculation result
       else
%            % temporal for three pahses: i) 1700-(1st)1790, ii) licking time; (2nd)1790-before 3sec interval, iii) 3sec interval
%            % for this condition, modeSet=13, compModeSet=1
%            meanList_tmp1 = [meanList_tmp1; mean(ctxtTable(trialIdx,6:end),1,'omitnan')];      % i) phrase
%            if ~isempty(licking_idx)
%                 meanList_tmp2 = [meanList_tmp2; mean(ctxtTable(licking_idx,6:end),1,'omitnan')];   % ii) phrase
%            end
%            if ~isempty(threeSec_Intvl_idx)
%                 meanList_tmp3 = [meanList_tmp3; mean(ctxtTable(threeSec_Intvl_idx,6:end),1,'omitnan')]; % iii) phrase
%            end
           
           meanList = [meanList; mean(ctxtTable(trialIdx,6:end),1,'omitnan')];      % original code
       end
   end
   
   if ~isempty(ctxtTable_S1)
        trialIdx_S1 = find(ctxtTable_S1(:,2) == trialItr);
        if ~isempty(trialIdx_S1)
            if isequal(compModeSet,5) || isequal(compModeSet,7)
                meanList_S1 = [meanList_S1; sum(ctxtTable_S1(trialIdx_S1,6:end),1,'omitnan')];
            else
                meanList_S1 = [meanList_S1; mean(ctxtTable_S1(trialIdx_S1,6:end),1,'omitnan')];
            end
        end
   end
   
   % temporal for time-space graphs
   if length(varargin) >= 2                  
       if varargin{2} == 1
           ctxtTable2 = ctxtTable(trialIdx,:);
           compRange = fliplr(ctxtTable2(end,3) - timeHeatMapRange);
           
           for timeBinIter = 1:1:length(compRange)-1
              if timeBinIter ~= length(compRange)-1
                  timeBinIdx = find(ctxtTable2(:,3) >= compRange(timeBinIter) & ctxtTable2(:,3) < compRange(timeBinIter+1)); 
              else
                  timeBinIdx = find(ctxtTable2(:,3) >= compRange(timeBinIter) & ctxtTable2(:,3) <= compRange(timeBinIter+1)); 
              end
              
              if ~isempty(timeBinIdx)
                  if find(ctxtTable2(timeBinIdx,4)>1700) & (antiPt_flag == 1)    % it shows anticipation area point
                        listTimeHeatMap(trialItr,timeBinIter) = 0; 
                        antiPt_flag = 0;
                  else
                        tempTable = ctxtTable2(timeBinIdx,6:end);
                        listTimeHeatMap(trialItr,timeBinIter) = mean(tempTable(:),'omitnan');
                  end
              end
           end
       end
   end
     
end

if isequal(compModeSet,5)
    meanList = meanList / 100;  % length of S2, 100mm
    meanAllTrial = mean(meanList,'omitnan');
elseif isequal(compModeSet,7)
    meanAllTrial = meanList ./ meanList_S1;
elseif isequal(modeSet,8)
    meanTmp = mean(meanList,1);
    meanAllTrial = meanTmp >= 0.05;           % selection active cells; (calcium activity/time duration) >= 0.05  
else
%     % temporal for three pahses: i) 1700-(1st)1790, ii) licking time; (2nd)1790-before 3sec interval, iii) 3sec interval
%     meanAllTrial_tmp1 = mean(meanList_tmp1,'omitnan');  % i) phrase
%     meanAllTrial_tmp2 = mean(meanList_tmp2,'omitnan');  % ii) phrase
%     meanAllTrial_tmp3 = mean(meanList_tmp3,'omitnan');  % iii) phrase
%     % wrap data into cell-type
%     meanAllTrial{1,1} = meanAllTrial_tmp1;              % i) phrase
%     meanAllTrial{2,1} = meanAllTrial_tmp2;              % ii) phrase
%     meanAllTrial{3,1} = meanAllTrial_tmp3;              % iii) phrase
%     meanList{1,1} = meanList_tmp1;
%     meanList{2,1} = meanList_tmp2;
%     meanList{3,1} = meanList_tmp3;
    
    % original code
    meanAllTrial = mean(meanList,'omitnan');  % 'meanAllTrial' returns mean of all trials in each cells
end

if ~isempty(ctxtTable_S1)
    if isequal(compModeSet,5)
        meanList_S1 = meanList_S1 / 1700;   % length of S1, 1700mm
        meanAllTrial_S1 = mean(meanList_S1,'omitnan');
    else
        meanAllTrial_S1 = mean(meanList_S1,'omitnan');  % 'meanAllTrial_S1' returns mean of all trials in each cells in S1 area
    end
end


function [compBinList,compPvalueList] = comparison(meanList1,meanList2,meanList3,mean1,mean2,mean3,txt,mode)

% 3 scenarios to compare in mode1
% 1) % of cells which are significantly (p<0.05) more active in context1 as compared to both context2 and context3
% 2) % of cells which are significantly more active in context2 as compared to both context1 and context3
% 3) % of cells which are significantly more active in context3 as compared to both context1 and context2

% 3 scenarios to compare in mode4
% 1) % of cells which are significantly (p<0.05) more active in context1 as compared to mean of both context2 and context3: C1 > (C2 + C3)/2
% 2) % of cells which are significantly more active in context2 as compared to mean of both context1 and context3: C2 > (C1 + C3)/2
% 3) % of cells which are significantly more active in context3 as compared to mean of both context1 and context2: C3 > (C1 + C2)/2

% 'meanList' includes mean of each trial in accumulation: # of trial-by-# of cells. this var. is for t-test
% eg.) [mean dF/F in 1st trial in cell1, cell2, ..., celln;
%       mean dF/F in 2nd trial in cell1, cell2, ..., celln;
%                      ...................
%       mean dF/F in n-th trial in cell1, cell2, ..., celln]

% 'mean' returns mean of all trials in each cells

% 'txtTmp' has string, "mice-day"

% compBinList stores binary value - '1': significantly different, '0': n.s.
% - in three scenarios. compBinList -> # of cell-by-3
compBinList = zeros(size(meanList1,2),3);

% compPvalueList stores p-value between two comparisons, eg) context1 vs
% 2&3, so on. compPvalueList -> # of cell-by-6
compPvalueList = zeros(size(meanList1,2),6);

% % temporal for three phases: i) 1700-(1st)1790, ii) licking time; (2nd)1790-before 3sec interval, iii) 3sec interval
% % meanList1/2/3 and mean1/2/3 are cell-type temporally
% meanList1_phr1 = meanList1{1,1}; meanList2_phr1 = meanList2{1,1}; meanList3_phr1 = meanList3{1,1}; % i) phrase
% meanList1_phr2 = meanList1{2,1}; meanList2_phr2 = meanList2{2,1}; meanList3_phr2 = meanList3{2,1}; % ii) phrase
% meanList1_phr3 = meanList1{3,1}; meanList2_phr3 = meanList2{3,1}; meanList3_phr3 = meanList3{3,1}; % iii) phrase
%                     
% mean1_phr1 = mean1{1,1}; mean2_phr1 = mean2{1,1}; mean3_phr1 = mean3{1,1}; % i) phrase
% mean1_phr2 = mean1{2,1}; mean2_phr2 = mean2{2,1}; mean3_phr2 = mean3{2,1}; % ii) phrase
% mean1_phr3 = mean1{3,1}; mean2_phr3 = mean2{3,1}; mean3_phr3 = mean3{3,1}; % iii) phrase


for cellItr = 1:1:size(meanList1,2) % temporal for three phases: size(meanList1_phr1,2) 
    for scenarioItr = 1:1:3
        switch scenarioItr
            case 1
                if isequal(mode,1)
%                     [~,pC1C2_phr1] = ttest2(meanList1_phr1(:,cellItr),meanList2_phr1(:,cellItr));    % i) phrase
%                     [~,pC1C3_phr1] = ttest2(meanList1_phr1(:,cellItr),meanList3_phr1(:,cellItr)); 
%                     if ~isempty(meanList1_phr2) && ~isempty(meanList2_phr2) && ~isempty(meanList3_phr2)
%                         [~,pC1C2_phr2] = ttest2(meanList1_phr2(:,cellItr),meanList2_phr2(:,cellItr));    % ii) phrase
%                         [~,pC1C3_phr2] = ttest2(meanList1_phr2(:,cellItr),meanList3_phr2(:,cellItr)); 
%                     else
%                         pC1C2_phr2 = 1e6; pC1C3_phr2 = 1e6; mean1_phr2 = 0; mean2_phr2 = 0; mean3_phr2 = 0;
%                     end
%                     [~,pC1C2_phr3] = ttest2(meanList1_phr3(:,cellItr),meanList2_phr3(:,cellItr));    % iii) phrase
%                     [~,pC1C3_phr3] = ttest2(meanList1_phr3(:,cellItr),meanList3_phr3(:,cellItr)); 
%                     
%                     if (mean1_phr1(1,cellItr) > mean2_phr1(1,cellItr)) && (mean1_phr1(1,cellItr) > mean3_phr1(1,cellItr))       % checking more active using mean value 
%                %         if (mean1_phr2(1,cellItr) > mean2_phr2(1,cellItr)) && (mean1_phr2(1,cellItr) > mean3_phr2(1,cellItr))       % checking more active using mean value 
%                             if (mean1_phr3(1,cellItr) > mean2_phr3(1,cellItr)) && (mean1_phr3(1,cellItr) > mean3_phr3(1,cellItr))       % checking more active using mean value 
%                                 
%                                 if (pC1C2_phr1 < 0.05) && (pC1C3_phr1 < 0.05)                                                 % checking signicantly more active or not using ttest2
%                %                     if (pC1C2_phr2 < 0.05) && (pC1C3_phr2 < 0.05)                                                 % checking signicantly more active or not using ttest2
%                                         if (pC1C2_phr3 < 0.05) && (pC1C3_phr3 < 0.05)                                                 % checking signicantly more active or not using ttest2
%                                             compBinList(cellItr,1) = 1;
%                                         else
%                                             compBinList(cellItr,1) = 0;
%                                         end
%                %                     else
%                %                         compBinList(cellItr,1) = 0;
%                %                     end
%                                 else
%                                     compBinList(cellItr,1) = 0;
%                                 end
%                             else
%                                 compBinList(cellItr,1) = 0;
%                             end
%                %         else
%                %            compBinList(cellItr,1) = 0;
%                %        end     
%                     else
%                         compBinList(cellItr,1) = 0;
%                     end
                    
                    % original code
                    [~,pC1C2] = ttest2(meanList1(:,cellItr),meanList2(:,cellItr));
                    [~,pC1C3] = ttest2(meanList1(:,cellItr),meanList3(:,cellItr));
                    if (mean1(1,cellItr) > mean2(1,cellItr)) && (mean1(1,cellItr) > mean3(1,cellItr))       % checking more active using mean value 
                        if (pC1C2 < 0.05) && (pC1C3 < 0.05)                                                 % checking signicantly more active or not using ttest2
                            compBinList(cellItr,1) = 1;
                        else
                            compBinList(cellItr,1) = 0;
                        end
                    else
                        compBinList(cellItr,1) = 0;
                    end
                    compPvalueList(cellItr,1:2) = [pC1C2, pC1C3];
                    txtTmp2 = [txt,'- cell',num2str(cellItr),' - T-test2 between Context1 vs 2&3: ', num2str(pC1C2),'  ', num2str(pC1C3)];
                    
                elseif isequal(mode,4)
                    % for compensation with different sample size between contexts
                    rowLenTmp = max([size(meanList2,1),size(meanList3,1)]);
                    meanList2Tmp = nan(rowLenTmp,size(meanList2,2));
                    meanList3Tmp = nan(rowLenTmp,size(meanList3,2));
                    meanList2Tmp(1:size(meanList2,1),:) = meanList2;
                    meanList3Tmp(1:size(meanList3,1),:) = meanList3;
                    tempCal = (meanList2Tmp(:,cellItr)+meanList3Tmp(:,cellItr))/2;
                    
                    [~,pC1C23] = ttest2(meanList1(:,cellItr),tempCal);
                    if mean1(1,cellItr) > (mean2(1,cellItr)+mean3(1,cellItr))/2
                        if pC1C23 < 0.05
                            compBinList(cellItr,1) = 1;
                        else
                            compBinList(cellItr,1) = 0;
                        end
                    else
                        compBinList(cellItr,1) = 0;
                    end
                    txtTmp2 = [txt,'- cell',num2str(cellItr),' - comparison Context1 > (2+3)/2: ', num2str(compBinList(cellItr,1))];
                end
            case 2
                if isequal(mode,1)
%                     [~,pC2C1_phr1] = ttest2(meanList2_phr1(:,cellItr),meanList1_phr1(:,cellItr));    % i) phrase
%                     [~,pC2C3_phr1] = ttest2(meanList2_phr1(:,cellItr),meanList3_phr1(:,cellItr)); 
%                     if ~isempty(meanList1_phr2) && ~isempty(meanList2_phr2) && ~isempty(meanList3_phr2)
%                         [~,pC2C1_phr2] = ttest2(meanList2_phr2(:,cellItr),meanList1_phr2(:,cellItr));    % ii) phrase
%                         [~,pC2C3_phr2] = ttest2(meanList2_phr2(:,cellItr),meanList3_phr2(:,cellItr)); 
%                     else
%                         pC2C1_phr2 = 1e6; pC2C3_phr2 = 1e6; 
%                     end
%                     [~,pC2C1_phr3] = ttest2(meanList2_phr3(:,cellItr),meanList1_phr3(:,cellItr));    % iii) phrase
%                     [~,pC2C3_phr3] = ttest2(meanList2_phr3(:,cellItr),meanList3_phr3(:,cellItr)); 
%                     
%                     if (mean2_phr1(1,cellItr) > mean1_phr1(1,cellItr)) && (mean2_phr1(1,cellItr) > mean3_phr1(1,cellItr))       % checking more active using mean value 
%               %          if (mean2_phr2(1,cellItr) > mean1_phr2(1,cellItr)) && (mean2_phr2(1,cellItr) > mean3_phr2(1,cellItr))       % checking more active using mean value 
%                             if (mean2_phr3(1,cellItr) > mean1_phr3(1,cellItr)) && (mean2_phr3(1,cellItr) > mean3_phr3(1,cellItr))       % checking more active using mean value 
%                                 
%                                 if (pC2C1_phr1 < 0.05) && (pC2C3_phr1 < 0.05)                                                 % checking signicantly more active or not using ttest2
%               %                      if (pC2C1_phr2 < 0.05) && (pC2C3_phr2 < 0.05)                                                 % checking signicantly more active or not using ttest2
%                                         if (pC2C1_phr3 < 0.05) && (pC2C3_phr3 < 0.05)                                                 % checking signicantly more active or not using ttest2
%                                             compBinList(cellItr,2) = 1;
%                                         else
%                                             compBinList(cellItr,2) = 0;
%                                         end
%               %                      else
%               %                          compBinList(cellItr,2) = 0;
%               %                      end
%                                 else
%                                     compBinList(cellItr,2) = 0;
%                                 end
%                             else
%                                 compBinList(cellItr,2) = 0;
%                             end
%               %         else
%               %             compBinList(cellItr,2) = 0;
%               %         end     
%                     else
%                         compBinList(cellItr,2) = 0;
%                     end
                    
                    % original code
                    [~,pC2C1] = ttest2(meanList2(:,cellItr),meanList1(:,cellItr));
                    [~,pC2C3] = ttest2(meanList2(:,cellItr),meanList3(:,cellItr));
                    if (mean2(1,cellItr) > mean1(1,cellItr)) && (mean2(1,cellItr) > mean3(1,cellItr))       % checking more active using mean value 
                        if (pC2C1 < 0.05) && (pC2C3 < 0.05)         % checking signicantly more active or not using ttest2
                            compBinList(cellItr,2) = 1;
                        else
                            compBinList(cellItr,2) = 0;
                        end
                    else
                        compBinList(cellItr,2) = 0;
                    end
                    compPvalueList(cellItr,3:4) = [pC2C1, pC2C3];
                    txtTmp2 = [txt,'- cell',num2str(cellItr),' - T-test2 between Context2 vs 1&3: ', num2str(pC2C1),'  ', num2str(pC2C3)];
                elseif isequal(mode,4)
                    % for compensation with different sample size between contexts
                    rowLenTmp = max([size(meanList1,1),size(meanList3,1)]);
                    meanList1Tmp = nan(rowLenTmp,size(meanList1,2));
                    meanList3Tmp = nan(rowLenTmp,size(meanList3,2));
                    meanList1Tmp(1:size(meanList1,1),:) = meanList1;
                    meanList3Tmp(1:size(meanList3,1),:) = meanList3;
                    tempCal = (meanList1Tmp(:,cellItr)+meanList3Tmp(:,cellItr))/2;
                   
                    [~,pC2C13] = ttest2(meanList2(:,cellItr),tempCal);
                    if mean2(1,cellItr) > (mean1(1,cellItr)+mean3(1,cellItr))/2
                        if pC2C13 < 0.05
                            compBinList(cellItr,2) = 1;
                        else
                            compBinList(cellItr,2) = 0;
                        end
                    else
                        compBinList(cellItr,2) = 0;
                    end
                    txtTmp2 = [txt,'- cell',num2str(cellItr),' - comparison Context2 > (1+3)/2: ', num2str(compBinList(cellItr,1))];
                end
            case 3
                if isequal(mode,1)
%                     [~,pC3C1_phr1] = ttest2(meanList3_phr1(:,cellItr),meanList1_phr1(:,cellItr));    % i) phrase
%                     [~,pC3C2_phr1] = ttest2(meanList3_phr1(:,cellItr),meanList2_phr1(:,cellItr)); 
%                     if ~isempty(meanList1_phr2) && ~isempty(meanList2_phr2) && ~isempty(meanList3_phr2)
%                         [~,pC3C1_phr2] = ttest2(meanList3_phr2(:,cellItr),meanList1_phr2(:,cellItr));    % ii) phrase
%                         [~,pC3C2_phr2] = ttest2(meanList3_phr2(:,cellItr),meanList2_phr2(:,cellItr)); 
%                     else
%                         pC3C1_phr2 = 1e6; pC3C2_phr2 = 1e6;
%                     end
%                     [~,pC3C1_phr3] = ttest2(meanList3_phr3(:,cellItr),meanList1_phr3(:,cellItr));    % iii) phrase
%                     [~,pC3C2_phr3] = ttest2(meanList3_phr3(:,cellItr),meanList2_phr3(:,cellItr)); 
%                     
%                     if (mean3_phr1(1,cellItr) > mean1_phr1(1,cellItr)) && (mean3_phr1(1,cellItr) > mean2_phr1(1,cellItr))       % checking more active using mean value 
%             %            if (mean3_phr2(1,cellItr) > mean1_phr2(1,cellItr)) && (mean3_phr2(1,cellItr) > mean2_phr2(1,cellItr))       % checking more active using mean value 
%                             if (mean3_phr3(1,cellItr) > mean1_phr3(1,cellItr)) && (mean3_phr3(1,cellItr) > mean2_phr3(1,cellItr))       % checking more active using mean value 
%                                 
%                                 if (pC3C1_phr1 < 0.05) && (pC3C2_phr1 < 0.05)                                                 % checking signicantly more active or not using ttest2
%             %                        if (pC3C1_phr2 < 0.05) && (pC3C2_phr2 < 0.05)                                                 % checking signicantly more active or not using ttest2
%                                         if (pC3C1_phr3 < 0.05) && (pC3C2_phr3 < 0.05)                                                 % checking signicantly more active or not using ttest2
%                                             compBinList(cellItr,3) = 1;
%                                         else
%                                             compBinList(cellItr,3) = 0;
%                                         end
%             %                        else
%             %                            compBinList(cellItr,3) = 0;
%             %                        end
%                                 else
%                                     compBinList(cellItr,3) = 0;
%                                 end
%                             else
%                                 compBinList(cellItr,3) = 0;
%                             end
%             %           else
%             %               compBinList(cellItr,3) = 0;
%             %           end     
%                     else
%                         compBinList(cellItr,3) = 0;
%                     end
                    
                    % original code
                    [~,pC3C1] = ttest2(meanList3(:,cellItr),meanList1(:,cellItr));
                    [~,pC3C2] = ttest2(meanList3(:,cellItr),meanList2(:,cellItr));
                    if (mean3(1,cellItr) > mean1(1,cellItr)) && (mean3(1,cellItr) > mean2(1,cellItr))       % checking more active using mean value 
                        if (pC3C1 < 0.05) && (pC3C2 < 0.05)         % checking signicantly more active or not using ttest2
                            compBinList(cellItr,3) = 1;
                        else
                            compBinList(cellItr,3) = 0;
                        end
                    else
                        compBinList(cellItr,3) = 0;
                    end
                    compPvalueList(cellItr,5:6) = [pC3C1, pC3C2];
                    txtTmp2 = [txt,'- cell',num2str(cellItr),' - T-test2 between Context3 vs 1&2: ', num2str(pC3C1),'  ', num2str(pC3C2)];
                elseif isequal(mode,4)
                    % for compensation with different sample size between contexts
                    rowLenTmp = max([size(meanList1,1),size(meanList2,1)]);
                    meanList1Tmp = nan(rowLenTmp,size(meanList1,2));
                    meanList2Tmp = nan(rowLenTmp,size(meanList2,2));
                    meanList1Tmp(1:size(meanList1,1),:) = meanList1;
                    meanList2Tmp(1:size(meanList2,1),:) = meanList2;
                    tempCal = (meanList1Tmp(:,cellItr)+meanList2Tmp(:,cellItr))/2;
                    
                    [~,pC3C12] = ttest2(meanList3(:,cellItr),tempCal);
                    if mean3(1,cellItr) > (mean1(1,cellItr)+mean2(1,cellItr))/2
                        if pC3C12 < 0.05
                            compBinList(cellItr,3) = 1;
                        else
                            compBinList(cellItr,3) = 0;
                        end
                    else
                        compBinList(cellItr,3) = 0;
                    end
                    txtTmp2 = [txt,'- cell',num2str(cellItr),' - comparison Context3 > (1+2)/2: ', num2str(compBinList(cellItr,1))];
                end
        end
        
        disp(txtTmp2)
    end
end


function [compBinList,compPvalueList] = comparison3(paramStruct1,paramStruct2,paramStruct3,txt,mode)

% compare three contexts using % of S2(1600-1800mm) > S1(0-1600mm) with mean dF/F
% paramStruct is a structure which have 'ctxtMeanList', 'ctxtMeanList_S1', 'ctxtMeanAllTrial', 'ctxtMeanAllTrial_S1');

% compBinList stores binary value - '1': significantly different, '0': n.s.
% - in three contexts. compBinList -> # of cell-by-3
compBinList = zeros(size(paramStruct1.ctxtMeanList1,2),3);

% compPvalueList stores p-value in each contexts, eg) context1, context2, context3. compPvalueList -> # of cell-by-3
compPvalueList = zeros(size(paramStruct1.ctxtMeanList1,2),3);

% 'txtTmp' has string, "mice-day"

for cellItr = 1:1:size(paramStruct1.ctxtMeanList1,2)
    for ctxtItr = 1:1:3
        switch ctxtItr
            case 1
                if isequal(mode,3)
                    [~,pS2S1] = ttest2(paramStruct1.ctxtMeanList1(:,cellItr),paramStruct1.ctxtMeanList1_S1(:,cellItr));
                    if (paramStruct1.ctxtMeanAllTrial1(1,cellItr) > paramStruct1.ctxtMeanAllTrial1_S1(1,cellItr))     % checking more active using mean value 
                        if (pS2S1 < 0.05)
                            compBinList(cellItr,1) = 1;
                        else
                            compBinList(cellItr,1) = 0;
                        end
                    else
                        compBinList(cellItr,1) = 0;
                    end
                    txtTmp2 = [txt,'- cell',num2str(cellItr),' - T-test2 between S2(1600-1800mm) and S1(0-1600mm) in Context1: ', num2str(pS2S1)];
                
                elseif isequal(mode,5)
                    tempS1 = paramStruct1.ctxtMeanList1_S1(:,cellItr);
                    tempS2 = paramStruct1.ctxtMeanList1(:,cellItr);
                    [~,pS2S1] = ttest2(tempS2, tempS1);
                    if (paramStruct1.ctxtMeanAllTrial1(1,cellItr) > paramStruct1.ctxtMeanAllTrial1_S1(1,cellItr))     % checking more active using mean value 
                        if (pS2S1 < 0.05)
                            compBinList(cellItr,1) = 1;
                        else
                            compBinList(cellItr,1) = 0;
                        end
                    else
                        compBinList(cellItr,1) = 0;
                    end    
                    txtTmp2 = [txt,'- cell',num2str(cellItr),' - T-test2 between S2(1600-1800mm)/length2 and S1(0-1600mm)/length1 in Context1: ', num2str(pS2S1)];
                end
                compPvalueList(cellItr,1) = pS2S1;
                
            case 2
                if isequal(mode,3)
                    [~,pS2S1] = ttest2(paramStruct2.ctxtMeanList2(:,cellItr),paramStruct2.ctxtMeanList2_S1(:,cellItr));
                    if (paramStruct2.ctxtMeanAllTrial2(1,cellItr) > paramStruct2.ctxtMeanAllTrial2_S1(1,cellItr))     % checking more active using mean value 
                        if (pS2S1 < 0.05)
                            compBinList(cellItr,2) = 1;
                        else
                            compBinList(cellItr,2) = 0;
                        end
                    else
                        compBinList(cellItr,2) = 0;
                    end
                    txtTmp2 = [txt,'- cell',num2str(cellItr),' - T-test2 between S2(1600-1800mm) and S1(0-1600mm) in Context2: ', num2str(pS2S1)];
                
                elseif isequal(mode,5)
                    tempS1 = paramStruct2.ctxtMeanList2_S1(:,cellItr);
                    tempS2 = paramStruct2.ctxtMeanList2(:,cellItr);
                    [~,pS2S1] = ttest2(tempS2, tempS1);
                    if (paramStruct2.ctxtMeanAllTrial2(1,cellItr) > paramStruct2.ctxtMeanAllTrial2_S1(1,cellItr))     % checking more active using mean value 
                        if (pS2S1 < 0.05)
                            compBinList(cellItr,2) = 1;
                        else
                            compBinList(cellItr,2) = 0;
                        end
                    else
                        compBinList(cellItr,2) = 0;
                    end    
                    txtTmp2 = [txt,'- cell',num2str(cellItr),' - T-test2 between S2(1600-1800mm)/length2 and S1(0-1600mm)/length1 in Context2: ', num2str(pS2S1)];
                end
                compPvalueList(cellItr,2) = pS2S1;
                
            case 3
                if isequal(mode,3)
                    [~,pS2S1] = ttest2(paramStruct3.ctxtMeanList3(:,cellItr),paramStruct3.ctxtMeanList3_S1(:,cellItr));
                    if (paramStruct3.ctxtMeanAllTrial3(1,cellItr) > paramStruct3.ctxtMeanAllTrial3_S1(1,cellItr))     % checking more active using mean value 
                        if (pS2S1 < 0.05)
                            compBinList(cellItr,3) = 1;
                        else
                            compBinList(cellItr,3) = 0;
                        end
                    else
                        compBinList(cellItr,3) = 0;
                    end
                    txtTmp2 = [txt,'- cell',num2str(cellItr),' - T-test2 between S2(1600-1800mm) and S1(0-1600mm) in Context3: ', num2str(pS2S1)];
                
                elseif isequal(mode,5)
                    tempS1 = paramStruct3.ctxtMeanList3_S1(:,cellItr);
                    tempS2 = paramStruct3.ctxtMeanList3(:,cellItr);
                    [~,pS2S1] = ttest2(tempS2, tempS1);
                    if (paramStruct3.ctxtMeanAllTrial3(1,cellItr) > paramStruct3.ctxtMeanAllTrial3_S1(1,cellItr))     % checking more active using mean value 
                        if (pS2S1 < 0.05)
                            compBinList(cellItr,3) = 1;
                        else
                            compBinList(cellItr,3) = 0;
                        end
                    else
                        compBinList(cellItr,3) = 0;
                    end    
                    txtTmp2 = [txt,'- cell',num2str(cellItr),' - T-test2 between S2(1600-1800mm)/length2 and S1(0-1600mm)/length1 in Context3: ', num2str(pS2S1)];
                end
                compPvalueList(cellItr,3) = pS2S1;    
        end
        
        disp(txtTmp2)
    end
end

% function [heatMapData] = HeatMapCal(context,day,ctxtTable,heatMapRange,heatMapData)
%     
% % heatMapData - cell type
% % # of days-by-# of contexts data size
% 
% % x-axis: position 0-1800mm, y-axis: # of cells
% % ctxtTable: ['Context','Trial','Times(s)','Position(mm)','dF/F in cell1','in cell2', ... 'in celln'];
% % heatMapDataTmp has # of cell-by-heatMapRange data size
% heatMapDataTmp = zeros(size(ctxtTable,2)-4,length(heatMapRange));     % mean fluorescence data
% 
% % arragement of fluorescence data by position bin
% for ii = 1:1:length(heatMapRange)-1     
%     % find index which depict position data within specific position bin
%     % ctxtTable: ['Context','Trial','Times(s)','Position(mm)','dF/F in cell1','in cell2', ... 'in celln'];
%     idxTmp = find(ctxtTable(:,4)>=heatMapRange(ii) & ctxtTable(:,4)<heatMapRange(ii+1));   
%     if ~isempty(idxTmp)
%         tableTmp = ctxtTable(idxTmp,5:end);         % fluorescence data - mean calculation
%         heatMapDataTmp(:,ii) = mean(tableTmp)';     % heatMapDataTmp has # of cell-by-heatMapRange data size
%     else
%         heatMapDataTmp(:,ii) = 0;
%     end
% end
% 
% % here, day does not mean exact date, but day iteration.
% % so we can use day var. as continuous numeric data
% if isequal(context,1)
%     heatMapData{day,1} = [heatMapData{day,1}; heatMapDataTmp];
% elseif isequal(context,2)
%     heatMapData{day,2} = [heatMapData{day,2}; heatMapDataTmp];
% elseif isequal(context,3)
%     heatMapData{day,3} = [heatMapData{day,3}; heatMapDataTmp];
% end
%     
