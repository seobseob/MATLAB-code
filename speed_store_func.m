function [dtCell_batch_speed] = speed_store_func(dtCell_batch_speed,dtCell_batch_idx,param,animalIter,dayIter)
                      
    % integrate speed calculation in all days, in all animals
    dtCell_batch_speed{dtCell_batch_idx+1,1} = param.animalList{animalIter}{1,1};     % e.g.) param.animalList{1} = {’Animal 1'; 'Animal1'} 
    dtCell_batch_speed_trialBase{dtCell_batch_idx+1,1} = param.animalList{animalIter}{1,1};
    if size(param.dayList{dayIter},1) == 2
       dtCell_batch_speed{dtCell_batch_idx+1,2} = param.dayList{dayIter}{1,1};       % e.g.) param.dayList{1} = {'Day 1'; 'Day1'} or param.dayList{14} = {'1week';'1 week';'distractor'}
    else
       dtCell_batch_speed{dtCell_batch_idx+1,2} = [param.dayList{dayIter}{1,1},'-',param.dayList{dayIter}{3,1}]; 
    end

end