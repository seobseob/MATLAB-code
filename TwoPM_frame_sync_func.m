function [dtCell_twoPM_frame_data] = TwoPM_frame_sync_func(dtCell_trigger_time_data,dtCell_spd_essen_data,num_frame_data)

    
%% variable initialization

    % PhenoSys system(= experiment control system) running frequency: 50 Hz
    % it means that the system record log 50 times every second 
    %
    % theoretically twoPM_freq = 30.3, but it is not true in real,thus
    % it is required to estimate twoPM_freq every time to get relatively 
    % precisive result in dtCell_twoPM_frame_data
    
    % twoPM_freq: two-photon microscope imaging frequency [Hz]
    % num_session: how many sessions in a single of experiment
    [twoPM_freq,num_session] = twoPM_freq_func(dtCell_trigger_time_data,num_frame_data);
        
    % dtCell_spd_essen_data (we only need from 1st to 5th column in this variable):
    % 1st col: Trial #, 2nd: Context, 3rd-5th: Time in start run/BlackStart/EndTrial
    % 6-8th: physical position in start run/BlackStart/EndTrial,
    % 9-11th: VR position in start run/BlackStart/EndTrial
    % 12-14th: Speed in three condition, i) start run-EndTrial(cm/s), 
    % ii) BlackStart-Endtrial, iii) start run-Blackstart,
    % 15th: Speed in anticipation area(2600-2700mm)
    %
    % dtCell_time_essen_data has only information of {trial#, context#,
    % time in start run, time in BlackStart, and time in EndTrial}
    dtCell_time_essen_data = dtCell_spd_essen_data(:,1:5);
    trial_col=1; ctxt_col=2; startRun_col=3; blackStart_col=4; endTrial_col=5;
    
    % dtCell_twoPM_frame_data:
    % 1st col: trial#, 2nd: context#, 3rd: (accumulted)frame# in start run,
    % 4th: frame# in BlackStart, 5th: frame# in EndTrial
    % caution!! frame number here is always accumulated value
    [row,col] = size(dtCell_time_essen_data);
    % dtCell_twoPM_frame_data: real data to be returned 
    dtCell_twoPM_frame_data = dtCell_time_essen_data(1,:);      % 1st row: head of column
    dtCell_twoPM_frame_data{2,1} = 'StartTrigger';
    dtCell_twoPM_frame_data{2,3} = 1;                           % frame 1
    
    dtCell_twoPM_frame_data_temp = cell(row,col);               % temporal data to support understanding of processing myself
    dtCell_twoPM_frame_data_temp(1,:) = dtCell_time_essen_data(1,:);
    
    % caution!! it is possible that reference time(StartTrigger in dtCell_trigger_time_data) 
    % is changeable because operators could separate an experiment in several slots. 
    % Therefore, time difference between time in EndTrial in previous and time 
    % in start run is always checked whether significant time gap or not
    % e.g.) Time in EndTrial in previous stage: 12:04:28.808
    %       Time in start run this stage:       12:04:28.813
    %       time gap between of them is only 0.005 s, and this is normal
    ref_sess = 1;
    ref_time = dtCell_trigger_time_data{(ref_sess-1)*2+1,2};
    end_time = dtCell_trigger_time_data{(ref_sess-1)*2+2,2};
    ref_twoPM_freq = twoPM_freq(ref_sess,1);  
    frame_offset = 0;
   
