function do_preprocessing(config_file, num)
  
%%% Function to copy the raw images for the source directory into the
%%% directory for the experiment and perform various normalizations on them
%%% in the process.  
  
%%% Currently the function normalizes all images to a fixed size
%%% (specificed in Preprocessing.Image_Size) using the axis specified in
%%% Preprocessing.Axis_For_Resizing (either 'x' or 'y'). 

%% Also rescales file containing ground thruth locations of objects
%% within the scene. File name that holds locations of objects is
%% specified in Global.Ground_Truth_Name. The variable in the file 
%% is gt_bounding_boxes which is a 1 x nImages (of that class) cell
%% array, each element holding a 4 x nInstances (per image) matrix, with
%% the bounding box for each instance within the image. The format is:
%% [top_left_x top_left_y width height];
%% (should originally be in subdirectories of IMAGE_DIR, but will be
%%  copied to RUN_DIR by do_preprocessing.m)
  
%%% All images are put into the RUNDIR/Global.Image_Dir_Name directory in one
%%% big collection; i.e. all images from all classes will be in the same directory  
  
%%% R.Fergus (fergus@csail.mit.edu) 8/9/05.  
  
%%% evaluate global configuration file
eval(config_file);

%%% reset frame counter
frame_counter = 0;
test_counter = 0;

%%% Remove 'images' and 'test_images' dirs
outdir = char(string(RUN_DIR)+'/'+Global.Image_Dir_Name);
if exist(outdir,'dir')
    rmdir(outdir,'s');
end
mkdir(outdir);
outdir = char(TEST_DIR);
if exist(outdir,'dir')
    rmdir(outdir,'s');
end

%%% make directory in experimental dir. for images
[s,m1,m2]=mkdir(RUN_DIR,Global.Image_Dir_Name);

%%%% Go through each of the categories
files = dir(IMAGE_DIR);
dirFlags = [files.isdir];
subFolders = files(dirFlags);

pat_range = 149;
pat_offset = 13;
patients_processed = 0;
for pat = 1 : pat_range
    pat_num = "";
    if pat < pat_offset
        pat_num = "-1_"+pat;
    else
        pat_num = int2str(pat - pat_offset);
    end
      
    pat_dir = IMAGE_DIR + "/patient" + pat_num;
      
      % Check that our patient exists before trying to load files
      % Don't include test patient in training images - we will handle this
      % later
    num_processed = 0;
    if exist(pat_dir, 'dir') && pat_num ~= HEALTHY_PATIENTS(num)
       patients_processed = patients_processed + 1;
       for cat = 1 : Categories.Number
          %%% Generate filenames for images
          in_file_names = dir(char(pat_dir+'/'+Categories.Name(cat)));

          for frame = 3:length(in_file_names)

            file_name = string(in_file_names(frame).folder) + '/' + string(in_file_names(frame).name);
            %%% read image in 
            im = imread(char(file_name));

            %%% find out size of image
            [imy,imx,imz] = size(im);

            %%% Resize image, proved Preprocessing.Image_Size isn't zero
            %%% in which case, do nothing.
            if (Preprocessing.Image_Size>0)

              %%% Figure out scale factor for resizing along appropriate axis
              if strcmp(Preprocessing.Axis_For_Resizing,'x')
                scale_factor = Preprocessing.Image_Size / imx;
              elseif strcmp(Preprocessing.Axis_For_Resizing,'y')
                scale_factor = Preprocessing.Image_Size / imy;     
              else
                error('Unknown axis');
              end

              %%% Rescale image using bilinear scaling
              if scale_factor ~= 1
                  im = imresize(im,scale_factor,Preprocessing.Rescale_Mode);
              end
            else
              scale_factor = 1;
            end

            outdir = char(string(RUN_DIR)+'/'+Global.Image_Dir_Name+'/'+Categories.Name(cat));
            if ~exist(outdir,'dir')
                mkdir(outdir);
            end
            
             %%% increment frame counter
            frame_counter = frame_counter + 1;
            num_processed = num_processed + 1;
            
            %%% Now save out to directory.
            fname = char(string(RUN_DIR)+'/'+Global.Image_Dir_Name+'/'+Categories.Name(cat)+'/'+Global.Image_File_Name+prefZeros(frame_counter,Global.Num_Zeros)+Global.Image_Extension);
            imwrite(im,fname,Global.Image_Extension(2:end));

            if (mod(frame_counter,10)==0)
              fprintf('.');
            end

          end

       end
      fprintf("\nPatient "+pat_num+": "+int2str(num_processed)+" images processed\tTotal: "+int2str(frame_counter)+"\n");
    elseif pat_num == HEALTHY_PATIENTS(num) % put test patient data into sub folder
        for cat = 1 : Categories.Number
            cat_dir = char(string(TEST_DIR) + '/' + Categories.Name(cat));
            if exist(cat_dir,'dir')
                rmdir(cat_dir,'s');
            end
            mkdir(cat_dir);
          %%% Generate filenames for images
            in_file_names = dir(char(pat_dir+'/'+Categories.Name(cat)));
            for frame = 3:length(in_file_names)
                file_name = string(in_file_names(frame).folder) + '/' + string(in_file_names(frame).name);
                %%% read image in 
                im = imread(char(file_name));

                %%% find out size of image
                [imy,imx,imz] = size(im);

                %%% Resize image, proved Preprocessing.Image_Size isn't zero
                %%% in which case, do nothing.
                if (Preprocessing.Image_Size>0)

                  %%% Figure out scale factor for resizing along appropriate axis
                  if strcmp(Preprocessing.Axis_For_Resizing,'x')
                    scale_factor = Preprocessing.Image_Size / imx;
                  elseif strcmp(Preprocessing.Axis_For_Resizing,'y')
                    scale_factor = Preprocessing.Image_Size / imy;     
                  else
                    error('Unknown axis');
                  end

                  %%% Rescale image using bilinear scaling
                  im = imresize(im,scale_factor,Preprocessing.Rescale_Mode);
                else
                  scale_factor = 1;
                end

                test_counter = test_counter + 1;
                %%% Now save out to directory.
                fname = char(string(TEST_DIR)+'/'+Categories.Name(cat)+'/'+Global.Image_File_Name+prefZeros(test_counter,Global.Num_Zeros)+Global.Image_Extension);
                imwrite(im,fname,Global.Image_Extension(2:end));
          end
        end
    end
end
