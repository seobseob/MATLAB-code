% updated normalization method
% updated heat-map graph method
% additional information - dF/F & spike from calcium signal analysis SW
% integrated this code, VR_Excel_Rearrangement_CellBias3_batch_mode.m, and VR_Excel_Rearrangement_CellBias_combininbCells.m

%% variables initialization

clear       % clear all variables, using 'clear' instead of 'clear all'

% two modes is supported in this program
% 1st mode - assign one mice one day
param.miceID = '13775';
param.day = 'day4';
param.miceID_day = [param.miceID,'-',param.day];
param.batch_mode = 0;   % batch mode flag

% 2nd mode - assign all mice all day
% if 1st mode is already set, then ask to users which mode would be run
if isstruct(param) && isfield(param,'miceID')
    answer = questdlg({'You have already assigned a specific mice ID & day','Which mode would you like to run?'}, ...
	'Warning', 'One mouse','Batch mode','Batch mode');

    % Handle response
    switch answer
        case 'One mouse'
            param.miceList = {param.miceID};
            param.dayList = {param.day};
        case 'Batch mode'
            param.miceList = {'13118','13696','13775','13776','14228'}; % DREADDs-Control % {'9485','9993','9995','10062','10065','10515'}; % DREADDs % {'8679','8680','8682','8969','9230'}; % non-DREADDs     
            param.dayList = {'day1','day4','day7'}; % DREADDs-Control % {'day1','day4','day5','day8','day9','day12','day13','day16','day17'}; % DREADDs  % {'day1','day4','day7'}; % non-DREADDs    
            param.batch_mode = 1;   % batch mode flag
                        
            fields = {'miceID','day','miceID_day'};
            param = rmfield(param,fields);
    end
    
else
    param.miceList = {'13118','13696','13775','13776','14228'}; % DREADDs-Control % {'9485','9993','9995','10062','10065','10515'}; % DREADDs % {'8679','8680','8682','8969','9230'}; % non-DREADDs     
    param.dayList = {'day1','day4','day7'}; % DREADDs-Control % {'day1','day4','day5','day8','day9','day12','day13','day16','day17'}; % DREADDs  % {'day1','day4','day7'}; % non-DREADDs    
    param.batch_mode = 1;   % batch mode flag
end

param.speedName = 'Position';
param.speedNameExtra = 'modified';
param.fluoName = 'normalized dF-by-F';
param.spkName = 'spike train';

param.CorFlag = [0, 200, 400];    % corridor flag, each number depicts different corridors

param.XPosEndLimit = 1800;        % distance limit of x-position in corridor when a mouse finish running in a trial; we assume that length of corridor is 1800mm
param.XPosStartLimit = 600;       % distance limit of x-position in corridor when a mouse start running in a trial
XPosStart = 0;                    % start point in X-Position
XPosRange = 10;                   % range of x-position in corridor; this parameter is used when we draw heat-map
XPosEnd = 1800 - XPosRange; % end range of x-position in corridor; this parameter is used when we draw heat-map
param.heatMapRange = XPosStart:XPosRange:XPosEnd;

param.ColorLimit = 1;            % color-bar limit
param.SaveImgFlag = 0;           % if SaveImgFlag is '0' Saving Images does not work
param.ColorbarFlag = 1;
param.XlsFlag = 0;

%% import essential data and treat here

