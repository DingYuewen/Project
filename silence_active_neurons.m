function V_ThreshE_all = silence_active_neurons(V_ThreshE_all, stim_groups, rEf_indv, Ntrials)
% silence_active_neurons is used to silence the neurons spiking the most in
% either each group (group) or the overall circuits (global).
% vE
% V_ThreshE
% stim_groups
% NE
% spikesE
seed = 42;
rng(seed);

num_silenced = 20;
condition = "ctrl_group";

for trial = 1:Ntrials
    V_ThreshE = V_ThreshE_all(:,trial);

    switch condition
        case "ctrl_global"
            spk_grp = [];
            for i = stim_groups
                spk_grp = [spk_grp, 100*(i-1)+1 : 100*i];
            end
            neurons = spk_grp(randperm(length(spk_grp), num_silenced));
            V_ThreshE(neurons) = V_ThreshE(neurons) + 1;
        case "ctrl_group"
            for i = stim_groups
                group_indices = 100*(i-1)+1 : 100*i;
                rand_indices = group_indices(randperm(length(group_indices), num_silenced));
                neurons = zeros(1, num_silenced);
                for j = 1:num_silenced
                    neuron = rand_indices(j);
                    neurons(j) = neuron;
                    V_ThreshE(neuron) = V_ThreshE(neuron) + 1;
                end
            end
        case "global"
            [rEf_indv_max_values, rEf_indv_max_indices] = maxk(rEf_indv(:,trial), num_silenced); 
            neurons = zeros(1,num_silenced);
            for j = 1:num_silenced
                neuron = rEf_indv_max_indices(j);
                neurons(j) = neuron;
                V_ThreshE(neuron) = V_ThreshE(neuron) + 1;
            end
        case "group"
            for i = stim_groups
                [rEf_indv_max_values, rEf_indv_max_indices] = maxk(rEf_indv(100*(i-1)+1 : 100*i, trial), num_silenced);
                % disp(rEf_indv_max_values)
                % disp(rEf_indv_max_indices)
                % Silence the neurons spiking the most
                neurons = zeros(1, num_silenced*length(stim_groups));
                for j = 1:num_silenced
                    neuron = 100*(i-1) + rEf_indv_max_indices(j);
                    neurons(j) = neuron;
                    V_ThreshE(neuron) = V_ThreshE(neuron) + 1;
                end
            end
    end
    V_ThreshE_all(:,trial) = V_ThreshE;

end