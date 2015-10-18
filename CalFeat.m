function [ test, bbtemp, bbcenter, len4] = CalFeat( feat, winH, winW, height, width,sbin,width_p,height_p)
%CALFEAT Summary of this function goes here
%   Detailed explanation goes here

len=zeros(1,12);
% Compute number of locations    
for i=1:length(feat)
    if i==1
       len(i)=(size(feat{i},1)-winH+1)*(size(feat{i},2)-winW+1);
    else
       len(i)=len(i-1)+(size(feat{i},1)-winH+1)*(size(feat{i},2)-winW+1);
    end
end
len4=len(4);

% Allocate some memory
%     test = zeros(winH * winW * 9+1, len4);
%     bbtemp = zeros(len4, 4);       % this stores the bounding box for all test samples
%     bbcenter = zeros(len4, 2);     % this stores the center location for all test samples

% Previous scale 
featsize=[size(feat{1},1),size(feat{1},2);size(feat{2},1),size(feat{2},2);size(feat{3},1),size(feat{3},2);size(feat{4},1),size(feat{4},2)];
offset=[0 0;0 4;4 0;4 4];
[test,bbtemp,bbcenter]=GetAllFeatures(feat{1},feat{2},feat{3},feat{4},width,height,featsize,sbin,offset,1,1);

bbcenter=round(bbcenter);


