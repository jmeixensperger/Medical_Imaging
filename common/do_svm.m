function do_svm(config_file)

% Function that runs the Naive Bayes classifier on histograms of
% vector-quantized image regions. Based on the paper:
% 
% Visual categorization with bags of keypoints
% Chris Dance, Jutta Willamowski, Lixin Fan, Cedric Bray, Gabriela Csurka
% ECCV International Workshop on Statistical Learning in Computer Vision, Prague, 2004. 
% http://www.xrce.xerox.com/Publications/Attachments/2004-010/2004_010.pdf
  
% Note that this only trains a model. It does not evaluate any test
% images. Use do_naive_bayes_evaluation for that.  
  
% Before running this, you must have run:
%    do_random_indices - to generate random_indices.mat file
%    do_preprocessing - to get the images that the operator will run on  
%    do_interest_op  - to get extract interest points (x,y,scale) from each image
%    do_representation - to get appearance descriptors of the regions  
%    do_vq - vector quantize appearance of the regions
  
% R.Fergus (fergus@csail.mit.edu) 03/10/05.  
%%
% Evaluate global configuration file
eval(config_file);

% ensure models subdir is present
[s,m1,m2]=mkdir(RUN_DIR,Global.Model_Dir_Name);

% get all file names of training image interest point files
temp_file_names = dir(IP_DIR);
temp_file_names = temp_file_names(3:end);
ip_file_names = [];
for a=1:size(temp_file_names,1)
    %pos_ip_file_names =  [pos_ip_file_names , ];
    file_name = char(string(temp_file_names(a).folder) + "/" + string(temp_file_names(a).name));
    ip_file_names = [ip_file_names; file_name];
end

% Create matrix to hold word histograms from +ve images
X = zeros(VQ.Codebook_Size,size(ip_file_names,1));

% load up all interest_point files which should have the histogram
% variable already computed (performed by do_vq routine).
classes = unique(Categories.Name);
Y = cell(size(ip_file_names,1),1);
for a=1:length(ip_file_names)
    % load file
    load(char(ip_file_names(a,:)));
    % store histogram
    X(:,a) = histg';
    % store labels
    temp_Y = "none";
    for n=1:length(classes)
        if ground_truth == classes(n)
            temp_Y = ground_truth;
        end
    end
    Y(a) = cellstr(temp_Y);
end 

X = X';
SVMModels = cell(5,1);
classes = unique(Categories.Name);
for i =1:numel(classes)
    indx = strcmp(Y,classes(i));
    SVMModels{i} = fitcsvm(X, indx, 'ClassNames', [false, true], 'Standardize', true, 'KernelFunction', 'rbf', 'OptimizeHyperparameters', 'auto');
end

Scores = zeros(size(X,1),numel(classes));
for i=1:numel(classes)
    [~,score] = predict(SVMModels{i},X);
    Scores(:,i) = score(:,2);
end
% Find max score (prediction for which class the ith image contains)
[~,maxScore] = max(Scores,[],2);

%%

figure
train_auc = zeros(numel(classes),1);
train_opt = zeros(numel(classes),1);
for i=1:numel(classes)
    scores = double(zeros(size(maxScore,1),1));
    for j=1:length(maxScore)
        if maxScore(j) == i
            scores(j) = 1;
        end
    end
    [x, y, t, auc, opt] = perfcurve(Y, scores, classes(i));
    train_auc(i) = auc;
    % outputs two values?
    train_opt(i) = opt(1);
    fprintf('Training %s images: area under perf curve = %f\n', string(classes(i)), auc);
    subplot(2,3,i)
    plot(x,y)
    xlabel('False positive rate')
    ylabel('True positive rate')
    title(string(classes(i))+" ROC")
end

%%

%%% compute roc
%[roc_curve_train,roc_op_train,roc_area_train,roc_threshold_train] = roc([values;labels]');
%fprintf('Training: Area under ROC curve = %f; Optimal threshold = %f\n', roc_area_train, roc_threshold_train);
%%% compute rpc
%[rpc_curve_train,rpc_ap_train,rpc_area_train,rpc_threshold_train] = recall_precision_curve([values;labels]',length(pos_ip_file_names));
%fprintf('Training: Area under RPC curve = %f\n', rpc_area_train);

%%

%%% Now save model out to file
[fname,model_ind] = get_new_model_name([RUN_DIR,'\',Global.Model_Dir_Name],Global.Num_Zeros);

%%% save variables to file
save(fname,'SVMModels','Y', 'train_auc', 'train_opt', 'maxScore');

%%% copy conf_file into models directory too..
config_fname = which(config_file);
copyfile(config_fname,[RUN_DIR,'\',Global.Model_Dir_Name,'\',Global.Config_File_Name,prefZeros(model_ind,Global.Num_Zeros),'.m']);