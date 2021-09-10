function [spd_over_trial] = speed_by_pos(dtCell_spaceBin,param,param_sub)

dayList = param.dayList;
miceList = param.miceList;
trial_lim = param_sub.trial_lim;
heatMapRange = param.heatMapRange;
figure_show_axisOff = param_sub.figure_show_axisOff;
day = param_sub.day;
animal = param_sub.animal;

% dtCell_spaceBin: heat-map range(0:100:1800)*trial number-by-cell 
% number(+four additional column: space bin number, context number, trial number)
% 1st col: space bin number, 2nd: context number, 3rd: trial number,
% 4th: speed(cm/s, outlier could be excluded-check code before),
% 5th-end: selected cells' activity

% three different contexts are expressed in three different data
for dayIter = day:1:day%length(dayList)   
    for animalIter = animal:1:animal % length(miceList)
        dataIdx = (dayIter-1)*length(miceList) + animalIter;
        
        for ctxtIter = 1:1:3
            data_load = dtCell_spaceBin{dataIdx,ctxtIter};
        
            figure
            txt = [dayList{dayIter},'-Animal',num2str(animalIter),'-Context',num2str(ctxtIter)];
            spd_over_trial = [];
            
            for trialIter = 1:1:trial_lim(dayIter)
                speed_data_trial = data_load((data_load(:,3)==trialIter),4);
                spd_over_trial = [spd_over_trial; speed_data_trial'];       % for calculation of mean speed over trial
                
                % we assume that space bin in each trial in data_load is 
                % always separated by 18 bins
            end          
            
            plot(1:size(spd_over_trial,2),spd_over_trial,'Color',[0.5,0.5,0.5]); hold on;
            plot(mean(spd_over_trial,1,'omitnan'),'k-','LineWidth',4); hold off;
            if isequal(figure_show_axisOff,0)
                xlabel('Position(cm)'); ylabel('Speed(cm/s)');
                title(txt)
            else
                xticklabels({}); yticklabels({});
            end

            %ylim([0 60]); xlim([1 18]);
            
        end
        
    end

end
