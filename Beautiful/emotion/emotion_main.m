function emotion_main(varargin)
% 
   
    options.subject_name = varargin{1};
    phase = varargin{2};
    cue = varargin{3};
    simulateSubj = false;
    if strcmp(options.subject_name, 'test')
        simulateSubj = true;
    end
    rng('shuffle')

    paths2Add = {'../lib/SpriteKit', '../lib/MatlabCommonTools/'}; 
    for ipath = 1 : length(paths2Add)
        if ~exist(paths2Add{ipath}, 'dir')
            error([paths2Add{ipath} ' does not exists, check the ../']);
        else
            addpath(paths2Add{ipath});
        end
    end
    
    options.home = getHome;
    
    switch cue
        case 'normalized'
            options.soundDir = [options.home '/sounds/Emotion_normalized/'];
        case 'intact'
            options.soundDir = [options.home '/sounds/Emotion/'];
        otherwise
            error('cue option does not exists')
    end

    if ~exist(options.soundDir, 'dir')
        error(['Sounds folder ' options.soundDir ' does not exists']);
    end
    if isempty(dir([options.soundDir '*.wav']))
        error([options.soundDir ' does not contain sound files']);
    end
    
    %% Setup experiment 
    options.result_path = [options.home '/results/Emotion/'];
    options.result_prefix = 'emo_';
    options.res_filename = [options.result_path, sprintf('%s%s.mat', options.result_prefix, options.subject_name)];
    
    [attempt, expe, options, results] = checkExpOptions(options, phase, cue);
    if isempty(attempt) && isempty(expe) && isempty(options) && isempty(results)
        return
    end
    %% Game Stuff 
    [G, Clown, Buttonup, Buttondown, gameCommands, Confetti, Parrot, Pool, ...
        Clownladder, Splash, ladder_jump11, clown_jump11, Drops, ExtraClown] = emotion_game; 
    G.onMouseRelease = @buttondownfcn;
    G.onKeyPress = @keypressfcn;

    starting = 0;   
    
    emotionvoices = classifyFiles(options.soundDir, phase);
    ladderStep = 1;
    %% ============= Main loop =============   
    for itrial = 1 : options.(phase).total_ntrials 
            
        if ~simulateSubj
            while starting == 0
                uiwait();
            end
        else
            gameCommands.State = 'empty';
        end
                
        if itrial == 1
            Clown.State = 'neutral';  
            if (strcmp(phase, 'training'))
                Clownladder.State = 'empty';
                 ExtraClown.State = 'empty';
                 Pool.State = 'empty'; 
            else
                Clownladder.State = 'ground';
                Pool.State = 'pool'; 
                ExtraClown.State = 'on';
            end
            Confetti.State = 'off';
        end      
        
        Buttonup.State = 'off';
        Buttondown.State = 'off';
        Parrot.State = 'neutral';
        pause(1);
        
        for clownState = 5:-1:1
            Clown.State = sprintf('clownSpotLight_%d',clownState);
            pause(0.01)
        end
        
        Parrot.State = 'parrot_1';
        pause(0.5)
       
        emotionVect = strcmp({emotionvoices.emotion}, expe.(phase).condition(itrial).voicelabel);
        phaseVect = strcmp({emotionvoices.phase}, phase);
        possibleFiles = [emotionVect & phaseVect];
        indexes = 1:length(possibleFiles);
        indexes = indexes(possibleFiles);
        
        if isempty(emotionvoices(indexes)) % extend structure with missing files and redo selection
            nLeft = length(emotionvoices);
            tmp = classifyFiles(options.soundDir, phase);
            emotionvoices(nLeft + 1 : nLeft + length(tmp)) = tmp;
            clear tmp
            emotionVect = strcmp({emotionvoices.emotion}, expe.(phase).condition(itrial).voicelabel);
            phaseVect = strcmp({emotionvoices.phase}, phase);
            possibleFiles = [emotionVect & phaseVect];
            indexes = 1:length(possibleFiles);
            indexes = indexes(possibleFiles);
        end
    
        %this should store all names of possibleFiles 
        toPlay = randperm(length(emotionvoices(indexes)),1);
        [y, Fs] = audioread([options.soundDir emotionvoices(indexes(toPlay)).name]);
        player = audioplayer(y, Fs);
        iter = 1;
        play(player)
        while true
            Parrot.State = ['parrot_' sprintf('%i', mod(iter, 2) + 1)];
            iter = iter + 1;
            pause(0.2);
            if ~isplaying(player)
                Parrot.State = 'neutral';
                break;
            end
        end
        tic(); 
        if simulateSubj
            response.timestamp = now;
            response.response_time = toc;
            response.button_clicked = randi([0, 1], 1, 1); % default in case they click somewhere else
            buttonsID = {'no', 'yes';};
            response.buttonID = buttonsID{response.button_clicked + 1};
            response.correct = (response.button_clicked == expe.(phase).condition(itrial).congruent);
            response.filename = emotionvoices(indexes(toPlay)).name;
        else
            clickClown2continue = true;
            uiwait
            clickClown2continue = false;
        end % if simulateSubj
        
        for clownState = 1:5
            Clown.State = sprintf('clownSpotLight_%d',clownState);
            pause(0.01)
        end
        Clown.State = expe.(phase).condition(itrial).facelabel;
        pause(0.6)
        
        Buttonup.State = 'on';
        Buttondown.State = 'on';
        
        if ~simulateSubj
            uiwait();
            pause(0.5)
            Buttonup.State = 'off';
            Buttondown.State = 'off';
        else
            response.button_clicked = randi([0,1]);
            Buttonup.State = 'press';
            response.timestamp = now();
            response.response_time = toc();
            response.respButton = 'no';
            if response.button_clicked
                response.respButton = 'yes';
            end
        end
        
       response.filename = emotionvoices(indexes(toPlay)).name;
       response.correct = (response.button_clicked == expe.(phase).condition(itrial).congruent);
       if response.correct
            for confettiState = 1:7
                Confetti.State = sprintf('confetti_%d', confettiState);
                pause(0.2)
            end
            Confetti.State = 'off';
            pause(0.3)
        else
            for shakeshake = 1:2
                for parrotshake = 1:3
                    Parrot.State = sprintf('parrot_shake_%d', parrotshake);
                    pause(0.2)
                end
            end
        end % if response.correct
    
        fprintf('Clicked button: %d\n', response.button_clicked);
        fprintf('Response time : %d ms\n', round(response.response_time*1000));
        fprintf('Response correct: %d\n\n', response.correct);

        response.condition = expe.(phase).condition(itrial);
        results.(phase).(cue).att(attempt).responses(itrial) = response;
        
        save(options.res_filename, 'options', 'expe', 'results');
        
        if expe.test.condition(itrial).clownladderNmove ~= 0
            if (strcmp(phase, 'test'))
                if ~ expe.test.condition(itrial).splash
                    for iState = 1 : expe.test.condition(itrial).clownladderNmove
                        Clownladder.State = sprintf('clownladder_%d%c',mod(ladderStep, 9),'a');
                        pause (0.2)
                        Clownladder.State = sprintf('clownladder_%d%c',mod(ladderStep, 9),'b');
                        pause (0.2)
                        ladderStep = ladderStep + 1;
                    end
                else
                    Clownladder.State = sprintf('clownladder_%d%c',mod(ladderStep, 9),'a');
                    pause (0.2)
                    Clownladder.State = sprintf('clownladder_%d%c',mod(ladderStep, 9),'b');
                    pause (0.2)
                    for ijump = 1:10
                        Clownladder.State = sprintf('clownladder_jump_%d', ijump);
                        pause(0.2)
                    end
                    Clownladder.State = 'empty';
                    ladder_jump11.State = 'ladder_jump_11';
                    clown_jump11.State = 'clown_jump_11';
                    for isplash = 1:3
                        Splash.State = sprintf('sssplash_%d', isplash);
                        pause(0.1)
                    end
                    pause (0.5)
                    Splash.State = 'empty';
                    ladder_jump11.State = 'empty';
                    clown_jump11.State = 'empty';
                    ExtraClown.State = 'empty';
                    Clownladder.State = 'ground';
                    ladderStep = 1;
                    for idrop = 1:2
                        Drops.State = sprintf('sssplashdrops_%d', idrop);
                        pause(0.2)
                    end
                    Drops.State = 'empty';
                end
            end
        end
        
        if itrial == options.(phase).total_ntrials
            gameCommands.Scale = 2; 
            gameCommands.State = 'finish';
         end
        
        % remove just played file from list of possible sound files
        emotionvoices(indexes(toPlay)) = [];
        
    end

