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
fprintf("Performing interest operator on %d images", nImages);

%%% Loop over all images
for i = 1:nImages

  filestr = image_file_names(i,:);
  filestr = char(filestr);
  
  % read in ith image
  im = imread(filestr);
  [rows, cols] = size(im);

  % Convert to single, grayscale image
  imGray = rgb2gray(im);
  
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
  
  % From f and d extract x, y, scale, angle and descriptor.
  % The following code was used to extract SIFT features (no longer used):
  % Total number of features from image
  if extractor_type == "sift" || extractor_type == "lbp"
        imGray = single(imGray);
        [f,d] = vl_sift(imGray);
        nFeats = size(f,2);
        x = f(1,:);
        y = f(2,:);
        scale = f(3,:);
  end
  if extractor_type == "sift"
        angle = f(4,:);
        descriptor = d;
        score = ones(1, nFeats);
        save(output_file_names(i,:),'x','y','scale','angle','descriptor','score','ground_truth');
        fprintf('Image: %d, Number of features detected: %d\n',i,length(x));
  elseif extractor_type == "filter_banks"
        %test hog, freak, surf, and other existing feature extractors
        descriptor = MRS4fast(imGray)';
        x = floor(i / cols) + 1;
        y = mod(i,rows) + 1;
        save(output_file_names(i,:),'x','y','descriptor','ground_truth');
  elseif extractor_type == "lbp"
       [f,d] = vl_sift(imGray);
       angle = f(4,:);
       score = ones(1, nFeats);
       descriptor = [];
       for j = 1:nFeats
           % Calculate bounds of feature
           Top = round(x(j)-3*scale(j));
           Bot = round(x(j)+3*scale(j));
           Left = round(y(j)-3*scale(j));
           Right = round(y(j)+3*scale(j));
           [height, width, dim] = size(imGray);
           % Clip out of bounds values
           if(Left < 1)
               Left = 1;
           end
           if(Top < 1)
               Top = 1;
           end
           if(Bot > height)
               Bot = height;
           end
           if(Right > width)
               Right = width;
           end
           % Crop feature from image and find descriptor with LBP
           patch = imcrop(imGray,[Left Top (Right-Left) (Bot-Top)]);
           [H,W] = size(patch); 
           descriptor = [descriptor; extractLBPFeatures(patch, 'CellSize',[H W])];
       end
       descriptor = transpose(descriptor);
       save(output_file_names(i,:),'x','y','scale','descriptor','ground_truth');
  end
  
   %%% print out progress every 500 images    
   if (mod(i,500)==0)
      fprintf('%d.',i);
   end
end
