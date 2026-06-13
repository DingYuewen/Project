% AELIF_ISNnet_stim_noad_RK6613e_grid.m
clear
seed = 2;
rng(seed);

Npools = 10;                % Number of distinct inhibition-stabilized cell-groups

NEpool = 100;               % No. of excitatory cells per group
NIpool = 50;                % No. of inhibitory cells per group
    
pconnEE = 0.06;             % Connection probability E-to-E
pconnEI = 0.06;             % Connection probability E-to-I
pconnIE = 0.12;              % Connection probability I-to-E
pconnII = 0.12;              % Connection probability I-to-I

background_noise = 1;       % add background noise
remove_self = 1;            % removes self-connections
latin_square_flag = 1;      % stops each cell being identical if 0
normalize_pools = 1;        % makes each pool approx equal if 1

fig_select = 17;

%% These values are used for extracting connections from the latin square, 
%  whic is used to ensure equal incoming (and outgoing) connections per
%  neuron.
if ( NEpool > NIpool )
    NEE = round(NEpool*pconnEE);    
    NEI = round(NIpool*pconnEI);    
    NIE = round(NIpool*pconnIE);
    NII = round(NIpool*pconnII);
else
    NEE = round(NEpool*pconnEE);
    NEI = round(NEpool*pconnEI);
    NIE = round(NEpool*pconnIE);
    NII = round(NIpool*pconnII);
end

NE = Npools*NEpool;         % Number of excitatory cells in total
NI = Npools*NIpool;         % Number of inhibitory cells in total

%% Simulations parameters
dt = 1e-3;                  % time-step of RK-4 method
tmax = 3;                   % maximum time of each trial
tvec = 0:dt:tmax;           % time vector of time points
Nt = length(tvec);          % number of time points

N_repeat_trials = 4;        % number of times to repeat same trial for consistence
N_vary_trials = 30;         % number of types of trial with distinct inputs
Ntrials = N_vary_trials*N_repeat_trials;    % total number of trials

%% Generate figure windows for later background plotting
for i = 1:4*N_repeat_trials
    h(i) = figure(i);
    h(Ntrials+i) = figure(Ntrials+i);
end
h(2*Ntrials + 1 ) = figure(2*Ntrials + 1);
h(2*Ntrials + 2 ) = figure(2*Ntrials + 2);

%% Set up the grid of parameters to be varied or held constant across types of trial
% The following set of flags should have at most two 1s indicating which
% parameters are varied across the rows and columns of the grid.
change_sigC = 0;
change_Vth = 0;
change_sigVth = 1;
change_GL = 0;
change_sigGL = 0;
change_Wscale = 1;
change_noise_scale = 0;

% The following set of vectors indicate the values they will take within
% the grid being tested if the corresponding flag is a 1.
sigC_vec = [0:0.02:0.5];
Vth_vec = [-0.053:0.0005:-0.048];
sigVth_vec = 0:0.0005:0.004;
GL_vec = 8.5e-9:2.5e-10:8.5e-9;
sigGL_vec = 0:0.025:0.15;
Wscale_vec = 0.9:0.05:1.3;  % Now Wscale_vec only controls E-to-E cells
noise_scale_vec = 0:0.1:1;

% The following set of valyes are the default values for parameters that
% are not varied (the corresponding flag is a 0).
Vth0 = -0.050;
sigVth0 = 0.0;
sigC0 = 0.0;
GL0 = 10e-9;
sigGL0 = 0;
Wscale0 = 1;
noise_scale0 = 0;

% default is to have a vector, not a grid of parameters, if fewer than 2
% are varied
grid_on = 0;        
if ( change_sigC + change_Vth + change_sigVth + change_GL + ... 
        change_sigGL + change_Wscale + change_noise_scale > 1 )
    grid_on = 1;        % Need a grid if more than 1 parameter is varied
end

% If there are two paraneters varied, set the unvaried ones to their
% default values and create a meshgrid (rows vary one parameter while
% columns vary the other parameter) for the two varied parameters
if ( grid_on == 1 )
    if ( ( change_GL > 0 ) && ( change_sigGL > 0 ) )
        [GL_grid, sigGL_grid] = meshgrid(GL_vec,sigGL_vec);
        Vth_grid = Vth0*ones(size(GL_grid));
        sigVth_grid = sigVth0*ones(size(Vth_grid));
        sigC_grid = sigC0*ones(size(Vth_grid));
        Wscale_grid = Wscale0*ones(size(Vth_grid));
    else
        if ( change_sigC == 0 )
            [Vth_grid, sigVth_grid] = meshgrid(Vth_vec,sigVth_vec);
            sigC_grid = sigC0*ones(size(Vth_grid));
        end
        
        if ( change_Vth == 0 )
            [sigC_grid, sigVth_grid] = meshgrid(sigC_vec,sigVth_vec);
            Vth_grid = Vth0*ones(size(sigC_grid));
        end
        
        if ( change_sigVth == 0 )
            [Vth_grid, sigC_grid] = meshgrid(Vth_vec,sigC_vec);
            sigVth_grid = sigVth0*ones(size(Vth_grid));
        end
        Wscale_grid = Wscale0*ones(size(Vth_grid));
        sigGL_grid = sigGL0*ones(size(Vth_grid));
    end
    if ( change_Wscale == 1 ) 
        if ( change_sigGL > 0 )
            [Wscale_grid, sigGL_grid] = meshgrid(Wscale_vec,sigGL_vec);
            Vth_grid = Vth0*ones(size(Wscale_grid));
            sigVth_grid = sigVth0*ones(size(Vth_grid));
            sigC_grid = sigC0*ones(size(Vth_grid));
        end
        if ( change_sigVth > 0 )
            [Wscale_grid, sigVth_grid] = meshgrid(Wscale_vec,sigVth_vec);
            GL_grid = GL0*ones(size(Wscale_grid));
            sigGL_grid = sigGL0*ones(size(GL_grid));
            sigC_grid = sigC0*ones(size(GL_grid));
        end
    end
    
    %noise_scale_grid = noise_scale0*ones(size(Vth_grid));
    noise_scale_grid = noise_scale0*ones(size(GL_grid));
    if ( change_noise_scale == 1 )
        [Vth_grid, noise_scale_grid] = meshgrid(Vth_vec,noise_scale_vec);
        Wscale_grid = Wscale0*ones(size(Vth_grid));
        sigVth_grid = sigVth0*ones(size(Vth_grid));
        sigC_grid = sigC0*ones(size(Vth_grid));
    end
    
    %GL_grid = GL0*ones(size(Vth_grid));
    Vth_grid = Vth0*ones(size(GL_grid));
    
    %[num_netrows,num_netcols] = size(Vth_grid);
    [num_netrows,num_netcols] = size(GL_grid);
    
