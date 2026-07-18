# Project
File `example_data` contains a 9 × 9 grid of simulated circuit datasets, each corresponding to a unique combination of `sigVth` \(0–4 mV\) and `W_EE` \(0.9–1.3\)

`AELIF_ISNnet_stim_noad_RK6613e_grid6_same_stim_noise_WEE.m` is the simulation script used to generate the circuit behavior datasets.

`analysis.m` and `analysis_all.m` compute circuit performance metrics, including robustness, discriminability, and mean firing rate. `circuits_performance_analysis.m` is a helper function used for the subsequent classifier analysis.

`classifier_RK6613e.m` implements the classifier used to identify regions of the \(`sigVth`, `W_EE`\) parameter space that produce desirable circuit behavior

 `classified_circuit_behavior_sd3.png` is an example output showing the classification results obtained using the SVM classifier.
