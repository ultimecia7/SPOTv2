function spot(movie_name)

addpath 'libsvm'
filetype=1; %#ok<*NASGU>

% Get list of images and movie properties
Obj =  VideoReader(movie_name);
nFrames = Obj.NumberOfFrames;
firstFrame = read(Obj,1);
% Some parameters for the experiment
sbin = 8;       % size of HOG block
num = 10;        % number of frames for which we always add positive sample

%Detect Motion field using Optical Flow
                         
optical = vision.OpticalFlow( ...
    'OutputValue', 'Horizontal and vertical components in complex form');
shapes = vision.ShapeInserter;
shapes.Shape = 'Lines';
shapes.BorderColor = 'white';
%Get Video Frame width&height
[m,n,rgbField]=size(firstFrame);
r = 1:5:m;
c = 1:5:n;
[Y, X] = meshgrid(c,r);
preprocessFrames=10;
hVideoIn = vision.VideoPlayer;
hVideoIn.Name  = 'Original Video';
hVideoOut = vision.VideoPlayer;
hVideoOut.Name  = 'Motion Detected Video';

% Set up for stream
frameCount = 0;
vr = vision.VideoFileReader(movie_name);
motionFieldImg=firstFrame;
while (frameCount<preprocessFrames)     % Process for the first 100 frames.
    % Acquire single frame from imaging device.
    rgbData = step(vr);

    % Compute the optical flow for that particular frame.
    optFlow = step(optical,rgb2gray(rgbData));

    % Downsample optical flow field.
    optFlow_DS = optFlow(r,c);
    H = imag(optFlow_DS)*50;
    V = real(optFlow_DS)*50;

    % Draw lines on top of image
    lines = [Y(:)'; X(:)'; Y(:)'+V(:)'; X(:)'+H(:)'];
    rgb_Out = step(shapes, rgbData,  lines');
    grimg=rgb2gray(rgb_Out);
    [rows, cols]=find(abs(grimg-1.0) < 0.001);
    for i=1:size(rows)
        grimg(rows(i),cols(i))=0;
    end
    % Send image data to video player
    % Display original video.
    step(hVideoIn, rgbData);
    % Display video along with motion vectors.
    step(hVideoOut, rgb_Out);

    % Increment frame count
    frameCount = frameCount + 1;
end

release(hVideoIn);
release(hVideoOut);
    
figure,imshow(rgb2gray(motionFieldImg)),title('Motion Field');                  
displayEndOfDemoMessage(mfilename)


for i=1:nFrames
    tic    
%     i
    
    % Read image
    rgbImage = read(Obj, i); %#ok<*GENDEP>
    img = rgbImage;
    if ~ismatrix(img)
       img = rgb2gray(img);
    end
         
    % Set up some parameters for the first time
    if i == 1
         
       %Threshold
       %[Ibw, thres] = autoThreshold(img);
       %imshow(Ibw);
        
       %Region Growth
       J = regionGrow(cannyEdge,img);
       figure, imshow(J),title('Image After')
       
       
       %Video Pattern Matching
       [locat] = ...
           videopatternmatching(img, movie_name, rgbImage);
       
       
       %Choose random part inside an object
%        locat1 = locat{1};
%        inside_locat = cell(1,4);
%        inside_locat{1} = [locat1(1,1) locat1(1,2) locat1(1,3)/4 locat1(1,4)/4];
%        inside_locat{2} = [locat1(1,1)+0.75*locat1(1,3) locat1(1,2) locat1(1,3)/4 locat1(1,4)/4];
%        inside_locat{3} = [locat1(1,1) locat1(1,2)+0.75*locat1(1,4) locat1(1,3)/4 locat1(1,4)/4];
%        inside_locat{4} = [locat1(1,1)+0.75*locat1(1,3) locat1(1,2)+0.75*locat1(1,4) locat1(1,3)/4 locat1(1,4)/4];
%        
%        locat = inside_locat;

       
       % Read ground truth location for first frame
        npart = length(locat);
        bb=cell(1,npart);
        bbcenter=cell(1,npart);
        bbout=cell(1,npart);
        location=cell(1,npart);
        results=cell(1,npart);
        pos=cell(1,npart);
        neg=cell(1,npart);
        w=cell(1,npart);
        partloc=[];
        objrect=cell(1,npart);
        
        figure,imshow(rgbImage);
        
        for j=1:npart  
            
            bb{j}=[locat{j}(1,1) locat{j}(1,2) locat{j}(1,1)+locat{j}(1,3) locat{j}(1,2)+locat{j}(1,4)];
            
%             h = imrect;
%             p = wait(h);
%             bb{j} = round([p(1), p(2),p(1)+p(3), p(2)+p(4)]); %y1 x1 y2 x2

            bbcenter{j}=round(0.5*([bb{j}(2)+bb{j}(4) bb{j}(1)+bb{j}(3)]));
            
            % Get first positive example
            bb{j} = round(bb{j});
            location{j}(1,:) = bb{j}; 
            patch = img(bb{j}(2)-4:bb{j}(4)+4, bb{j}(1)-4:bb{j}(3)+4);
            feat = features_gray(patch, sbin);
            feat = feat(:,:,1:9) + feat(:,:,10:18);
            
            pos{j} = repmat([feat(:)' 1], [50 1]);
            
            % Get bunch of negative examples
            neg{j} = initial_multiscale(img, pos{j}, bb{j}, sbin, 50);
            bbout{j} = bb{j}';
            scalepre{j} = 1;

            valid(j)=1;
            partloc=[partloc;bbcenter{j}];
        end
        
        % Build minimum spanning tree
        [ tree, root, nodepath ] = CreateTree( img, partloc );
        for k=1:npart
            for j=1:length(nodepath)
                ind=find(k==nodepath{j});
                if ind==length(nodepath{j})
                   parent=nodepath{j}(ind);
                elseif isempty(ind)==0 
                   parent=nodepath{j}(ind+1);
                end
            end
            part_parent{k}=[(bbout{parent}(2)+bbout{parent}(4))/2-(bbout{k}(2)+bbout{k}(4))/2 (bbout{parent}(1)+bbout{parent}(3))/2-(bbout{k}(1)+bbout{k}(3))/2];
        end

    else
        
        % Run detector
        for k=1:npart
            bbpre{k}=location{k}(i-1,:);
        end 

        [pos, neg, bbout, scale, w, valid, inconf_map1,part_parent] = detection_spot(part_parent,root, nodepath, valid, npart, bbpre, scalepre, img, num, i, pos, neg, w, bb, sbin );

        scalepre = scale;
        
        % Confidence map
        imtem=[];
        for j=1:npart
            imtem=[imtem;inconf_map1{j}];
        end
    end
    
    % Plot bounding box
    if i==1
       imtemp=0.*imresize(img,[size(img,1) round(size(img,2)/npart)]);
    else
       imtemp=255.*imresize(imtem,[size(img,1) round(size(img,2)/npart)]);
    end
    imgout=[img imtemp];

    if i==1
    handle = imshow(imgout);
    else
    set(handle,'cdata',imgout); hold on;
    end
    axis off

    if i>1
       for j=1:npart
           delete(objrect{j})
       end
    end
    for j=1:npart
        bbshow{j}=[bbout{j}(1) bbout{j}(2) bbout{j}(3)-bbout{j}(1) bbout{j}(4)-bbout{j}(2)];
        if valid(j)==1 % high confidence
           if j==1
              objrect{j} = rectangle('Position', bbshow{j},'EdgeColor','yellow','LineWidth',2,'LineStyle','-'); 
           elseif j==2
              objrect{j} = rectangle('Position', bbshow{j},'EdgeColor','red','LineWidth',2,'LineStyle','-');
           elseif j==3
              objrect{j} = rectangle('Position', bbshow{j},'EdgeColor','green','LineWidth',2,'LineStyle','-');
           elseif j==4
              objrect{j} = rectangle('Position', bbshow{j},'EdgeColor','blue','LineWidth',2,'LineStyle','-'); 
           end
        else  %low confidence
           if j==1
              objrect{j} = rectangle('Position', bbshow{j},'EdgeColor','yellow','LineWidth',2,'LineStyle','--'); 
           elseif j==2
              objrect{j} = rectangle('Position', bbshow{j},'EdgeColor','red','LineWidth',2,'LineStyle','--');
           elseif j==3
              objrect{j} = rectangle('Position', bbshow{j},'EdgeColor','green','LineWidth',2,'LineStyle','--');
           elseif j==4
              objrect{j} = rectangle('Position', bbshow{j},'EdgeColor','blue','LineWidth',2,'LineStyle','--');
           end
        end
        location{j}(i,:) = bbout{j};
%         results{j}(i,:) = bbshow{j};
    end
    if ispc
        drawnow;
    end
    hold off;
    
    %toc;
end

% for i = 1:npart
%     filename = strcat('result', int2str(i), '.mat');
%     loc = results{i};
%     save(filename, 'loc');
% end
end