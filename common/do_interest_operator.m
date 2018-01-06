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

%% Perform interest operator on testing images
test_file_names = [];
test_out_file_names = [];
old_files = dir(char(TEST_DIR + "/*.mat"));
for i = 1 : length(old_files)
   fn = char(string(old_files(i).folder) + '/' + string(old_files(i).name));
   delete(fn); 
end

for i = 1 : length(Categories.Name)
    cat_dir = char(TEST_DIR + "/" + Categories.Name(i));
    listing = dir(cat_dir);
    file_folder = "";
    file_name = "";
    for j = 3:length(listing)
        file_folder = string(listing(j).folder) + '/';
        file_name = string(listing(j).name);
        test_file_names = [test_file_names; file_folder + file_name];
        file_name = strip(file_name, 'right', 'g');
        file_name = strip(file_name, 'right', 'p');
        file_name = strip(file_name, 'right', 'j');
        test_out_file_names = [test_out_file_names; TEST_DIR + "/" + file_name + "mat"];
    end
end

%% Perform interest operator on training images (randomly chosen)

img_file_names = [];
ip_file_names = [];
img_dir = string(RUN_DIR) + '/' + string(Global.Image_Dir_Name);
old_files = dir(char(IP_DIR + "/*.mat"));
for i = 1 : length(old_files)
   fn = char(string(old_files(i).folder) + '/' + string(old_files(i).name));
   delete(fn); 
end

healthy = zeros(1,length(dir(char(img_dir + "/healthy"))));
emphysema = zeros(1,length(dir(char(img_dir + "/emphysema"))));
fibrosis = zeros(1,length(dir(char(img_dir + "/fibrosis"))));
ground_glass = zeros(1,length(dir(char(img_dir + "/ground_glass"))));
micronodules = zeros(1,length(dir(char(img_dir + "/micronodules"))));
for i = 1 : Categories.Total_Frames
    cat_num = mod(i, length(Categories.Name)) + 1;
    cat_name = char(Categories.Name(cat_num));
    dir_name = dir(char(img_dir + '/' + cat_name));
    dir_length = length(dir_name);
    file_folder = "";
    file_name = "";
    if cat_name == "healthy"
        idx = uint16(rand() * (length(healthy)-3)) + 3;
        while healthy(:,idx) == 1
            idx = uint16(rand() * (length(healthy)-3)) + 3;
        end
        healthy(:,idx) = 1;
        file_folder = string(dir_name(idx).folder) + '/';
        file_name = string(dir_name(idx).name);
    elseif cat_name == "emphysema"
        idx = uint16(rand() * (length(emphysema)-3)) + 3;
        while emphysema(:,idx) == 1
            idx = uint16(rand() * (length(emphysema)-3)) + 3;
        end
        emphysema(:,idx) = 1;
        file_folder = string(dir_name(idx).folder) + '/';
        file_name = string(dir_name(idx).name);
    elseif cat_name == "fibrosis"
        idx = uint16(rand() * (length(fibrosis)-3)) + 3;
        while fibrosis(:,idx) == 1
            idx = uint16(rand() * (length(fibrosis)-3)) + 3;
        end
        fibrosis(:,idx) = 1;
        file_folder = string(dir_name(idx).folder) + '/';
        file_name = string(dir_name(idx).name);
    elseif cat_name == "ground_glass"
        idx = uint16(rand() * (length(ground_glass)-3)) + 3;
        while ground_glass(:,idx) == 1
            idx = uint16(rand() * (length(ground_glass)-3)) + 3;
        end
        ground_glass(:,idx) = 1;
        file_folder = string(dir_name(idx).folder) + '/';
        file_name = string(dir_name(idx).name);
    elseif cat_name == "micronodules"
        idx = uint16(rand() * (length(micronodules)-3)) + 3;
        while micronodules(:,idx) == 1
            idx = uint16(rand() * (length(micronodules)-3)) + 3;
        end
        micronodules(:,idx) = 1;
        file_folder = string(dir_name(idx).folder) + '/';
        file_name = string(dir_name(idx).name);
    end
    img_file_names = [img_file_names; file_folder + file_name];
    file_name = strip(file_name, 'right', 'g');
    file_name = strip(file_name, 'right', 'p');
    file_name = strip(file_name, 'right', 'j');
    ip_file_names = [ip_file_names; IP_DIR + "/" + file_name + "mat"];
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
  Edge_Sampling(test_file_names,test_out_file_names,Interest_Point);
  
elseif strcmp(Interest_Point.Type,'DoG')
  
  %% Laplacian of Gaussian method to obtain key points (implemented as difference of Gaussian)
  % Now returns filter responses from MR8 filters
  DoG(img_file_names,ip_file_names);
  DoG(test_file_names,test_out_file_names);
else
  error('Unknown type of operator');
end

total_time=toc;
fn = [RUN_DIR,'/training.mat'];
save(fn,'img_file_names','ip_file_names','test_file_names','test_out_file_names');

fprintf('\nFinished running interest point operator\n');
fprintf('Total number of images: %d, mean time per image: %f secs\n',Categories.Total_Frames,total_time/Categories.Total_Frames);
