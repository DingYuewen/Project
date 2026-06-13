
files = dir('sd1/*.mat');
Nfiles = length(files);

X = zeros(Nfiles, 2);
Y = zeros(Nfiles, 1);

% Weights
w1 = 1;     % robustness
w2 = 1;     % discriminability
w3 = -0.5;   % firing rate penalty

for i = 1:10
    tic

    filepath = fullfile(files(i).folder, files(i).name);
    data = load(filepath);
    close all;
    rEf = data.rEf;
    sigVth = data.sigVth;
    W_EE = data.Wscale;

    [non_robust_percent, switch_count_valid, mean_rEf] = circuits_performance_analysis(rEf);
    robustness = 1 - non_robust_percent;
    Y(i) = w1*robustness + w2*switch_count_valid + w3*mean_rEf;
    X(i,:) = [sigVth, W_EE];

    disp(['sigVth: ', num2str(sigVth), ', W_EE: ', num2str(W_EE)]);
    disp(['Performance score: ', num2str(Y(i))]);
    toc
    disp(' ');
end
