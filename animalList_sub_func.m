function [animalList] = animalList_sub_func(animal_number)

    animalList = cell(1,animal_number); 
    for animalIter = 1:1:animal_number
        animalList{animalIter} = {['Animal',num2str(animalIter)]; ['Animal ',num2str(animalIter)]};
    end
        
end