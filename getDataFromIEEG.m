function [training_ecog, training_dg, testing_ecog]=getDataFromIEEG(userName, passFile)

    %%
    % Initial Setup
    % Let's add the toolbox and all subdirectories to the path
    warning('off');
    addpath(genpath('ieeg-matlab-1.8.3'));
    addpath('lib'); % for getAllAnnotations

    %%
    % Check existence of data
    if ~exist('training_ecog.mat') 
        % Get data and then save it for future references
        disp 'downloading data from the IEEG server. . .'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        session = IEEGSession('I521_A0012_D001', userName, passFile); % 310000x62
        session.openDataSet('I521_A0012_D002'); % 310000x5
        session.openDataSet('I521_A0012_D003'); % 147500x62

        session.openDataSet('I521_A0013_D001'); % 310000x48
        session.openDataSet('I521_A0013_D002'); % 310000x5
        session.openDataSet('I521_A0013_D003'); % 147500x48

        session.openDataSet('I521_A0014_D001'); % 310000x64
        session.openDataSet('I521_A0014_D002'); % 310000x5
        session.openDataSet('I521_A0014_D003'); % 147500x64

        disp 'sessions made . .'

        % Initial Setup - start session
        disp '-----------------sub1--------------'
        training_ecog{1} = session.data(1).getvalues(1:310000,1:62);
        training_dg{1} = session.data(2).getvalues(1:310000,1:5);
        testing_ecog{1} = session.data(3).getvalues(1:147500,1:62);

        disp '-----------------sub2--------------'
        training_ecog{2} = session.data(4).getvalues(1:310000,1:48);
        training_dg{2} = session.data(5).getvalues(1:310000,1:5);
        testing_ecog{2} = session.data(6).getvalues(1:147500,1:48);

        disp '-----------------sub3--------------'
        training_ecog{3} = session.data(7).getvalues(1:310000,1:64);
        training_dg{3} = session.data(8).getvalues(1:310000,1:5);
        testing_ecog{3} = session.data(9).getvalues(1:147500,1:64);

        % Save data for next time
        save('training_ecog.mat','training_ecog');
        save('training_dg.mat','training_dg');
        save('testing_ecog.mat','testing_ecog');
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else
        % Load data from last time
        disp 'loading exiting channel data . . .'
        load('training_ecog.mat');
        load('training_dg.mat') ;
        load('testing_ecog.mat') ;
    end
    
end