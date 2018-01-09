function [tp, fp, fscore, roc_area_test] = do_svm_evaluation(config_file,num)

%% Test and plot graphs for a naive bayes classifier learnt with do_naive_bayes.m

%% The action of this routine depends on the directory in which it is
%% run: 
%% (a) If run from RUN_DIR, then it will evaluate the latest model in the
%% models subdirectory. i.e. if you have just run
%% do_plsa('config_file_2'), which saved to model_0011.mat and
%% config_file_0011.m in the models subdirectory in RUN_DIR, then doing
%% do_plsa_evaluation('config_file_2') will load up model_0011.mat and
%% evaluate it. 
%% (b) If run within in models subdirectory, then it
%% will evaluate the model corresponding to the configuration file passed
%% to it. i.e. do_plsa_evaluation('config_file_0002') will load
%% model_0002.mat and evaluate/plot figures for it. 
%%  
%% Mode (a) exists to allow a complete experiment to be run from start to
%% finish without having to manually go into the models subdirectory and
%% find the appropriate one to evaluate.
  
%% If this routine is called on a newly learnt model, it will run the pLSA code
%% in folding in mode and then plot lots of figures. If run a second time
%% on the same model, it will only plot the figures, since there is no need
%% to recompute the statistics on the testing images. If you want to force it
%% to re-run on the images, then remove the Pc_d_pos_test variable from the
%% model file. 
  
%% Note this only uses a pre-existing model to evaluate the test
%% images. Please use do_naive_bayes to actually learn the classifiers.  
%% Before running this, you must have run:
%%    do_random_indices - to generate random_indices.mat file.
%%    do_preprocessing - to get the images that the operator will run on.  
%%    do_interest_op  - to get extract interest points (x,y,scale) from each image.
%%    do_representation - to get appearance descriptors of the regions.  
%%    do_vq - vector quantize appearance of the regions in each image.
%%    do_naive_bayes - learn a Naive Bayes classifier.
  
%% R.Fergus (fergus@csail.mit.edu) 03/10/05.  

%% figure numbers to start at
FIGURE_BASE = 2000;
%% color ordering
cols = {'g' 'r' 'b' 'c' 'm' 'y' 'k'};
markers = {'+', '.'};

