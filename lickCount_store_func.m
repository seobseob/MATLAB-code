function [dtCell_batch_lick_count] = lickCount_store_func(dtCell_batch_lick_count,dtCell_batch_idx,param,animalIter,dayIter)

    % integrate licking count in all days, in all animals
    dtCell_batch_lick_count{dtCell_batch_idx+1,1} = param.animalList{animalIter}{1,1};
    
    if size(param.dayList{dayIter},1) == 2
      dtCell_batch_lick_count{dtCell_batch_idx+1,2} = param.dayList{dayIter}{1,1};
    else
      dtCell_batch_lick_count{dtCell_batch_idx+1,2} = [param.dayList{dayIter}{1,1},'-',param.dayList{dayIter}{3,1}];
    end
    
end