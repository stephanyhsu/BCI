clear all;
userName = 'hsuyun';
passFile = 'hsu_ieeglogin.bin';
% Get data from ieeg portal
[training_ecog, training_dg, testing_ecog]=getDataFromIEEG(userName, passFile);
predicted_dg = make_predictions(testing_ecog');
save('predicted_dg.mat','predicted_dg');