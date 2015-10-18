function [feat, img] = RawFeat(imgin, sbin)
%RAWFEAT Summary of this function goes here
%   Detailed explanation goes here
img=double(imgin);

% Extract HOG features
[feat{1}, feat{2}, feat{3}, feat{4}] = features_layers(img, sbin);    
feat{1}=feat{1}(:,:,1:9)+feat{1}(:,:,10:18);
feat{2}=feat{2}(:,:,1:9)+feat{2}(:,:,10:18);
feat{3}=feat{3}(:,:,1:9)+feat{3}(:,:,10:18);
feat{4}=feat{4}(:,:,1:9)+feat{4}(:,:,10:18);