for miceIter = 1:1:length(param.miceList)
    for dayIter = 1:1:length(param.dayList)
        % initialization of this var. every loop
        DataInte = {'Animal','Cell #','Treatment','Session','Context','Reward','Trial #','Times(s)','Position(mm)','Velocity(mm/s)','mean dF/F','mean spike'};
        
        %% import data of speed measurement, Fluorescence, and Spike train 

        % Raw Data Structure(*.xls or *.xlsx file)
        % 1st column: time(sec), 2nd: x-position in corridor(mm), 3rd: corridor flag(seperated 3 corridors-0,200,400)
        % 4th: 2PM trigger number(not corrected)
        % * Usually x-position starts 0 and ends around 1800 but not always

        param.miceID = param.miceList{miceIter};
        param.miceID_day = [param.miceList{miceIter},'-',param.dayList{dayIter}];     % eg) '13775-day1', '13775-day4', so on
        if isequal(param.batch_mode,1)
            param.day = param.dayList{dayIter};
        end

        % cells variable has user-selected-good cells' number
        param.good_cells = good_cell_list(param.miceID_day);     % miceID_day is user-determined variable

        [loadedDataSpeed,loadedDataFluor,loadedDataSpk] = VR_Excel_Rearrangement_importData2(param);

        %% speed measurement data preprocessing
        % 1) searching for a start/end point
        % searching condition(start): time(in 1st col) & trigger(in 4th col) are not '0', plus, consider an issue below

        % 0         0   0     0
        % 2.9370    0   0   631
        % 3.0250    0   0   631
        % 3.2200    0   0     0
        % ......    ......
        % 8.5960    518 0     1 
        %
        % here, 631 in 4th coloumn is an issue to be ignored

        % searching condition(end): the maximum value which trigger(in 4th col) is not '0'

        % 2) seperation trials in each corridor table
        % first all, to calculate difference between neighbor x position in each row, such as (x position in row1 - row2), (x position in row2 - row3), so on.
        % next, to find index whose value is bigger than 1500 in 2nd column where depicts x position.
        % consequently, the variable 'trial_mark_tableN' includes index value which depicts new trial

        % 3) data correction of unusual condition, such as 
        %   i) 1.0(time) 1800(x-pos) 0(corridor) 
        %  ii) 1.1       1800        200  <- must be '0'
        % iii) 1.2       0           200
        % 
        % compare end index and second end index of each trial, for example,
        % compare i) and ii) index above and put correct corridor flag into 1) index

        % 4) conversion from trigger to frame number
        % trigger is increased by 4 times, therefore, we need convert it into the serial number of frame
        % such as, trigger number is [1000, 1003, 1007, 1010..] and it must be converted into [250,251,252,253...]

        % 5) to get rid of duplicated number of frame on DataTable1
        % if there is duplicate value, then we delete & overwrite that with next data
        % for example, (converted) frame number is [250,251,251,253,254,...], then,
        % we have got a duplicated number, 251 in 2nd & 3rd element

        % 6) interpolate absence number of frame

        % 7) calculation of velocity between frames

        [DataTable3, TrialMark] = VR_Excel_Rearrangement_preprocessing(loadedDataSpeed,param);

        % %% import data of fluorescence & spike-train data
        % [FluorData,SpikeData,cells] = VR_Excel_Rearrangement_importFluoSpk(param.miceID_day);
    
        %% merging(synchronizing) raw data of VR with fluorescence data

        [DataInte,DataInte_Context] = VR_Excel_Rearrangement_mergeVRFlour(DataTable3,loadedDataFluor,loadedDataSpk,DataInte,param);
        
        %% saving essential data 
%         fileName = [param.miceID_day,'-DataInte.mat'];
%         save(fileName,'DataInte')
%         
%         % important!!!!
%         % xlswrite function works only in MS Windows system 
%         % therefore, I searched for this issue on the internet, and the solution
%         % is described on a web-site below
%         % https://undocumentedmatlab.com/blog/xlswrite-for-mac-linux
%         % javaaddpath('/home/choii/Documents/MatlabExcelMac/Archive/jxl.jar')
%         % javaaddpath('/home/choii/Documents/MatlabExcelMac/Archive/MXL.jar')
%         fileName = [param.miceID_day,'-DataInte.xls'];
%         save(fileName,'DataInte')
    end
end

%% categorize data by corridor flag & gathering fluorescence data in position bin 
[HeatMapData,DataInte_Context,contextCellBiasTable,contextCellBiasPtg,contextRewardCompTable,contextRewardCompPtg] = VR_Excel_Rearrangement_category2(param,FluorData,DataInte,DataInte_Context);
% % for repeated one-way ANOVA 
% rAnovaResultTable
% fileName = [param.miceID_day,'_RM one-way ANOVA_data table.mat']; 
% save(fileName,'rAnovaTable')
% fileName = [param.miceID_day,'_RM one-way ANOVA_result table.mat']; 
% save(fileName,'rAnovaResultTable')

% for calculation of cell bias - T-test2 between each contexts
fileName = [param.miceID_day,'_Cellbias_t-test contexts_data table.mat'];
save(fileName,'contextCellBiasTable')
contextCellBiasPtg       % only for displaying on command window
contextRewardCompPtg     % only for displaying on command window

fileName = [param.miceID_day,'_Reward Expectation Comparison_t-test contexts_data table.mat'];
save(fileName,'contextRewardCompTable')

fileName = [param.miceID_day,'-DataInte.mat'];
save(fileName,'DataInte')

%% plot heat-map graphs by corridor number
VR_Excel_Rearrnagement_plotHeatMap2(param,HeatMapData)


