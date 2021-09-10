function [idx,binary_idx] = indexing_in_cell(cell_idx)    % input data must be cell type
    
    idx = []; binary_idx = [];
    
    for idxIter = 1:1:size(cell_idx,1)
       if ~isempty(cell_idx{idxIter,1})
           idx = [idx; idxIter];
           binary_idx = [binary_idx; 1];
       else
           binary_idx = [binary_idx; 0];
       end
    end
    
end