function do_interest_operator(config_file)
  
%% Top-level function that generates interest points for all images in
%% the images/ subidrectory, putting the output in interest_points/ 

%% This routine is a wrapper for each of the different interest operator
%% types you may have. Currently there is only one really simple operator based on
%% sampling from edgels found within the image. 
  
%% The structure Interest_Point should be passed to each interest
%% operator, and will hold all parameter settings for the operator.  
   
%% N.B. This routine does not give a representation to each region - it
%% only finds its location and scale within the image. Use
%% do_represenation to get SIFT descriptors or whatever describing each region.  

%% Before running this, you must have run:
%%    do_random_indices - to generate random_indices.mat file
%%    do_preprocessing - to get the images that the operator will run on  
  
%%% R.Fergus (fergus@csail.mit.edu) 03/10/05.  
  
%% Evaluate global configuration file
eval(config_file);

%% Create directories for interest points
[s,m1,m2]=mkdir(RUN_DIR,Global.Interest_Dir_Name);

%% Get list of file name of input images
% Edit Total_Frames in config file to change number of training images that
% get generated here
%genFileNames({Global.Image_Dir_Name},[1:Categories.Total_Frames],RUN_DIR,Global.Image_File_Name,Global.Image_Extension,Global.Num_Zeros);

img_file_names = [];
ip_file_names = [];
img_dir = string(RUN_DIR) + '/' + string(Global.Image_Dir_Name);
old_files = dir(char(img_dir + '/*.mat'));
for i = 1 : length(old_files)
   fn = char(string(old_files(i).folder) + '/' + string(old_files(i).name));
   delete(fn); 
end
search_str = img_dir + '/*.jpg';
chosen = zeros(1,length(dir(char(search_str))) - 2);
for i = 1 : Categories.Total_Frames
    idx = uint16(rand() * (length(chosen)-1)) + 1;
    while chosen(:,idx) == 1
        idx = uint8(rand() * (length(chosen)-1)) + 1;
    end
    chosen(:,idx) = 1;
    img_file_names = [img_file_names; char(img_dir + '/' + Global.Image_File_Name + prefZeros(idx, 4) + '.jpg')];
    ip_file_names = [ip_file_names; char(string(RUN_DIR) + '/' + Global.Interest_Dir_Name + '/' + Global.Image_File_Name + prefZeros(idx, 4) + '.mat')];
end
 
%% Get list of output file names
%genFileNames({Global.Interest_Dir_Name},[1:Categories.Total_Frames],RUN_DIR,Global.Interest_File_Name,'.mat',Global.Num_Zeros);
 
%% Find type of Interest Operator to be used
%% (should be specified in the config_file)
%% and run across 
tic;

if strcmp(Interest_Point.Type,'Edge_Sampling')

  %%% Edge Sampling: simple, crude interest operator.
  Edge_Sampling(img_file_names,ip_file_names,Interest_Point);
  
elseif strcmp(Interest_Point.Type,'DoG')
  
  %% Laplacian of Gaussian method to obtain key points (implemented as difference of Gaussian)
  % Now returns filter responses from MR8 filters
  DoG(img_file_names,ip_file_names);
else
  error('Unknown type of operator');
end

total_time=toc;
fn = [RUN_DIR,'/training.mat'];
save(fn,'img_file_names','ip_file_names');

fprintf('\nFinished running interest point operator\n');
fprintf('Total number of images: %d, mean time per image: %f secs\n',Categories.Total_Frames,total_time/Categories.Total_Frames);
