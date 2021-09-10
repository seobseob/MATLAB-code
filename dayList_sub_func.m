function [dayList] = dayList_sub_func(day)

    if isnumeric(day) &  day > 11
        day = 11;
    elseif isnumeric(day) 
        day = param.day;
    elseif strcmpi(day,'all')    % param.day = 'all'
        % 12 days + 6 extra days
        % Day0-11, '1week after..','distractor','combined pattern','6weeks after..','6weeks-distractor','6weeks-combined'
        day = 12 + 6;    
    end
    
    dayList = cell(1,day);
    for dayIter = 0:1:day  
        if dayIter <= 11
            dayList{dayIter+1} = {['Day',num2str(dayIter)]; ['Day ',num2str(dayIter)]};
        
        else
            switch dayIter          % do not change this order!!!
                case 12 
                    dayList{dayIter+1} = {'1 week';'1week';'distractor'};
                case 13
                    dayList{dayIter+1} = {'1 week';'1week';'combined'};
                case 14
                    dayList{dayIter+1} = {'1 week';'1week'};
                case 15
                    dayList{dayIter+1} = {'6 week';'6week';'distractor'};
                case 16
                    dayList{dayIter+1} = {'6 week';'6week';'combined'};
                case 17
                    dayList{dayIter+1} = {'6 week';'6week'};
            end
        end
    end

end