%% embedded game functions    
    
    function buttondownfcn(hObject, callbackdata)
        
        locClick = get(hObject,'CurrentPoint');
        if starting == 1
            % tumb's up
            if (locClick(1) >= Buttonup.clickL) && (locClick(1) <= Buttonup.clickR) && ...
                    (locClick(2) >= Buttonup.clickD) && (locClick(2) <= Buttonup.clickU)
                if strcmp(Clown.State, expe.(phase).condition(itrial).facelabel)
                    Buttonup.State = 'press';
                    response.timestamp = now();
                    response.response_time = toc();
                    response.button_clicked = 1;
                    response.respButton = 'yes';
                    uiresume
                end
            end
            % tumb's down
            if (locClick(1) >= Buttondown.clickL) && (locClick(1) <= Buttondown.clickR) && ...
                    (locClick(2) >= Buttondown.clickD) && (locClick(2) <= Buttondown.clickU)
                if strcmp(Clown.State, expe.(phase).condition(itrial).facelabel)
                    Buttondown.State = 'press';
                    response.timestamp = now();
                    response.response_time = toc();
                    response.respButton = 'no';
                    response.button_clicked = 0; % default in case they click somewhere else
                    uiresume
                end
            end
            
            if (locClick(1) >= Clown.clickL) && (locClick(1) <= Clown.clickR) && ...
                    (locClick(2) >= Clown.clickD) && (locClick(2) <= Clown.clickU)
                if clickClown2continue
                    Clown.State = expe.(phase).condition(itrial).facelabel;
                    uiresume;
                    tic();
                end
            end
        else %  else of 'if starting == 1'
            if (locClick(1) >= gameCommands.clickL) && (locClick(1) <= gameCommands.clickR) && ...
                    (locClick(2) >= gameCommands.clickD) && (locClick(2) <= gameCommands.clickU)
                starting = 1;
                gameCommands.State = 'empty';
                pause (1)
                uiresume();
            end
        end
        
    end % buttondownfcn function
   
%     function keypressfcn(~,e)
%         if strcmp(e.Key, 'control') % OR 'space'
%             uiresume;
%             tic();
%         end
%     end
  
    for iPath = 1 : length(paths2Add)
        rmpath(paths2Add{iPath});
    end

end




     
