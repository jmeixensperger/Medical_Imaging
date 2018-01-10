function DoG(image_file_names,output_file_names,extractor_type)

  %% Simple interest operator that:
  %%    1. Runs difference of Gaussian operator on image using VL FEAT package.

  %% Inputs: 
  %%      1. image_file_names - cell array of filenames of all images to be processed
  %%      2. output_file_names - cell array of output filenames

  %% Outputs:
  %%      None - it saves the results for each image to the files
  %%      specified in output_file_names.
  %%      Each file holds 4 variables:
  %%          x - x coordinates of points (1 x NumPoints)
  %%          y - y coordinates of points (1 x NumPoints)
  %%          scale - characteristic scale of points (radius, in pixels)  (1 x NumPoints)
  %%          angle - dominant angle of the region around each keypoint  (1 x NumPoints)
  %%          score - Always 1 (1 x NumPoints).
  %%          descriptor - SIFT descriptors of all keypoints (128 x NumPoints)
  
%%% Get total number of images
nImages = length(image_file_names);

%%% Loop over all images
for i = 1:nImages

  filestr = image_file_names(i,:);
  filestr = char(filestr);
  
  % read in ith image
  im = imread(filestr);

  % Convert to single, grayscale image
  imGray = single(rgb2gray(im));

  %features = MR8fast(imGray);
  
  % From f and d extract x, y, scale, angle and descriptor.
  % The following code was used to extract SIFT features (no longer used):
  % Total number of features from image
  if extractor_type == "sift"
       [f,d] = vl_sift(imGray);
       nFeats = size(f,2);
       x = f(1,:);
       y = f(2,:);
       scale = f(3,:);
       angle = f(4,:);
       descriptor = d;
       score = ones(1, nFeats);
  else
      % test hog, freak, surf, and other existing feature extractors
      pass
  end

   % save ground truth information
   ground_truth = "";
   if contains(filestr,"healthy")
       ground_truth = "healthy";
   elseif contains(filestr,"emphysema")
       ground_truth = "emphysema";
   elseif contains(filestr,"fibrosis")
       ground_truth = "fibrosis";
   elseif contains(filestr,"micronodules")
       ground_truth = "micronodules";
   elseif contains(filestr,"ground_glass")
       ground_truth = "ground_glass";
   end

  fprintf('Image: %d, Number of features detected: %d\n',i,length(x));
  % Save in output file
  save(output_file_names(i,:),'x','y','scale','angle','descriptor','score','ground_truth');
  
   %%% print out progress every 10 images    
   if (mod(i,10)==0)
      fprintf('%d.',i);
   end
end