else
    % this is if there is only one parameter varied: if a new one is varied
    % it will need to be incorporated in this section
    if ( change_sigC == 1 )
        num_nets = length(sigC_vec);
    end
    if ( change_Vth == 1 )
        num_nets = length(Vth_vec);
    end
    if ( change_sigVth == 1 )
        num_nets = length(sigVth_vec);
    end
    num_netrows = num_nets;
    num_netcols = 1;
end

% Initially define the arrays of results as zeros
if ( grid_on == 1 )
    mean_r_array = zeros(num_netrows,num_netcols);
    worst_r_array = zeros(num_netrows,num_netcols);
    bad_r_array = zeros(num_netrows,num_netcols);
    mean_xr_array = zeros(num_netrows,num_netcols);
    mean_rE_array = zeros(num_netrows,num_netcols);
    mean_rI_array = zeros(num_netrows,num_netcols);
else
    mean_r_array = zeros(1,num_nets);
    worst_r_array = zeros(1,num_nets);
    bad_r_array = zeros(1,num_nets);
    mean_xr_array = zeros(1,num_nets);
    mean_rE_array = zeros(1,num_nets);
    mean_rI_array = zeros(1,num_nets);
end

%% Now loop through all the simulations of trials
for net_row = 1:num_netrows
    for net_col = 1:num_netcols
        
        if ( grid_on == 1 )
            % ensure the correct parameter set is used for this set of
            % trials
            V_Thresh = Vth_grid(net_row,net_col);
            sigVth = sigVth_grid(net_row,net_col);
            sigC = sigC_grid(net_row,net_col);
            GL0 = GL_grid(net_row,net_col);
            sigGL = sigGL_grid(net_row,net_col);
            Wscale = Wscale_grid(net_row,net_col);
            noise_scale = noise_scale_grid(net_row,net_col);
        else
            % If only one parameter is varied things are done a little
            % differently, just setting the parameter one by one
            network = net_row

            if ( change_Vth == 1 )
                V_Thresh = Vth_vec(network);
            else
                V_Thresh = Vth0;         % Threshold potential (V)
            end
            if ( change_sigC == 1 )
                sigC = sigC_vec(network);
            else
                sigC = sigC0;
            end
            if ( change_sigVth == 1 )
                sigVth = sigVth_vec(network);
            else
                sigVth = sigVth0;
            end
        end
        
        % Display progress to the screen
        disp(['net_row: ',num2str(net_row),'  net_col: ',num2str(net_col), ...
            '  num_netrows: ',num2str(num_netrows),'  num_netcols: ',num2str(num_netcols)])
        
        disp(['Vth: ',num2str(V_Thresh),'  sigVth: ',num2str(sigVth),'  sigC: ',num2str(sigC) , ...
            '  GL0: ',num2str(GL0),'  sigGL: ',num2str(sigGL),' Wscale: ',num2str(Wscale), ...
            ' noise_scale: ',num2str(noise_scale)])
        
        rEf = zeros(Npools,Ntrials);
        rIf = zeros(Npools,Ntrials);
        rEf_indv = zeros(NE,Ntrials);

        V_ThreshE_all = zeros(NE,Ntrials);
        V_ThreshI_all = zeros(NI,Ntrials);
        
        % Parameters for excitatory and inhibitory noise input to cells
        gnoise_E = 0.25e-9*noise_scale;     % Excitatory noise conductance
        gnoise_I = 0.25e-9*noise_scale;     % Inhibitory noise conductance
        rnoise_EE = 600;                    % E noise input rate to E cells
        rnoise_IE = 600;                    % I noise input rate to E cells
        rnoise_EI = 400;                    % E noise input rate to I cells
        rnoise_II = 400;                    % I noise input rate to I cells
        
        tau_noiseE = 0.010;                 % Time constant of excitatory noise inputs
        tau_noiseI = 0.010;                 % Time constant of inhibitory noise inputs
        
        %% List of Cell Parameters for the simulation
        
        G_LE = GL0*(1-sigGL+2*sigGL*rand(NE,1));    % E-cell leak conductance (S)
        G_LI = GL0*(1-sigGL+2*sigGL*rand(NI,1));    % I-cell leak conductance (S)
        C = 100e-12;                % Capacitance (F)
        E_L = -70e-3;               % Leak potential (V)       
        V_Reset = -80e-3;           % Reset potential (V)        
        Vmax = 50e-3;               % level of voltage to detect a spike
        
        Iapp0E = 1.5e-10;           % Base applied current to E cells
        Iapp0I = -1.5e-10;          % Base applied current to I cells
        
        deltaT = 3e-3;              % Threshold shift factor (V)
        tauw = 150e-3;              % Adaptation time constant (s)
        a = 0e-9;                   % adaptation recovery (S)
        bEmax = 0.00e-9;            % Step increase in adaptation per spike (E cells)
        bImax = 0;                  % Step increase in adaptation per spike (I cells)
        bE = bEmax*rand(NE,1);      % E cell by E cell adaptation strength (A)
        bI = bImax*rand(NI,1);      % I cell by I cell adaptation strength (A)
        
        CE = C*(1-sigC + 2*sigC*rand(NE,1));    % Capacitance of each E cell 
        CI = C*(1-sigC + 2*sigC*rand(NI,1));    % Capacitance of each I cell
        
        sigThreshE = sigVth;        % Mean threshold of E cells
        sigThreshI = sigVth;        % Mean threshold of I cells
        
        % Next lines incorporate random variability cell by cell in
        % threshold for spiking
        V_ThreshE = V_Thresh-sigThreshE + 2*sigThreshE*rand(NE,1);
        V_ThreshI = V_Thresh-sigThreshI + 2*sigThreshI*rand(NI,1);
        
        % The next section ensures each pool of cells has the same mean
        % values either by subtracting or dividing by the mean to
        % normalize. This is to ensure no pool is much more excitable than
        % others.
        for i = 1:Npools;
            V_ThreshE( (i-1)*NEpool+1:i*NEpool ) =  ...
                V_ThreshE( (i-1)*NEpool+1:i*NEpool ) + ...
                V_Thresh - mean(V_ThreshE( (i-1)*NEpool+1:i*NEpool ) );
            CE( (i-1)*NEpool+1:i*NEpool ) =  ...
                CE( (i-1)*NEpool+1:i*NEpool ) * ...
                C * mean(1./CE( (i-1)*NEpool+1:i*NEpool ) );
            G_LE( (i-1)*NEpool+1:i*NEpool ) =  ...
                G_LE( (i-1)*NEpool+1:i*NEpool ) * ...
                GL0 / mean(G_LE( (i-1)*NEpool+1:i*NEpool ) );
            if ( bEmax > 0 )
                bE( (i-1)*NEpool+1:i*NEpool ) =  ...
                    bE( (i-1)*NEpool+1:i*NEpool ) * ...
                    (bEmax/2) / mean(bE( (i-1)*NEpool+1:i*NEpool ) );
            end
            V_ThreshI( (i-1)*NIpool+1:i*NIpool ) =  ...
                V_ThreshI( (i-1)*NIpool+1:i*NIpool ) + ...
                V_Thresh - mean(V_ThreshI( (i-1)*NIpool+1:i*NIpool ) );
            CI( (i-1)*NIpool+1:i*NIpool ) =  ...
                CI( (i-1)*NIpool+1:i*NIpool ) * ...
                C * mean(1./CI( (i-1)*NIpool+1:i*NIpool ) );
            G_LI( (i-1)*NIpool+1:i*NIpool ) =  ...
                G_LI( (i-1)*NIpool+1:i*NIpool ) * ...
                GL0 / mean(G_LI( (i-1)*NIpool+1:i*NIpool ) );
            
            if ( bImax > 0 )
                bI( (i-1)*NIpool+1:i*NIpool ) =  ...
                    bI( (i-1)*NIpool+1:i*NIpool ) * ...
                    (bImax/2) / mean(bI( (i-1)*NIpool+1:i*NIpool ) );
            end
        end
        
        %% Synaptic parameters
        f_facE = 0;             % Facilitation factor for E cells
        f_facI = 0;             % Facilitation factor for I cells
        tau_f = 0.250;          % Facilitation time constant
        fmax = 1;               % Maximum level of synaptic facilitation
        
        alpha = 0.5;            % Fraction of receptors bound per spike
        
        tau_sE = 0.01;          % Excitatory synaptic time constant
        tau_sI = 0.01;          % Inhibitory synaptic time constant
        
        E_E = 0;                % Excitatory synaptic reversal potential
        E_I = -70e-3;           % Inhibitory synaptic reversal potential
        
        %% Stimulation protocol        
        Istim = 1;              % set to 1 if there are any stimuli
        
        % if stim_reset is set to 1 it resets activity before a stimulus 
        % to ensure the same initial state before the stimulus
        stim_reset = 0;    
        
        % assume stimulus input is only from E afferents but can target I cells
        gstim_E = 0.25e-9;      % excitatory conductance of stimulus input
        rstim_EE = 600;         % rate of stim input spikes to E cells
        rstim_EI = 1800;        % rate of stim input spikes to I cells
        
        load('same_poisson_stim.mat','stim_EE','stim_EI');
        % max_possible_duration = 150;
        % stim_noise_EE = poissrnd(rstim_EE * dt, [1, max_possible_duration]);
        % stim_noise_EI = poissrnd(rstim_EI * dt, [1, max_possible_duration]);

        %% This section determines which cell-groups receive stimulus on each trial
        
        % *** Ngroups_stim is a key parameter that determines the fraction
        % of groups that receive excitatory input per stimulation type ***
        Ngroups_stim = 5;   % select random subset of groups for E-stim
        selected_stim = 1;
        all_rand_stim = 0;  % make each stim a new random subset (or repeat)
        Nstims = 1;         % Number of stimuli per trial
        stim_dur = 0.150;   % Duration of stimulus
        stim_sep = 1;       % Separation of stimuli when there are more than 1
        
        % stim_groups is a matrix containing the group identities to be 
        % stimulated in each stimulus 
        stim_groups = zeros(Nstims,Ngroups_stim);
        
        % select_groups can be set to 1 to ensure different, non-random 
        % sets of groups are stimulated for first couple of sets of trials
        select_groups = 1;  
        
        if ( selected_stim == 1)
            load('stim_groups_30.mat');
            selected_stim_groups = stim_groups;
        end

        % Number of sets of stimulated groups is equal to N_vary_trials
        for stim_set = 1:N_vary_trials
            
            % We can randonly choose sets of stimulated groups, but may get
            % repeats. *** This section could be improved with a latin square
            % approach. ***
            if ( all_rand_stim ) 
                for i = 1:Nstims
                    stim_groups_varied(i,:,stim_set) = randperm(Npools,Ngroups_stim);
                end
            else
                % This section aims to ensure different sets of trials have
                % different groups stimulated but latin square may be
                % better
                if ( ( select_groups ) && ( stim_set == 1 ) )
                    stim_groups_varied(1,:,stim_set) = 1:Ngroups_stim;
                else
                    if ( ( select_groups ) && ( stim_set == 2 ) )
                        stim_groups_varied(1,:,stim_set) = Npools-Ngroups_stim+1:Npools;
                    else
                        stim_groups_varied(1,:,stim_set) = randperm(Npools,Ngroups_stim);
                    end
                end
                
                for i = 2:Nstims
                    stim_groups_varied(i,:,stim_set) = stim_groups_varied(1,:,stim_set);
                end
            end

            if ( selected_stim )
                stim_groups_varied(1,:,stim_set) = selected_stim_groups(stim_set,:);
            end
        end
        
        
        %% Set up network conductances. THese as they stand ensure the network is inhibition-stabilized
        
        % Baseline values for connections within a pool.
        % These are scaled by connection probability and an overall factor
        gEE0 = 2.5e-9*(80/NEpool)*(0.1/pconnEE)*Wscale;
        gEI0 = 12e-9*(80/NEpool)*(0.1/pconnEI)*Wscale0;
        gIE0 = 2.2e-9*(40/NIpool)*(0.2/pconnIE)*Wscale0;
        gII0 = 4.0e-9*(40/NIpool)*(0.2/pconnII)*Wscale0;
        
        % In this version the pools interact only through I-to-E
        % connections to ensure only a subset of pools stay active at one
        % time *** could compare I to E with E to I for x-connections ***
        gEEx = 0;
        gEIx = 0;
        gIEx = 0.12e-9*(40/NIpool)*(0.12/pconnIE)*Wscale;
        gIIx = 0;
        
        % *** g_vary_fact introduces heterogeneity in conductances for 
        % connections between groups. 
        % Could be a parameter and could be altered ***
        g_vary_fact = 0.5;

        % First set up general connections as if all are cross-connections
        gEE = gEEx*ones(NE,NE).*(1 - g_vary_fact + 2*g_vary_fact*rand(NE,NE) );
        gEI = gEIx*ones(NI,NE).*(1 - g_vary_fact + 2*g_vary_fact*rand(NI,NE) );
        gIE = gIEx*ones(NE,NI).*(1 - g_vary_fact + 2*g_vary_fact*rand(NE,NI) );
        gII = gIIx*ones(NI,NI).*(1 - g_vary_fact + 2*g_vary_fact*rand(NI,NI) );
        
        % Now overwrite connections within each pool by the uniform values
        for i = 1:Npools;
            gEE( (i-1)*NEpool+1:i*NEpool, (i-1)*NEpool+1:i*NEpool ) = gEE0;
            gEI( (i-1)*NIpool+1:i*NIpool, (i-1)*NEpool+1:i*NEpool ) = gEI0;
            gIE( (i-1)*NEpool+1:i*NEpool, (i-1)*NIpool+1:i*NIpool ) = gIE0;
            gII( (i-1)*NIpool+1:i*NIpool, (i-1)*NIpool+1:i*NIpool ) = gII0;
        end
        
        % The following sections impose the sparse connectivity within
        % pools. If latin_square_flag is 1 it ensures each cell receives
        % the same number of incoming and outgoing connections
        if latin_square_flag
            for i = 1:Npools;
                for j = 1:Npools;
                    connEE( (i-1)*NEpool+1:i*NEpool, (j-1)*NEpool+1:j*NEpool ) = ...
                        ( latin_square(NEpool) <= NEE );
                    
                    connEI( (i-1)*NIpool+1:i*NIpool, (j-1)*NEpool+1:j*NEpool ) = ...
                        ( latin_square(NIpool,NEpool) <= NEI );
                    
                    connIE( (i-1)*NEpool+1:i*NEpool, (j-1)*NIpool+1:j*NIpool ) = ...
                        ( latin_square(NEpool,NIpool) <= NIE );
                    
                    connII( (i-1)*NIpool+1:i*NIpool, (j-1)*NIpool+1:j*NIpool ) = ...
                        ( latin_square(NIpool) <= NII );
                end
            end
        else;   % if latin_squre_flag is zero then randomly independent connections
            for i = 1:Npools;
                for j = 1:Npools;
                    
                    connEE( (i-1)*NEpool+1:i*NEpool, (j-1)*NEpool+1:j*NEpool ) = ...
                        ( rand(NEpool) < pconnEE ) ;
                    
                    connEI( (i-1)*NIpool+1:i*NIpool, (j-1)*NEpool+1:j*NEpool ) = ...
                        ( rand(NIpool,NEpool) < pconnEI );
                    
                    connIE( (i-1)*NEpool+1:i*NEpool, (j-1)*NIpool+1:j*NIpool ) = ...
                        ( rand(NEpool,NIpool) < pconnIE );
                    
                    connII( (i-1)*NIpool+1:i*NIpool, (j-1)*NIpool+1:j*NIpool ) = ...
                        ( rand(NIpool) < pconnII );
                end
            end
        end
        
        % Finally the connectivity matrix is set up by combining
        % conductance values with connection probabilities
        gEE = gEE.*connEE;
        gEI = gEI.*connEI;
        gIE = gIE.*connIE;
        gII = gII.*connII;
        
        % Next step removes self-connections
        if ( remove_self == 1 )
            gEE = gEE - diag(diag(gEE));
            gII = gII - diag(diag(gII));
        end
        
        % Next section ensures incoming sums of connection strengths are
        % the same for every pool
        if ( normalize_pools )
            for i = 1:Npools;
                gEEmean(i) = mean(mean(gEE( (i-1)*NEpool+1:i*NEpool, (i-1)*NEpool+1:i*NEpool )));
                gEImean(i) = mean(mean(gEI( (i-1)*NIpool+1:i*NIpool, (i-1)*NEpool+1:i*NEpool )));
                gIEmean(i) = mean(mean(gIE( (i-1)*NEpool+1:i*NEpool, (i-1)*NIpool+1:i*NIpool )));
                gIImean(i) = mean(mean(gII( (i-1)*NIpool+1:i*NIpool, (i-1)*NIpool+1:i*NIpool )));
            end
            % Normalization is the average across pools
            gEEnorm = mean(gEEmean);
            gEInorm = mean(gEImean);
            gIEnorm = mean(gIEmean);
            gIInorm = mean(gIImean);
            
            % Now reweight all connections to each pool by the
            % pool-averaged mean so the mean for each pool becomes the
            % pool-averaged mean.
            for i = 1:Npools
                gEE( (i-1)*NEpool+1:i*NEpool, (i-1)*NEpool+1:i*NEpool ) = ...
                    gEE( (i-1)*NEpool+1:i*NEpool, (i-1)*NEpool+1:i*NEpool )*(gEEnorm/gEEmean(i));
                gEI( (i-1)*NIpool+1:i*NIpool, (i-1)*NEpool+1:i*NEpool ) = ...
                    gEI( (i-1)*NIpool+1:i*NIpool, (i-1)*NEpool+1:i*NEpool )*(gEInorm/gEImean(i));
                gIE( (i-1)*NEpool+1:i*NEpool, (i-1)*NIpool+1:i*NIpool ) = ...
                    gIE( (i-1)*NEpool+1:i*NEpool, (i-1)*NIpool+1:i*NIpool )*(gIEnorm/gIEmean(i));
                gII( (i-1)*NIpool+1:i*NIpool, (i-1)*NIpool+1:i*NIpool ) = ...
                    gII( (i-1)*NIpool+1:i*NIpool, (i-1)*NIpool+1:i*NIpool )*(gIInorm/gIImean(i));
            end
            
        end
        
        
        %% Loop through trials
        
        trial = 0;
        
        %% Define all variables
        sE = zeros(NE,Nt);                  % Excitatory synaptic gating
        sI = zeros(NI,Nt);                  % Inhibitory synaptic gating
        FE = ones(NE,Nt);                   % Facilitation for E cells
        FI = ones(NI,Nt);                   % Facilitation for I cells
        IappE = Iapp0E*ones(NE,Nt);         % Applied current to E cells
        IappI = Iapp0I*ones(NI,Nt);         % Applied current to I cells
        binsize = 0.050;                    % Time bin for saving rate outputs
        bindt = 0.002;
        Nbins = ceil(tmax/bindt);
        bintvec = bindt*[1:Nbins];
        Nibindt = round(bindt/dt);
        Nibinsize = round(binsize/dt);
        rEsave = zeros(Npools,Nbins,Ntrials);
        
        %% Loop through trials
        for stim_set = 1:N_vary_trials
            
            stim_groups = squeeze(stim_groups_varied(:,:,stim_set));
            disp('stim_groups: ')
            disp(stim_groups)
            
            
            for repeat_trial = 1:N_repeat_trials
                tic

                trial = trial + 1;
                
                V_ThreshE_all(:,trial) = V_ThreshE;
                V_ThreshI_all(:,trial) = V_ThreshI;

                disp(['trial ',num2str(trial),' stim set: ',num2str(stim_set),' repeat: ',num2str(repeat_trial) ])
                
                if ( background_noise == 1 )
                    noise_EE = gnoise_E*poissrnd(rnoise_EE*dt,[NE,Nt]);
                    noise_IE = gnoise_I*poissrnd(rnoise_IE*dt,[NE,Nt]);
                    noise_EI = gnoise_E*poissrnd(rnoise_EI*dt,[NI,Nt]);
                    noise_II = gnoise_I*poissrnd(rnoise_II*dt,[NI,Nt]);
                else
                    noise_EE = zeros(NE,Nt);
                    noise_IE = zeros(NE,Nt);
                    noise_EI = zeros(NI,Nt);
                    noise_II = zeros(NI,Nt);
                end
                
                if ( Istim )
                    
                    if ( stim_reset )
                        ton = 0;
                        toff = ton+0.5;
                        i_ton = round(ton/dt);
                        i_toff = round(toff/dt);
                        i_dur = i_toff-i_ton;
                        cell1I = 1;
                        cell2I = NI;
                        stim_EI = poissrnd(rstim_EE*dt,[NI,i_dur]);
                        for i = 1:i_dur
                            noise_EI(cell1I:cell2I,i_ton+i) = noise_EI(cell1I:cell2I,i_ton+i) + ...
                                gstim_E*stim_EI(:,i);
                        end
                        ton = 0.25;
                        toff = ton+0.5;
                        i_ton = round(ton/dt);
                        i_toff = round(toff/dt);
                        i_dur = i_toff-i_ton;
                        cell1E = 1;
                        cell2E = 4*NEpool;
                        stim_EE = poissrnd(rstim_EE*dt,[4*NEpool,i_dur]);
                        for i = 1:i_dur
                            noise_EE(cell1E:cell2E,i_ton+i) = noise_EE(cell1E:cell2E,i_ton+i) + ...
                                gstim_E*stim_EE(:,i);
                        end
                        
                    end
                    
                    
                    for stim = 1:Nstims
                        ton = stim_sep*(stim);
                        toff = ton+stim_dur;
                        i_ton = round(ton/dt);
                        i_toff = round(toff/dt);
                        i_dur = i_toff-i_ton;
                        for j = 1:Ngroups_stim
                            group_on = stim_groups(stim,j);
                            cell1E = NEpool*(group_on-1)+1;
                            cell2E = NEpool*group_on;
                            cell1I = NIpool*(group_on-1)+1;
                            cell2I = NIpool*group_on;
                            %stim_EE = poissrnd(rstim_EE*dt,[NEpool,i_dur]);
                            for i = 1:i_dur
                                noise_EE(cell1E:cell2E,i_ton+i) = noise_EE(cell1E:cell2E,i_ton+i) + ...
                                    gstim_E*stim_EE(:,i);
                            end
                        end
                        if ( rstim_EI > 0 )
                            %stim_EI = poissrnd(rstim_EI*dt,[NI,i_dur]);
                            for i = 1:i_dur
                                noise_EI(:,i_ton+i) = noise_EI(:,i_ton+i) + ...
                                    gstim_E*stim_EI(:,i);
                            end
                        end
                        
                    end
                    
                end
                
                
                %% Single trial data
                
                gnoise_EE = zeros(NE,Nt);
                gnoise_IE = zeros(NE,Nt);
                gnoise_EI = zeros(NI,Nt);
                gnoise_II = zeros(NI,Nt);
                
                if ( background_noise == 1 )
                    for i = 2:Nt
                        gnoise_EE(:,i-1) = gnoise_EE(:,i-1) + noise_EE(:,i-1);
                        gnoise_IE(:,i-1) = gnoise_IE(:,i-1) + noise_IE(:,i-1);
                        gnoise_EI(:,i-1) = gnoise_EI(:,i-1) + noise_EI(:,i-1);
                        gnoise_II(:,i-1) = gnoise_II(:,i-1) + noise_II(:,i-1);
                        
                        gnoise_EE(:,i) = gnoise_EE(:,i-1)*exp(-dt/tau_noiseE);
                        gnoise_IE(:,i) = gnoise_IE(:,i-1)*exp(-dt/tau_noiseI);
                        gnoise_EI(:,i) = gnoise_EI(:,i-1)*exp(-dt/tau_noiseE);
                        gnoise_II(:,i) = gnoise_II(:,i-1)*exp(-dt/tau_noiseI);
                    end
                else
                    % Assume stimulus only comes via E-input
                    i_ton = min(find(sum(noise_EE) + sum(noise_IE) ) );
                    i_toff = max(find(sum(noise_EE) + sum(noise_IE) ) );
                    i_toff = min(Nt,i_toff + round(10*tau_noiseE/dt));
                    
                    for i = i_ton:i_toff
                        gnoise_EE(:,i-1) = gnoise_EE(:,i-1) + noise_EE(:,i-1);
                        gnoise_EI(:,i-1) = gnoise_EI(:,i-1) + noise_EI(:,i-1);
                        
                        gnoise_EE(:,i) = gnoise_EE(:,i-1)*exp(-dt/tau_noiseE);
                        gnoise_EI(:,i) = gnoise_EI(:,i-1)*exp(-dt/tau_noiseE);
                    end
                end
                
                
                vE = E_L*ones(NE,Nt);
                vI = E_L*ones(NI,Nt);
                vE(:,1) = V_Reset + 2*(V_Thresh-V_Reset)*rand(NE,1);
                vI(:,1) = V_Reset + 2*(V_Thresh-V_Reset)*rand(NI,1);
                
                spikesE = zeros(NE,Nt);
                spikesI = zeros(NI,Nt);
                rE = zeros(Npools,Nbins);
                rI = zeros(Npools,Nbins);
                
                ibin = 0;
                %% Simulation loop 
                % This method uses Runge-Kutta 4 which is a bit more
                % complicated than Euler but more efficient.
                for i = 2:Nt     % simulation of tmax
                    
                    % Record which cells spike in the prior time step
                    sp_Ecells = find( (vE(:,i-1) > Vmax) + isnan(vE(:,i-1)) );
                    sp_Icells = find( (vI(:,i-1) > Vmax) + isnan(vI(:,i-1)) );
                    
                    vE(sp_Ecells,i-1) = V_Reset;        % reset the voltage
                    vI(sp_Icells,i-1) = V_Reset;        % reset the voltage
                    spikesE(sp_Ecells,i-1) = 1;         % update spike vectors
                    spikesI(sp_Icells,i-1) = 1;         % update spike vectors
                    
                    % Update synaptic gating variables for those cells that
                    % spiked (note this corresponds to a value for each
                    % presynaptic cell)
                    sE(sp_Ecells,i-1) = sE(sp_Ecells,i-1) + alpha*(1-sE(sp_Ecells,i-1)).*FE(sp_Ecells,i-1);        % increase the adaptation variable by b
                    sI(sp_Icells,i-1) = sI(sp_Icells,i-1) + alpha*(1-sI(sp_Icells,i-1)).*FI(sp_Icells,i-1);        % increase the adaptation variable by b
                    
                    % Update facilitation variables for those cells that
                    % spiked (all presynaptic)
                    FE(sp_Ecells,i-1) = FE(sp_Ecells,i-1) + (fmax-FE(sp_Ecells,i-1))*f_facE;
                    FI(sp_Icells,i-1) = FI(sp_Icells,i-1) + (fmax-FI(sp_Icells,i-1))*f_facI;
                     
                    %% Runge-Kutta Integration of vE and vI
                    % The following sections begin the Runge-Kutta 4 steps
                    % for integration. Each step is like the Euler but it
                    % is done 4 times, incrementing variables with
                    % estimates each time and then combining to get a total
                    % change in the voltage of each cell. Separately done
                    % for E and I cells. 
                    k1_vE = dt*( G_LE.*(E_L-vE(:,i-1) + deltaT*exp((vE(:,i-1)-V_ThreshE(:))/deltaT) ) ...
                         + (gnoise_EE(:,i-1)+gEE*sE(:,i-1)).*(E_E-vE(:,i-1)) + (gnoise_IE(:,i-1) + gIE*sI(:,i-1)).*(E_I-vE(:,i-1)) + IappE(:,i))./CE;
                    k1_vI = dt*( G_LI.*(E_L-vI(:,i-1) + deltaT*exp((vI(:,i-1)-V_ThreshI(:))/deltaT) ) ...
                        + (gnoise_EI(:,i-1) + gEI*sE(:,i-1)).*(E_E-vI(:,i-1)) + (gnoise_II(:,i-1) + gII*sI(:,i-1)).*(E_I-vI(:,i-1)) + IappI(:,i))./CI;

                    tmp_vE = vE(:,i-1) + k1_vE/2;
                    tmp_vI = vI(:,i-1) + k1_vI/2;
                    k2_vE = dt*( G_LE.*(E_L-tmp_vE + deltaT*exp((tmp_vE-V_ThreshE(:))/deltaT) ) ...
                       + (gnoise_EE(:,i-1)+gEE*sE(:,i-1)).*(E_E-tmp_vE) + (gnoise_IE(:,i-1) + gIE*sI(:,i-1)).*(E_I-tmp_vE) + IappE(:,i))./CE;
                    k2_vI = dt*( G_LI.*(E_L-tmp_vI + deltaT*exp((tmp_vI-V_ThreshI(:))/deltaT) ) ...
                        + (gnoise_EI(:,i-1) + gEI*sE(:,i-1)).*(E_E-tmp_vI) + (gnoise_II(:,i-1) + gII*sI(:,i-1)).*(E_I-tmp_vI) + IappI(:,i))./CI;
 
                    tmp_vE = vE(:,i-1) + k2_vE/2;
                    tmp_vI = vI(:,i-1) + k2_vI/2;
                    k3_vE = dt*( G_LE.*(E_L-tmp_vE + deltaT*exp((tmp_vE-V_ThreshE(:))/deltaT) ) ...
                        + (gnoise_EE(:,i-1)+gEE*sE(:,i-1)).*(E_E-tmp_vE) + (gnoise_IE(:,i-1) + gIE*sI(:,i-1)).*(E_I-tmp_vE) + IappE(:,i))./CE;
                    k3_vI = dt*( G_LI.*(E_L-tmp_vI + deltaT*exp((tmp_vI-V_ThreshI(:))/deltaT) ) ...
                        + (gnoise_EI(:,i-1) + gEI*sE(:,i-1)).*(E_E-tmp_vI) + (gnoise_II(:,i-1) + gII*sI(:,i-1)).*(E_I-tmp_vI) + IappI(:,i))./CI;

                    tmp_vE = vE(:,i-1) + k3_vE;
                    tmp_vI = vI(:,i-1) + k3_vI;
                    k4_vE = dt*( G_LE.*(E_L-tmp_vE + deltaT*exp((tmp_vE-V_ThreshE(:))/deltaT) ) ...
                        + (gnoise_EE(:,i-1)+gEE*sE(:,i-1)).*(E_E-tmp_vE) + (gnoise_IE(:,i-1) + gIE*sI(:,i-1)).*(E_I-tmp_vE) + IappE(:,i))./CE;
                    k4_vI = dt*( G_LI.*(E_L-tmp_vI + deltaT*exp((tmp_vI-V_ThreshI(:))/deltaT) ) ...
                        + (gnoise_EI(:,i-1) + gEI*sE(:,i-1)).*(E_E-tmp_vI) + (gnoise_II(:,i-1) + gII*sI(:,i-1)).*(E_I-tmp_vI) + IappI(:,i))./CI;

                    % Finally update vE and vI based on the estimates of
                    % dV/dt from the Runge-Kutta steps
                    vE(:,i) = vE(:,i-1) + (k1_vE + 2*k2_vE + 2*k3_vE + k4_vE)/6;
                    vI(:,i) = vI(:,i-1) + (k1_vI + 2*k2_vI + 2*k3_vI + k4_vI)/6;
                    
                    %% Now update other variables
                    
                    % Exponential decay of synaptic gating variables
                    sE(:,i) = sE(:,i-1)*exp(-dt/tau_sE);
                    sI(:,i) = sI(:,i-1)*exp(-dt/tau_sI);
                    
                    % Exponetnial decay of facilitation variables
                    FE(:,i) = 1 + (FE(:,i-1)-1)*exp(-dt/tau_f);
                    FI(:,i) = 1 + (FI(:,i-1)-1)*exp(-dt/tau_f);
                    
                    % The goal here is to record firing rates by counting
                    % spikes within a bin of width Nibinsize*dt but
                    % producing a new bin every Nibin*dt seconds.
                    % Default is to use 50ms for counting spikes in a
                    % window (so accuracy is only to 20Hz) and to shift
                    % bins every 2ms.
                    % *** I think this section could be done after the time
                    % integration and optimized better but may need to be 
                    % done here to view rates as a function of time as the 
                    % time integration progresses. ***
                    if ( mod(i,Nibindt) == 0 )
                        ibin = ibin + 1;
                        icount_min = max(1,i+1-Nibinsize);
                        for j = 1:Npools
                            rE(j,ibin) = sum(sum(spikesE(NEpool*(j-1)+1:NEpool*j,icount_min:i))) ...
                                /(NEpool*binsize);
                            rI(j,ibin) = sum(sum(spikesI(NIpool*(j-1)+1:NIpool*j,icount_min:i))) ...
                                /(NIpool*binsize);
                        end
                    end
                    
                    % Plot some figures for a subset of trials to check
                    % spiking is reasonable
                    if ( stim_set <= 4 )
                        if ( mod(i,round(0.5/dt)) == 0 )
                            set(0,'CurrentFigure',h(trial))
                            imagesc(vE>V_Thresh)
                            drawnow
                            
                            set(0,'CurrentFigure',h(Ntrials+trial))
                            plot(bintvec,rE)
                            drawnow
                            
                        end
                    end
                    
                end

                for i = 2:Nt
                    if ( mod(i,Nibindt) == 0 )
                        ibin = ibin + 1;
                        icount_min = max(1,i+1-Nibinsize);
                        for j = 1:NE
                            rE_indv(j,ibin) = sum(spikesE(j,icount_min:i)) / (binsize);
                        end
                    end
                end
                rEf_indv(:,trial) = mean(rE_indv(:,end-round(0.2/bindt):end),2);
                
                % Record final rates of each trial based on the last 0.2s
                % of firing. Note the 0.2sec is somewhat arbitrary but
                % needs to be well after the stimulus to check for
                % stability.
                rEf(:,trial) = mean(rE(:,end-round(0.2/bindt):end),2);
                rIf(:,trial) = mean(rI(:,end-round(0.2/bindt):end),2);
                
                % rEsave has summary data for rE of all trials
                rEsave(:,:,trial) = rE;
                
                set(0,'CurrentFigure',h(2*Ntrials+1))
                imagesc(vE>V_Thresh)
                drawnow
                set(0,'CurrentFigure',h(2*Ntrials+2))
                imagesc(rEf)
                drawnow
                toc
                
            end
        end
        
        %% Next evaluate the performance of the circuit
        % r is the correlation matrix between final states. 
        % The goal is high correlation if the inputs are the same to
        % indicate reliability, but low correlation between any different
        % sets of inputs.
        r = corr(rEf);  
        
        % rmean will contain the mean within-stimulus correlation
        rmean = zeros(1,N_vary_trials);
        
        % badr is the highest correlation from a stimulus to another
        badr = zeros(1,N_vary_trials);
        
        % xr is the mean correlation across other stimuli
        xr = zeros(1,N_vary_trials);
        
        % if there are repeated trials of the same stimulus
        if ( N_repeat_trials > 1 )
            for i = 1:N_vary_trials;            % Loop through all stimuli
                jmin = (i-1)*N_repeat_trials + 1;   % First trial of that stimulus
                jmax = i*N_repeat_trials;           % Final trial of that stimulus
                % Find mean correlation between different trials of the
                % same stimulus (the subtraction is to remove those
                % correlations of 1 for the same trial)
                rmean(i) = (sum(sum(r(jmin:jmax,jmin:jmax))) - N_repeat_trials) / ...
                    (N_repeat_trials*(N_repeat_trials-1));
                
                % badr looks at the maximum correlation between any single
                % trial of a stimulus and any single trial of any other
                % stimulus
                badr(i) = max(max(r(jmin:jmax,[1:jmin-1 jmax+1:Ntrials])));
                % badr(i) = 0;
                
                % xr looks at the mean correlation between every single
                % trial of a stimulus and every single trial of every other
                % stimulus
                xr(i) = mean(mean(r(jmin:jmax,[1:jmin-1 jmax+1:Ntrials])));
            end
        end
        
        worst_r = min(rmean);           % worst reliability to same stim
        mean_r = mean(rmean);           % mean reliability to same stim
        max_badr = max(badr);           % highest corr for any trial between different stim
        mean_badr = mean(badr);         % mean of highest corrs across stims
        
        %% Now plot some of the summary data
        figure()
        plot(rmean,badr,'x')        % ideally rmean is near 1 and badr is low
        axis([0 1 0 1])
        hold on
        plot([0 1],[0 1])
        
        %% Now store key measured results for this set of parameters in an array
        mean_r_array(net_row,net_col) = mean_r;
        worst_r_array(net_row,net_col) = worst_r;
        bad_r_array(net_row,net_col) = mean(badr);
        xr_array(net_row,net_col) = mean(xr);
        mean_rE_array(net_row,net_col) = mean(mean(rEf))*Npools/Ngroups_stim;
        mean_rI_array(net_row,net_col) = mean(mean(rIf))*Npools/Ngroups_stim;
        
        % display summary statistics
        disp([' mean_r: ',num2str(mean_r),' worst_r: ',num2str(worst_r),' bad_r: ', num2str(max_badr)])
        
        % save into a file for this parameter set
        % save(['Data_AELIF_ISNnet_noad_RK6613e_NE',num2str(NEpool),'_NP',num2str(Npools), ...
        %     '_netr',num2str(net_row),'_netc',num2str(net_col),'.mat'], ...
        %     'rE','rI', 'stim_groups_varied', 'rEf', 'r', 'rmean', 'badr', 'xr')
        
        V_ThreshE_all = silence_active_neurons(V_ThreshE_all, stim_groups, rEf_indv, Ntrials);
        filename = ['AELIF_ISNnet_noad_RK6613e_grid_NE',num2str(NEpool),'_NP',num2str(Npools), ...
            '_netr',num2str(net_row),'_netc',num2str(net_col),'.mat'];
        save(filename)
        close(gcf)
        
    end
    
end

% save summary data into a final file
% save(['AELIF_ISNnet_noad_RK6613e_grid_NE',num2str(NEpool),'_NP',num2str(Npools), ...
%     '_vary.mat'], 'xr_array','mean_r_array', 'worst_r_array','bad_r_array',...
%     'mean_rE_array','mean_rI_array')
% V_ThreshE_all = silence_active_neurons(V_ThreshE_all, stim_groups, rEf_indv, Ntrials);
% save(['All_AELIF_ISNnet_noad_RK6613e_grid_NE',num2str(NEpool),'_NP',num2str(Npools), ...
%     '_netr',num2str(net_row),'_netc',num2str(net_col),'.mat'], ...
%     'rEf_indv','V_ThreshE_all','V_ThreshI_all')
% filename = ['AELIF_ISNnet_noad_RK6613e_grid_NE',num2str(NEpool),'_NP',num2str(Npools), ...
%     '_netr',num2str(net_row),'_netc',num2str(net_col),'.mat'];
% save(filename)