%% Evaluate global configuration file
eval(config_file);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Model section
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% get filename of model to learn
%%% if in models subdirectory then just get index off config_file string
if (strcmp(pwd,[RUN_DIR,'/',Global.Model_Dir_Name]) | strcmp(pwd,[RUN_DIR,'\',Global.Model_Dir_Name]))
    ind = str2num(config_file(end-Global.Num_Zeros+1:end));
else
    %%% otherwise just take newest model in subdir.
    ind = length(dir([RUN_DIR,'/',Global.Model_Dir_Name,'/',Global.Model_File_Name,'*.mat']));    
end
%%% construct model file name
model_fname = [RUN_DIR,'/',Global.Model_Dir_Name,'/',Global.Model_File_Name,prefZeros(ind,Global.Num_Zeros),'.mat'];

%%% load up model
load(model_fname);

%%

% get all file names of test image interest point files
test_out_files = dir(char(string(TEST_DIR) + "/*.mat"));
temp_file_names = [];
for a=1:length(test_out_files)
    file_name = char(string(test_out_files(a).folder) + "/" + string(test_out_files(a).name));
    temp_file_names = [temp_file_names; file_name];
end

% Create matrix to hold word histograms from +ve images
X = zeros(VQ.Codebook_Size,size(temp_file_names,1));

% load up all interest_point files which should have the histogram
% variable already computed (performed by do_vq routine).
classes = unique(Categories.Name);
Y = cell(size(temp_file_names,1),1);
for a=1:size(temp_file_names,1)
    % load file
    load(char(temp_file_names(a,:)));
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

%%
classes = unique(Categories.Name);
% Scores = zeros(size(X,1),numel(classes));
% for i=1:numel(classes)
%     [~,score] = predict(SVMModels{i},X);
%     Scores(:,i) = score(:,2);
% end
% % Find max score (prediction for which class the ith image contains)
% [~,maxScore] = max(Scores,[],2);
[predictY, values] = predict(SVMModel,X);
values = values(:,2)';
labels = strcmp(Y,'healthy')';

%%% compute roc
[roc_curve_test,roc_op_test,roc_area_test,roc_threshold_test] = roc([values;labels]');
fprintf('Testing: Area under ROC curve = %f\n', roc_area_test);

%% Get image filenames and ip filenames
image_file_names = cell(size(temp_file_names,1),1);
image_num = 1;
for i=1:length(Categories.Name)
    cat_dir = char(TEST_DIR + "/" + Categories.Name(i));
    if exist(cat_dir, 'dir')
        listing = dir(cat_dir);
        for a=3:size(listing,1)
            file_name = string(listing(a).folder) + "/" + string(listing(a).name);
            image_file_names(image_num) = cellstr(file_name);
            image_num = image_num + 1;
        end
    end
end
ip_file_names = temp_file_names;

% %% next decide on plotting order
% if strcmp(Plot.Example_Mode,'ordered')
%     %%% just go in orginial order of images
%     [~, plot_order] = sort(Categories.All_Test_Frames);
% elseif strcmp(Plot.Example_Mode,'alternate')
%     %%% using random order but alternating between images of different
%     %%% classes...
%     ind = ones(Categories.Number,max(cellfun('length',Categories.Test_Frames)));
%     tmp = length(Categories.Test_Frames{1});
%     ind(1,1:tmp)=[1:tmp];
%     for a=2:Categories.Number
%         tmp = length(Categories.Test_Frames{a});
%         offset=sum(cellfun('length',Categories.Test_Frames(1:a-1)));
%         ind(a,1:tmp) = [1:tmp]+offset;
%    end
%    plot_order = ind(:);
%    
% elseif strcmp(Plot.Example_Mode,'random')
%     %%% using order given in random_indices.mat
%     plot_order = 1: length(Categories.All_Test_Frames);
% elseif strcmp(Plot.Example_Mode,'best')
%     %%% plot ordered by ratio of posteriors, worst first
%     [tmp2,plot_order] = sort(-values);
% elseif strcmp(Plot.Example_Mode,'worst')
%     %%% plot ordered by ratio of posteriors, worst first
%     [tmp2,plot_order] = sort(values);    
% elseif strcmp(Plot.Example_Mode,'borderline')
%     %%% images closest to threshold
%     %%% ordering by how close they are to the ROC thresholds...
%     [tmp2,plot_order] = sort(abs(values-roc_threshold_train));
% else
%     error('Unknown type of Plot.Example_Mode');
% end 
   
%% now setup figure and run loop plotting images
%figure(FIGURE_BASE+2);
nImage_Per_Figure = prod(Plot.Number_Per_Figure);
pos_count = 0;
neg_count = 0;
tp_count = 0;
fp_count = 0;

for a=1:size(ip_file_names,1)
    
        b = mod(a,nImage_Per_Figure)+1;
        if b == 1
            %pause
            %clf;
        end
        %%% actual index
        index = a;

            %%% load image
            im=imread(char(image_file_names(index)));
            
            %%% load up interest_point file
            load(ip_file_names(index,:));
            
            %% Plot image
            
            %%% get correct subplot
            %subplot(Plot.Number_Per_Figure(1),Plot.Number_Per_Figure(2),b);

            %%% show image
            %imagesc(im); hold on;

            %%% if grayscale, then adjust colormap
            %if (size(im,3)==1)
            %    colormap(gray);
            %end 

            %%% loop over all regions, plotting and coloring according to Pw_z
    %         for c=1:length(x)
    %             %%% which topic is favoured by the region?
    %             [tmp,preferred_class]=max([Pw_pos(descriptor_vq(c)) , Pw_neg(descriptor_vq(c))]);
    %             %%% plot center of region
    %             plot(x(c),y(c),'Marker',markers{preferred_class},'MarkerEdgeColor',cols{rem(preferred_class-1,7)+1});
    %             %%% and circle showing scale
    %             drawcircle(y(c),x(c),6*scale(c),cols{rem(preferred_class-1,7)+1},1);
    %             hold on;    
    %         end

            %%% do we plot header information?
            if (Plot.Labels)

                above_threshold = (values(index)>roc_threshold_train);
                if labels(index) == 1
                    pos_count = pos_count + 1;
                else
                    neg_count = neg_count + 1;
                end
                
                imageIndex = index;
                if (above_threshold==labels(index)) %% Correct classification
                    if labels(index) == 1
                        tp_count = tp_count + 1;
                    end
                    %% show image number and Pz_d
                    %title(['Correct - Image: ',num2str(imageIndex)]);    
                else
                    if labels(index) == 0
                        fp_count = fp_count + 1;
                    end
                    %% show image number and Pz_d
                    %title(['INCORRECT - Image: ',num2str(imageIndex)]);    
                end

                fprintf('Image: %d \t Score: %f\n',imageIndex,values(index));
            end
    
end

%% Calculate TP/FP and f-score
tp = tp_count / pos_count;
fp = fp_count / neg_count;
precision = tp / (tp + fp);
fscore = 0;
if tp ~= 0 || fp ~= 0
    fscore = (2 * tp * precision) / (tp + precision);
end
fprintf('Test Patient: %s \t TruePos: %f \t FalsePos: %f \t F-Score: %f \t OptThresh: %f \t TestROCArea: %f\n', ...
    HEALTHY_PATIENTS(num),tp,fp,fscore,roc_threshold_train,roc_area_test);
