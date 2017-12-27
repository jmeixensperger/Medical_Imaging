function do_svm(config_file)

%% Function that runs the Naive Bayes classifier on histograms of
%% vector-quantized image regions. Based on the paper:
%% 
%% Visual categorization with bags of keypoints
%% Chris Dance, Jutta Willamowski, Lixin Fan, Cedric Bray, Gabriela Csurka
%% ECCV International Workshop on Statistical Learning in Computer Vision, Prague, 2004. 
%% http://www.xrce.xerox.com/Publications/Attachments/2004-010/2004_010.pdf
  
%% Note that this only trains a model. It does not evaluate any test
%% images. Use do_naive_bayes_evaluation for that.  
  
%% Before running this, you must have run:
%%    do_random_indices - to generate random_indices.mat file
%%    do_preprocessing - to get the images that the operator will run on  
%%    do_interest_op  - to get extract interest points (x,y,scale) from each image
%%    do_representation - to get appearance descriptors of the regions  
%%    do_vq - vector quantize appearance of the regions
  
%% R.Fergus (fergus@csail.mit.edu) 03/10/05.  
 
    
%% Evaluate global configu
%% Evaluate global configuration file
eval(config_file);

%% ensure models subdir is present
[s,m1,m2]=mkdir(RUN_DIR,Global.Model_Dir_Name);

%% get all file names of training image interest point files
temp_file_names = dir(IP_DIR);
temp_file_names = temp_file_names(3:end);
ip_file_names = [];
for a=1:length(temp_file_names)
    %pos_ip_file_names =  [pos_ip_file_names , ];
    file_name = char(string(temp_file_names(a).folder) + "/" + string(temp_file_names(a).name));
    ip_file_names = [ip_file_names; file_name];
end

%% get -ve interest point file names
%neg_ip_file_names = [];
%neg_sets = find(Categories.Labels==0);
%for a=1:length(neg_sets)
%    neg_ip_file_names =  [neg_ip_file_names , genFileNames({Global.Interest_Dir_Name},Categories.Train_Frames{neg_sets(a)},RUN_DIR,Global.Interest_File_Name,'.mat',Global.Num_Zeros)];
%end

%% Create matrix to hold word histograms from +ve images
X = zeros(VQ.Codebook_Size,length(ip_file_names));

%% load up all interest_point files which should have the histogram
%% variable already computed (performed by do_vq routine).
classes = unique(Categories.Name);
Y = cell(length(ip_file_names),1);
for a=1:length(ip_file_names)
    %% load file
    load(char(ip_file_names(a,:)));
    %% store histogram
    X(:,a) = histg';
    %% store labels
    temp_Y = "none";
    for n=1:length(classes)
        if ground_truth == classes(n)
            temp_Y = ground_truth;
        end
    end
    Y(a) = cellstr(temp_Y);
end 

%% OLD CODE
    % Create matrix to hold word histograms from -ve images
    %X_bg = zeros(VQ.Codebook_Size,length(neg_ip_file_names));
    % load up all interest_point files which should have the histogram
    % variable already computed (performed by do_vq routine).
    %for a=1:length(neg_ip_file_names)
    %    %% load file
    %    load(neg_ip_file_names{a});
    %    %% store histogram
    %    X_bg(:,a) = histg';    
    %end
    %%% Now construct probability of word given class using SVM classifier 
    % positive 
    %Pw_pos = (1 + sum(X_fg,2)) / (VQ.Codebook_Size + sum(sum(X_fg)));
    % positive 
    %Pw_neg = (1 + sum(X_bg,2)) / (VQ.Codebook_Size + sum(sum(X_bg)));
    %%% Compute posterior probability of each class given likelihood models
    %%% assume equal priors on each class
    class_priors = [0.5 0.5];
    %%% positive model on positive training images
    %for a=1:length(pos_ip_file_names)
    %    Pc_d_pos_train(1,a) = log(class_priors(1)) + sum(X_fg(:,a) .* log(Pw_pos)); 
    %end
    %%% negative model on positive training images
    %for a=1:length(pos_ip_file_names)
    %    Pc_d_pos_train(2,a) = log(class_priors(2)) + sum(X_fg(:,a) .* log(Pw_neg)); 
    %end
    %%% positive model on negative training images
    %for a=1:length(neg_ip_file_names)
    %    Pc_d_neg_train(1,a) = log(class_priors(1)) + sum(X_bg(:,a) .* log(Pw_pos)); 
    %enD
    %%% negative model on negitive training images
    %for a=1:length(neg_ip_file_names)
    %    Pc_d_neg_train(2,a) = log(class_priors(2)) + sum(X_bg(:,a) .* log(Pw_neg)); 
    %end
    % Concatenate data
    %X = cat(2, X_fg, X_bg)';
    %Y = zeros(100,1);
    %for i=1:50
    %    Y(i) = 1;
    %end

X = X';
SVMModels = cell(5,1);
classes = unique(Categories.Name);
for i =1:numel(classes)
    indx = strcmp(Y,classes(i));
    SVMModels{i} = fitcsvm(X, indx, 'ClassNames', [false, true], 'Standardize', true, 'KernelFunction', 'rbf', 'OptimizeHyperparameters', 'auto');
end

d = 0.02;
[x1grid,x2grid] = meshgrid(min(X(:,1)):d:max(X(:,1)), min(X(:,2)):d:max(X(:,2)));
xgrid = [x1grid(:), x2grid(:)];
N = size(xgrid, 1);
Scores = zeros(N,numel(classes));
for i=1:numel(classes)
    % CURRENTLY FAILING ON THE FOLLOWING LINE:
    [~,score] = predict(SVMModels{i},xgrid);
    Scores(:,i) = score(:,2);
end
[~,maxScore] = max(Scores,[],2);

%%% Compute ROC and RPC on training data
labels = [ones(1,length(pos_ip_file_names)) , zeros(1,length(neg_ip_file_names))];
values = values(:,1)';

%%% compute roc
[roc_curve_train,roc_op_train,roc_area_train,roc_threshold_train] = roc([values;labels]');
fprintf('Training: Area under ROC curve = %f; Optimal threshold = %f\n', roc_area_train, roc_threshold_train);
%%% compute rpc
[rpc_curve_train,rpc_ap_train,rpc_area_train,rpc_threshold_train] = recall_precision_curve([values;labels]',length(pos_ip_file_names));
fprintf('Training: Area under RPC curve = %f\n', rpc_area_train);
%%% Now save model out to file
[fname,model_ind] = get_new_model_name([RUN_DIR,'\',Global.Model_Dir_Name],Global.Num_Zeros);

%%% save variables to file
save(fname,'SVMModel','Pw_pos','Pw_neg','class_priors','Pc_d_pos_train','Pc_d_neg_train','roc_curve_train','roc_op_train','roc_area_train','roc_threshold_train','rpc_curve_train','rpc_ap_train','rpc_area_train','rpc_threshold_train');

%%% copy conf_file into models directory too..
config_fname = which(config_file);
copyfile(config_fname,[RUN_DIR,'\',Global.Model_Dir_Name,'\',Global.Config_File_Name,prefZeros(model_ind,Global.Num_Zeros),'.m']);