function [num] = numeric_in_string(str)

    num = regexp(str,'\d+','match');
    num = str2double(num{1,1});

end