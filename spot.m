function spot(movie_name)

addpath 'libsvm'
filetype=1; %#ok<*NASGU>

% Get list of images and movie properties
Obj =  VideoReader(movie_name);
nFrames = Obj.NumberOfFrames;

% Some parameters for the experiment
sbin = 8;       % size of HOG block
num = 10;        % number of frames for which we always add positive sample

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