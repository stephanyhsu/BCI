function [predicted_dg] = make_predictions(test_ecog)
    %% Load existing datasets
    load('B_subj1.mat');
    load('B_subj2.mat');
    load('B_subj3.mat');
    load('FitInfo_subj1.mat');
    load('FitInfo_subj2.mat');
    load('FitInfo_subj3.mat');
    load('svm.mat');
    
    BAll = {B1,B2,B3};
    FitInfoAll = {FitInfo1,FitInfo2,FitInfo3};
    predicted_dg = cell(3,1);
    %% Predict
    for subjectNum = 1:3 
       % Get number of channels
       if (subjectNum == 1)
            numChannels = 62;
        elseif (subjectNum == 2)
            numChannels = 48;
        elseif (subjectNum == 3)
            numChannels = 64;
       end
        %% Define 6-Features
        Fs = 1000;
        winLen = 100E-3*Fs;
        overlap = 50E-3*Fs;
        winDisp = winLen - overlap;

        for channelNum = 1:numChannels
            testSig = test_ecog{subjectNum}(:,channelNum);
            [PSD,freq,T] = spectrogram(testSig,winLen,overlap,1024,Fs);

            xLen = length(testSig);
            ni = mod(xLen-winLen+winDisp, winDisp);
            s = fix((xLen-winLen+winDisp)/winDisp);
            featValues = zeros(1,s);
            i = 1;
            for t = ni:winDisp:xLen-winLen
                featValues(i) = sum(testSig(t+1:t+winLen));
                i = i+1;
            end

            F1 = featValues/winLen;
            F2 = mean(abs(PSD((freq >= 5 & freq <= 20),:)));
            F3 = mean(abs(PSD((freq >= 20 & freq <= 75),:)));
            F4 = mean(abs(PSD((freq >= 75 & freq <= 125),:)));
            F5 = mean(abs(PSD((freq >= 125 & freq <= 160),:)));
            F6 = mean(abs(PSD((freq >= 170 & freq <= 185),:)));

            FMatrixTest(1+(channelNum-1)*6,:) = F1;
            FMatrixTest(2+(channelNum-1)*6,:) = F2;
            FMatrixTest(3+(channelNum-1)*6,:) = F3;
            FMatrixTest(4+(channelNum-1)*6,:) = F4;
            FMatrixTest(5+(channelNum-1)*6,:) = F5;
            FMatrixTest(6+(channelNum-1)*6,:) = F6;
        end

        TestFMatrix = FMatrixTest;
        %% Build testing R matrix
        n = numChannels*6;         
        N = 4;         
        M = length(TestFMatrix)+1;

        spikeDataTest= [TestFMatrix(:,1:1+(N-1)) TestFMatrix];

        Rtest = ones(M,1);
        for j=1:n
            for i=1:N
                Rtest = [Rtest spikeDataTest(j, i:i+M-1)'];
            end
        end
        %% Apply Lasso 
        B = BAll{subjectNum};
        FitInfo = FitInfoAll{subjectNum};
        Y1 = Rtest * B{1} + repmat(FitInfo{1}.Intercept,size(Rtest,1),1);
        Y2 = Rtest * B{2} + repmat(FitInfo{2}.Intercept,size(Rtest,1),1);
        Y3 = Rtest * B{3} + repmat(FitInfo{3}.Intercept,size(Rtest,1),1);
        Y4 = Rtest * B{4} + repmat(FitInfo{4}.Intercept,size(Rtest,1),1);
        Y5 = Rtest * B{5} + repmat(FitInfo{5}.Intercept,size(Rtest,1),1);
        %% Find the one with minimum MSE
        Y1 = Y1(:,FitInfo{1}.IndexMinMSE);
        Y2 = Y2(:,FitInfo{2}.IndexMinMSE);
        Y3 = Y3(:,FitInfo{3}.IndexMinMSE);
        Y4 = Y4(:,FitInfo{4}.IndexMinMSE);
        Y5 = Y5(:,FitInfo{5}.IndexMinMSE);
        %% Get predicted result
        uYtest = [Y1,Y2,Y3,Y4,Y5];
        %% apply SVM
        addpath('lib');
        svmStruct = svm{subjectNum};
        [predicted_label1, accuracy, prob_estimates] = svmpredict(zeros(length(uYtest),1), uYtest(:,1), svmStruct{1});
        [predicted_label2, accuracy, prob_estimates] = svmpredict(zeros(length(uYtest),1), uYtest(:,2), svmStruct{2});
        [predicted_label3, accuracy, prob_estimates] = svmpredict(zeros(length(uYtest),1), uYtest(:,3), svmStruct{3});
        [predicted_label4, accuracy, prob_estimates] = svmpredict(zeros(length(uYtest),1), uYtest(:,4), svmStruct{4});
        [predicted_label5, accuracy, prob_estimates] = svmpredict(zeros(length(uYtest),1), uYtest(:,5), svmStruct{5});
        uYtest(:,1) = predicted_label1.*uYtest(:,1);
        uYtest(:,2) = predicted_label2.*uYtest(:,2);
        uYtest(:,3) = predicted_label3.*uYtest(:,3);
        uYtest(:,4) = predicted_label4.*uYtest(:,4);
        uYtest(:,5) = predicted_label5.*uYtest(:,5);
        %% Interpolate + Filter
        len = length(test_ecog{subjectNum});
        load('FIRLowPassNew.mat');
        X = (50:50:len)';
        XX = (50:len)';
        YY = zeros(length(XX),5);
        for finger=1:5
            Y = uYtest(:,finger);
            YY(:,finger) = spline(X,Y,XX);
        end
        YY = [zeros(49,5);YY];
        YY = filtfilt(Num,1,YY);
        predicted_dg{subjectNum} = YY;
    end
end
