
participant.name = 'test';
participant.age = 5;
participant.sex = 'f';
participant.language = 'Dutch'; % or English
% participant tasks set is specified through the name of the directories holding the experiments
participant.expDir = {'MCI', 'NVA', 'fishy', 'emotion', 'gender'};



%% do not edit from here
participant.kidsOrAdults = 'Kid';
if participant.age > 18
    participant.kidsOrAdults = 'Adult';
end

%     participant.sentencesCourpus = 'VU_zinnen';
