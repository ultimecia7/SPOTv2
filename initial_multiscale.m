function [ neg ] = initial_multiscale(img, pos, bb, sbin, sampleNum)
%INITIAL Summary of this function goes here
%   Detailed explanation goes here

    neg = zeros(2*sampleNum, size(pos, 2));
    
    % Sample random locations for negatives
    winH = round(bb(4) - bb(2) + 1+sbin);
    winW = round(bb(3) - bb(1) + 1+sbin);  
    y1 = 1 + round((size(img, 2) - winW - 1) * rand(1, 2*sampleNum));
    x1 = 1 + round((size(img, 1) - winH - 1) * rand(1, 2*sampleNum));
    
    % Sample random negative examples and store feature vectors
    t=0;
    for i=1:2*sampleNum
        if (x1(i)- bb(2))^2 + (y1(i)- bb(1))^2>50
           patch = img(x1(i):x1(i) + winH - 1, y1(i):y1(i) + winW - 1);
           feat = features_gray(patch, sbin);
           feat = feat(:,:,1:9) + feat(:,:,10:18);
           neg(i,:) = [feat(:)' 1];
           t=t+1;
        end
        if t==sampleNum
            break;
        end
    end
    
