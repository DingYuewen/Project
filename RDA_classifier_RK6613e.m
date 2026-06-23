%% Criteria for robustness, discriminability, firing rate:
% robustness >= 0.95; switch_count_valid >= 28/30; 0 < mean_rEf <= 20

files = dir('sd2/*.mat');
Nfiles = length(files);

%% Labels to calculate Y
Y_class = zeros(Nfiles, 1);
for i = 1:Nfiles
    tic
    filepath = fullfile(files(i).folder, files(i).name);
    data = load(filepath); close all;

    rEf = data.rEf;
    sigVth = data.sigVth;
    W_EE = data.Wscale;
    
    [non_robust_percent,...
        switch_count_valid,...
        mean_rEf] = circuits_performance_analysis(rEf);
    robustness = 1 - non_robust_percent;

    circuit_good = robustness >= 0.95 && ...
        switch_count_valid >= 28 && ...
        mean_rEf > 0 && ...
        mean_rEf <= 20;

    Y_class(i) = circuit_good;
    X(i,:) = [sigVth, W_EE];

    disp(['sigVth: ', num2str(sigVth), ', W_EE: ', num2str(W_EE)]);
    toc
end

%% RDA training
Md1 = fitcdiscr(X, Y_class, ...
    'DiscrimType','linear');

Md2 = fitcsvm(X, Y_class, ...
    'KernelFunction','gaussian', ...
    'Standardize', true);

%% test
cv = cvpartition(Y_class, 'Leaveout');
accuracy = zeros(cv.NumTestSets,1);
for j = 1:cv.NumTestSets
    trainIdx = training(cv,j);
    testIdx = test(cv,j);
    Md1 = fitcdiscr(X(trainIdx,:), Y_class(trainIdx), ...
        'DiscrimType','linear');
    Md2 = fitcsvm(X(trainIdx,:), Y_class(trainIdx), ...
        'KernelFunction','gaussian', ...
        'Standardize', true);
    pred = predict(Md2,X(testIdx,:));
    accuracy(j) = pred == Y_class(testIdx);
end
mean_accuracy = mean(accuracy);
disp(mean_accuracy);

%% plot
[sigVth_grid, W_EE_grid] = meshgrid(linspace(0,0.004,100),...
    linspace(0.9,1.3,100));
Xgrid = [sigVth_grid(:),W_EE_grid(:)];

[label, score] = predict(Md2,Xgrid);
prob_good = score(:,2);
prob_map = reshape(prob_good,size(sigVth_grid));

imagesc(linspace(0,0.004,100),...
    linspace(0.9,1.3,100), ...
    prob_map);
colorbar;
xlabel('\sigma_{Vth}(mV)');
xticklabels([0:0.5:4]);
ylabel('W_{EE}');

