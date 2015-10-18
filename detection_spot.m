function [ pos, neg, bbout, scaleout, w, valid, inconf_map,part_parent] = detection_spot(part_parent,root, nodepa, valid, npart, ~, scalepre, imgin, num, frame, pos, neg, w, bb, sbin )
%DETECTION_TREE Summary of this function goes here
%   Detailed explanation goes here
    

% % allocate some memory
width    = cell(1, npart);
height   = cell(1, npart);
winH     = cell(1, npart);
winW     = cell(1, npart);
test     = cell(1, npart);
bbtemp   = cell(1, npart); 
bbcenter = cell(1, npart);
len4     = cell(1, npart);
Ix1      = cell(1, npart); 
Iy1      = cell(1, npart);
part_cen = cell(1, npart);
map      = cell(1, npart);
loc_temp = cell(1, npart);
loc      = cell(1, npart);
inconf_map = cell(1, npart); 
confidence = cell(1, npart);
conf_part  = cell(1, npart);
part_partemp = zeros(npart, 2);

for i=1:npart

    % pixel size of object  
    height{i}=bb{i}(4)-bb{i}(2)+1;  % bb[y1 x1 y2 x2]
    width{i}=bb{i}(3)-bb{i}(1)+1;

    % block size of object
    winH{i}=round(height{i}/sbin)-1; 
    winW{i}=round(width{i}/sbin)-1;

    sigma = 25;
end

traff1=0.001;
traff2=0;
feat = RawFeat(imgin, sbin);

for ii=1:npart
    a = [pos{ii}; neg{ii}];
    if frame == 2
        alpha = svmtrain([zeros(size(pos{ii}, 1), 1); ones(size(neg{ii}, 1), 1)], [(1:size(a, 1))' a * a'], '-s 0 -t 4 -b 1 -e 1e-3 -c 1 -q');
        J = full(alpha.SVs);
        w{ii} = sum(bsxfun(@times, alpha.sv_coef, a(J,:)), 1)';
    else        
        if valid(ii)
           w{ii}= train_pa(a, [ones(size(pos{ii}, 1), 1); -ones(size(neg{ii}, 1), 1)], 1, w{ii});
        end
    end
    
    % Visualize classifier
%     n=0;
%     w_visual=zeros(winH,winW,9);
%     for k=1:9
%         for j=1:winW
%             for i=1:winH
%                 n=n+1;
%                 w_visual(i,j,k)=w(n);
%             end
%         end
%     end
%     map_w=visualizeHOG(w_visual);
%     dipshow(map_w);

    [ test{ii}, bbtemp{ii}, bbcenter{ii}, len4{ii}] = CalFeat( feat, winH{ii}, winW{ii}, height{ii}, width{ii},sbin);

    % Classify candidate locations
    confidence{ii} = 1 ./ (1 + exp(-(test{ii} * w{ii})));
    
    % Plot confidence map
%     conf_map = zeros(size(imgin, 1), size(imgin, 2));   
%     for j=1:len4{i}
%         conf_map(round(max(1,bbcenter{i}(j,1))):min(size(imgin,1),round(max(1,bbcenter{i}(j,1)))+3),round(max(1,bbcenter{i}(j,2))):min(size(imgin,2),round(max(1,bbcenter{i}(j,2)))+3)) = confidence{i}(j);
%     end
%     imagesc(conf_map), colormap gray, colorbar, drawnow, pause

    % Incorporate edge deformation   
    inconf_map{ii}=CalConfMap(confidence{ii}(1:len4{ii}),size(imgin,2),size(imgin,1),bbcenter{ii}(1:len4{ii},:),len4{ii});
    [inconf_map{ii}, Ix1{ii}, Iy1{ii}] = dt(inconf_map{ii},traff1,traff2,traff1,traff2);

    part_cen{ii}=[0.1 0.1];
    part_partemp(ii,:)=part_parent{ii};
end 

% Get path from node to root
part_parent{root}=[0 0];
part_partemp(root,:)=[0 0];
part_cen{root}=[0 0];
for i=1:length(nodepa)
    n=length(nodepa{i});
    temp = part_partemp(nodepa{i},:);
    for j=n-1:-1:1
        if part_cen{nodepa{i}(j)}(1)~=0 && part_cen{nodepa{i}(j)}(2)~=0 
           part_cen{nodepa{i}(j)}=sum(temp(j:n-1,:),1);
        end
    end
end

