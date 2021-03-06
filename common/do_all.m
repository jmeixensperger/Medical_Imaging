function do_all(config_file)

%%% Top-level script for ICCV short course demos  
%%% Overall routine that does everything, call this with 
%%% a configuration file and it will run each subsection of the scheme in
%%% turn. See the comments in each do_ routine for details of what it does

%%% ALL settings for the experiment should be held in the configuration
%%% file. When first running the code, please ensure all paths within the
%%% configuration file are correct.  
  
%% Platform requirements: The currentl implementation only runs under 32-bit Linux
%% as the implementation of SIFT uses a Linux binary from
%% Krystian Mikolajczyk (km@robots.ox.ac.uk). The rest of the code will
%% run fine under Windows, so you will need alternative code to use in place
%% of the SIFT descriptor binary if you intend to use it under
%% Windows. Note that in the d emos shown at ICCV, we copied the
%% interest_point files onto our Windows laptops, having run the SIFT
%% descriptor code on Linux machines. 
  
%% Software requirements: Matlab 
%%                        Image Processing toolbox
                          
%%% R.Fergus (fergus@csail.mit.edu) 03/10/05.  
  
%%% run configuration script robustly to get EXPERIMENT_TYPE
%%% this tells if we are doing plsa or a bag or words or a parts and
%%% structure experiment etc.
try
    eval(config_file);
catch
end

tp_list = zeros(length(HEALTHY_PATIENTS),1);
fp_list = zeros(length(HEALTHY_PATIENTS),1);
fscore_list = zeros(length(HEALTHY_PATIENTS),1);
roc_area_list = zeros(length(HEALTHY_PATIENTS),1);
for i=1:length(HEALTHY_PATIENTS)
    %%% generate random indices for trainig and test frames
    %do_random_indices(config_file);

    %%% copy & resize images into experiment subdir
    do_preprocessing(config_file,i);

    %%% run interest operator over images and obtain representation of interest points
    do_interest_operator(config_file);

    %%% form appearance codebook
    do_form_codebook(config_file);

    %%% VQ appearance of regions
    do_vq(config_file);

    %%% run svm to learn model
    do_svm(config_file);

    %%% test model
    [tp, fp, fscore, roc_area] = do_svm_evaluation(config_file,i);
    tp_list(i) = tp;
    fp_list(i) = fp;
    fscore_list(i) = fscore;
    roc_area_list(i) = roc_area;
end

num_p = length(HEALTHY_PATIENTS);
tp_avg = sum(tp_list) / num_p;
fp_avg = sum(fp_list) / num_p;
fscore_avg = sum(fscore_list) / num_p;
roc_avg = sum(roc_area_list) / num_p;
fprintf('Tested on: %d patient(s)\n', num_p);
fprintf('Averages:\nTruePos: %f \tFalsePos: %f \tFscore: %f \tROC Test Area: %f\n', ...
    tp_avg, fp_avg, fscore_avg, roc_avg);
output_name = char(string(IMAGE_DIR) + "/output.mat");
% output all relevant data
save(output_name, 'tp_list', 'fp_list', 'fscore_list', 'roc_area_list', ...
    'num_p', 'tp_avg', 'fp_avg', 'fscore_avg', 'roc_avg');
    
