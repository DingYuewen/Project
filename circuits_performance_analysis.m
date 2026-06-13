function [non_robust_percent, switch_count_valid, mean_rEf] = circuits_performance_analysis(rEf)


[num_rows,num_cols] = size(rEf);
num_grps = num_cols / 4;
non_robust_count = 0;
non_robust_locations = [];
states = zeros(num_rows, num_grps);

switches = zeros(num_rows, 1);      % to count state switches
max_switches = num_grps - 1;        % maximum possible switches

% check robustness & distinct states
for row = 1:num_rows 
    for grp = 1:num_grps
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

non_robust_percent = non_robust_count / ( num_grps * num_rows );

rEf_states = zeros(num_rows, num_cols);

% Determine the states
for row = 1:num_rows
    for col = 1:num_cols
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

% Check for state switches
switch_count = 1;
switch_locations = [];
for col = 2:num_cols
    if ~isequal(rEf_states(:, col-1), rEf_states(:, col))
        switch_count = switch_count + 1;
        switch_locations = [switch_locations; col];
    end
end

% Check for state switches within groups
switch_count_valid = 1;
for grp = 1:num_grps-1
    grp_start = (grp-1)*4 + 1;
    grp_end = grp*4;
    next_grp_start = grp_end + 1;
    next_grp_end = next_grp_start + 3;

    % Check if there is a switch between groups
    if ~isequal(rEf_states(:, grp_end), rEf_states(:, next_grp_start))
        switch_count_valid = switch_count_valid + 1;
    end
end

% Mean firing rate
mean_rEf = mean(rEf(rEf > 0));

end