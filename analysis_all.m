clear;

% name and number of files to process
Nfiles = 9; 
file_prefix1 = ['AELIF_ISNnet_noad_RK6613e_NE100_NP10_netr'];
file_netr = 9;
file_prefix2 = ['_netc'];
file_suffix = '.mat';

nonRobust_vary = zeros(Nfiles,1);
efficiency_vary = zeros(Nfiles,1);
states_vary = zeros(Nfiles,2);
firing_rate_vary = zeros(Nfiles,1);

for file_idx = 1:Nfiles
    filename = strcat(file_prefix1, num2str(file_netr), file_prefix2, num2str(file_idx), file_suffix);
    
    if isfile(filename)
        load(filename, 'rEf');
    else
        disp(['File not found: ', filename]);
        continue;
    end
    
    [Nrows,Ncols] = size(rEf);
    Ngrps = Ncols / 4;
    non_robust_count = 0;
    non_robust_locations = [];
    states = zeros(Nrows, Ngrps);
    
    switches = zeros(Nrows, 1);      % count state switches
    max_switches = Ngrps - 1;        % maximum possible switches
    
    % check robustness & distinct states
    for row = 1:Nrows 
        for grp = 1:Ngrps
            elements = rEf(row, (grp-1)*4 + 1 : grp*4);
    
            num_spikes = sum(elements > 0);
            if (num_spikes == 4)
                states(row, grp) = 1;
            elseif num_spikes == 0
                states(row, grp) = 0;
            elseif num_spikes == 3
                states(row, grp) = 1;
            elseif num_spikes == 1
                states(row, grp) = 0;
            else
                states(row, grp) = 0.5;
            end
    
            if ~( all(elements == 0 ) || all(elements ~= 0) )
                non_robust_count = non_robust_count + 1;
                non_robust_locations = [non_robust_locations; row, (grp-1)*4 + 1];
            end
    
        end
    end
    
    non_robust_percent = non_robust_count / ( Ngrps * Nrows );
    nonRobust_vary(file_idx) = non_robust_percent;

    % disp('Locations: (pool, starting column): ')
    % disp(non_robust_locations);
    
    % disp('State matrix:');
    % disp(states);
    
    rEf_states = zeros(Nrows, Ncols);
    
    % determine the states
    for row = 1:Nrows
        for col = 1:Ncols
            if rEf(row, col) ~= 0
                rEf_states(row, col) = 1;
            else
                rEf_states(row, col) = 0;
            end
        end
    end
    
    % Display the states
    % disp('rEf_states:');
    % disp(rEf_states);
    
    % check for state switches
    switch_count = 1;
    switch_locations = [];
    for col = 2:Ncols
        if ~isequal(rEf_states(:, col-1), rEf_states(:, col))
            switch_count = switch_count + 1;
            switch_locations = [switch_locations; col];
        end
    end
    
    % check for state switches within groups
    switch_count_valid = 1;
    for grp = 1:Ngrps-1
        grp_start = (grp-1)*4 + 1;
        grp_end = grp*4;
        next_grp_start = grp_end + 1;
        next_grp_end = next_grp_start + 3;
    
        % check if there is a switch between groups
        if ~isequal(rEf_states(:, grp_end), rEf_states(:, next_grp_start))
            switch_count_valid = switch_count_valid + 1;
        end
    end

    states_vary(file_idx,1) = switch_count;
    states_vary(file_idx,2) = switch_count_valid;
    efficiency_vary(file_idx) = switch_count / Ngrps;

    % mean firing rate
    firing_rate_vary(file_idx) = mean(rEf(rEf > 0));

    % display the result
    disp(['File: ', filename]);

    disp(['Number of non-robust groups: ', num2str(non_robust_count)]);
    disp(['Percentage of non-robust groups: ', num2str(non_robust_percent)]);
    disp(['Number of state switches: ', num2str(switch_count), ' out of ', num2str(Ncols)]);
    % disp(switch_locations);
    disp(['Number of valid state switches: ', num2str(switch_count_valid), ' out of ', num2str(Ngrps)]);
    % disp(loc);
    disp(['total / valid: ', num2str(switch_count), ' / ', num2str(switch_count_valid)])
    disp(['State switching efficiency: ', num2str(switch_count / Ngrps)]);
    
    % disp(['Percentage of states switches: ', num2str(all_switch_percentage)]);
    disp(['Mean firing rate: ', num2str(firing_rate_vary(file_idx))]);
    disp(' ')
end

disp('End of analysis')