% Score map
suminconf_map=zeros(size(inconf_map{i},1),size(inconf_map{i},2));
for i=1:npart
    part_cen{i}=round(part_cen{i});
    map{i}=zeros(size(suminconf_map,1),size(suminconf_map,2));
    if part_cen{i}(1)<=0 && part_cen{i}(2)<=0
       map{i}(1:size(map{i},1)-abs(part_cen{i}(1)),1:size(map{i},2)-abs(part_cen{i}(2)))= inconf_map{i}(abs(part_cen{i}(1))+1:size(map{i},1),abs(part_cen{i}(2))+1:size(map{i},2));
    elseif part_cen{i}(1)<=0 && part_cen{i}(2)>0
       map{i}(1:size(map{i},1)-abs(part_cen{i}(1)),part_cen{i}(2)+1:size(map{i},2))= inconf_map{i}(abs(part_cen{i}(1))+1:size(map{i},1),1:size(map{i},2)-part_cen{i}(2));
    elseif part_cen{i}(1)>0 && part_cen{i}(2)<=0
       map{i}(part_cen{i}(1)+1:size(map{i},1),1:size(map{i},2)-abs(part_cen{i}(2)))= inconf_map{i}(1:size(map{i},1)-part_cen{i}(1),abs(part_cen{i}(2))+1:size(map{i},2)); 
    else
       map{i}(part_cen{i}(1)+1:size(map{i},1),part_cen{i}(2)+1:size(map{i},2))= inconf_map{i}(1:size(map{i},1)-part_cen{i}(1),1:size(map{i},2)-part_cen{i}(2)); 
    end
    suminconf_map=suminconf_map+map{i};
end
inconfi1 = max(suminconf_map(:));    
[x1,y1]=find(suminconf_map==inconfi1);

% Get positive feature
for i=1:npart     
    scaleout{i}=scalepre{i};
    loc_temp{i}=round([mean(x1) mean(y1)]-round(part_cen{i}*scalepre{i}));
    if loc_temp{i}(1)<1 || loc_temp{i}(1)>size(Iy1{i},1) || loc_temp{i}(2)<1 || loc_temp{i}(2)>size(Iy1{i},2)
       loc_temp{i}(1)=round(min(size(Iy1{i},1),max(1,loc_temp{i}(1))));
       loc_temp{i}(2)=round(min(size(Iy1{i},2),max(1,loc_temp{i}(2))));
    end 
    loc{i}=double([Iy1{i}(loc_temp{i}(1),loc_temp{i}(2)),Ix1{i}(loc_temp{i}(1),loc_temp{i}(2))]);
    [~,optindtemp]=max(confidence{i}(1:len4{i}));
    optcenter{i}=bbcenter{i}(optindtemp(1),:);
    if sum((loc{i}-optcenter{i}).^2)<200 
        indbb=optindtemp;  
        conf_part{i}=confidence{i}(indbb(1));
    else
      loctemp=(bbcenter{i}(1:len4{i},1)-loc{i}(1)).^2+(bbcenter{i}(1:len4{i},2)-loc{i}(2)).^2;
      [~,indbb]=min(loctemp);         
      conf_part{i}=confidence{i}(indbb(1));
    end 
    
    confidence_part(i)=test{i}(indbb(1),:) * w{i};
    bbcentemp=bbcenter{i}(indbb(1),:);

    postemp{i}=test{i}(indbb(1),:);
    bbouttemp=bbtemp{i}(indbb(1),:);           
           
    bbcenout{i}=bbcentemp;
    bbout{i}=bbouttemp;

    if conf_part{i}>0.4 || frame<=num 
        valid(i)=1;
        pos{i} = postemp{i};
    else
        valid(i)=0;
    end
end 

% Get negative feature and update edge vector
for i=1:npart    
    if valid(i) || frame<num
        neg_confidence{i}(1:len4{i})  = confidence{i}(1:len4{i}) .* (1 - exp(-sum(bsxfun(@minus, bbcenter{i}(1:len4{i},:),bbcenout{i}) .^ 2, 2) ./ (2 .* (scalepre{i} .* sigma) .^ 2)));
        [~, max_ind] = max(neg_confidence{i});
        neg{i} = test{i}(max_ind,:);
        negbbout{i}= bbtemp{i}(max_ind,:);
        negconf_opart{i}=test{i}(max_ind,:) * w{i};
        for j=1:length(nodepa)
           ind=find(i==nodepa{j});
           if ind==length(nodepa{j})
               parent=nodepa{j}(ind);
           elseif isempty(ind)==0 
               parent=nodepa{j}(ind+1);
           end
        end
        posvector{i}=bbcenout{parent}-bbcenout{i};
%         overlap_loss(i)=overlap_rate(negbbout{i},bbout{i});
%         Cvet=1;
%         loss=negconf_opart{i}-confidence_part(i)+traff1*sum((posvector{i}-part_parent{i}).^2)+overlap_loss(i);
%         loss_descen=4*traff1^2*sum((posvector{i}-part_parent{i}).^2);
%         stepsize=loss./ (loss_descen + (1 ./ (2 .* Cvet)));
%         part_parent{i}=part_parent{i}/scaleout{i}+2*traff1*stepsize*(posvector{i}-part_parent{i});
        part_parent{i}=(part_parent{i}/scaleout{i}+0.05*posvector{i})/1.05;
    end
end