%% two-photon image frame number synchronization 

    for rowIter = 2:1:size(dtCell_twoPM_frame_data_temp,1)
        % three columns: start run, BlackStart, endTrial       
        for colIter = startRun_col:1:endTrial_col
            % time_gap: [unknown,unknwon,unknwon,Hour,Minute,Second]
            % time arithmatic calculation to find time gap
            time_gap = time_gap_cal_func(ref_time,dtCell_time_essen_data{rowIter,colIter});  
            dtCell_twoPM_frame_data_temp{rowIter,colIter} = round(time_gap * ref_twoPM_freq)+frame_offset;

            % if frame number in time endTrial in previous is equal to
            % frame number in start run, +1 to start run to avoid
            % duplicated frame number
            if (rowIter>2) & isequal(colIter,startRun_col) & ...
                    dtCell_twoPM_frame_data_temp{rowIter,colIter} == dtCell_twoPM_frame_data_temp{rowIter-1,endTrial_col}
                dtCell_twoPM_frame_data_temp{rowIter,colIter} = dtCell_twoPM_frame_data_temp{rowIter,colIter}+1;
            end
                      
            % trial# and context# storing
            dtCell_twoPM_frame_data_temp(rowIter,trial_col:ctxt_col) = dtCell_time_essen_data(rowIter,trial_col:ctxt_col);
        end
        
        % data accumulation in real data
        dtCell_twoPM_frame_data = [dtCell_twoPM_frame_data; dtCell_twoPM_frame_data_temp(rowIter,:)];
        
        % new reference time checking
        % time difference check between time in EndTrial in previous and time in start run
        % this thing is possibly happened when operators did experiment in several slots
        if (num_session > 1) & (ref_sess < num_session)
            % end time between multiple number of session should be satisfied that
            % time at 'EndTrial' current trial <= end_time < time at 'Start run' next trial 
            if (end_time >= dtCell_time_essen_data{rowIter,endTrial_col}) & (end_time < dtCell_time_essen_data{rowIter+1,startRun_col})
                time_gap = time_gap_cal_func(ref_time,end_time);
                frame = round(time_gap*ref_twoPM_freq);
                row_size = size(dtCell_twoPM_frame_data,1);
                dtCell_twoPM_frame_data{row_size+1,1} = 'EndTrigger';
                dtCell_twoPM_frame_data{row_size+1,5} = frame;     % frame# at 1st endTrigger
                frame_offset = frame;                              % reset frame number offset
                
                % reset data using updated ref_sess value
                ref_sess = ref_sess + 1;
                ref_time = dtCell_trigger_time_data{(ref_sess-1)*2+1,2};
                end_time = dtCell_trigger_time_data{(ref_sess-1)*2+2,2};
                ref_twoPM_freq = twoPM_freq(ref_sess);
                dtCell_twoPM_frame_data{row_size+2,1} = 'StartTrigger';
                dtCell_twoPM_frame_data{row_size+2,3} = frame_offset+1; % frame# at next startTrigger
                        
                % display addtional information
                trial_num = dtCell_time_essen_data{rowIter+1,trial_col};
                ctxt_num = dtCell_time_essen_data{rowIter+1,ctxt_col};
                txt = ['new reference time set in trial',num2str(trial_num),' context',num2str(ctxt_num)];
                disp(txt)             
            end
        end
        
        % end of the data; frame number at the last endTrigger is added into dtCell_twoPM_frame_data
        if isequal(rowIter,size(dtCell_twoPM_frame_data_temp,1))
            time_gap = time_gap_cal_func(ref_time,end_time);
            frame = round(time_gap*ref_twoPM_freq)+frame_offset;
            row_size = size(dtCell_twoPM_frame_data,1);
            dtCell_twoPM_frame_data{row_size+1,1} = 'EndTrigger';
            dtCell_twoPM_frame_data{row_size+1,5} = frame;     % frame# at the last endTrigger
        end
        
    end
    
end

function [twoPM_freq,num_session] = twoPM_freq_func(dtCell_trigger_time_data,num_frame_data)
   
    % twoPM_freq: two-photon microscope imaging frequency [Hz]
    twoPM_freq = []; 
    % num_session: how many sessions in a single of experiment
    num_session = size(dtCell_trigger_time_data,1)/2;       
    for sessIter = 1:1:num_session
        startTrigger_time = dtCell_trigger_time_data{(sessIter-1)*2+1,2};
        endTrigger_time = dtCell_trigger_time_data{(sessIter-1)*2+2,2};
        
        time_gap = datevec(endTrigger_time - startTrigger_time);
        time_gap = time_gap(1,4)*3600 + time_gap(1,5)*60 + time_gap(1,6);
        num_frame = num_frame_data{1,sessIter};
        twoPM_freq = [twoPM_freq; num_frame/time_gap];
        
        txt = ['Two-Photon imaging frequency is ',num2str(num_frame/time_gap),'Hz'];
        disp(txt)
    end

end

function [time_gap] = time_gap_cal_func(start_time,end_time)

    time_gap = datevec(end_time - start_time); 
	time_gap = time_gap(1,end-2)*3600 + time_gap(1,end-1)*60 + time_gap(1,end);
                
end







