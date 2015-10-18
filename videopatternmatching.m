function [ locat ] = videopatternmatching(img, movie_name, rgbImage)
%VIDEOPATTERNMATCHING Summary of this function goes here
%   Detailed explanation goes here
        threshold = single(0.89);
        level = 2;
        hGaussPymd1 = vision.Pyramid('PyramidLevel',level);
        hGaussPymd2 = vision.Pyramid('PyramidLevel',level);
        hGaussPymd3 = vision.Pyramid('PyramidLevel',level);
        hRotate1 = vision.GeometricRotator('Angle', pi);
        hFFT2D1 = vision.FFT;
        hFFT2D2 = vision.FFT;
        hIFFFT2D = vision.IFFT;
        hConv2D = vision.Convolver('OutputSize','Valid');

        
        useDefaultTarget = false;
        [Img, numberOfTargets, target_image] = ...
                videopattern_gettemplate(useDefaultTarget, movie_name);
        
        target_image = single(target_image);
        target_dim_nopyramid = size(target_image);
        target_image_gp = step(hGaussPymd1, target_image);
        target_energy = sqrt(sum(target_image_gp(:).^2));
        
        target_image_rot = step(hRotate1, target_image_gp);
        [rt, ct] = size(target_image_rot);
        Img = single(Img);
        Img = step(hGaussPymd2, Img);
        [ri, ci]= size(Img);
        r_mod = 2^nextpow2(rt + ri);
        c_mod = 2^nextpow2(ct + ci);
        target_image_p = [target_image_rot zeros(rt, c_mod-ct)];
        target_image_p = [target_image_p; zeros(r_mod-rt, c_mod)];
        
        target_fft = step(hFFT2D1, target_image_p);
        target_size = repmat(target_dim_nopyramid, [numberOfTargets, 1]);
        gain = 2^(level);
        Im_p = zeros(r_mod, c_mod, 'single'); % Used for zero padding
        C_ones = ones(rt, ct, 'single'); 
        
        hFindMax = vision.LocalMaximaFinder( ...
            'Threshold', single(-1), ...
            'MaximumNumLocalMaxima', numberOfTargets, ...
            'NeighborhoodSize', floor(size(target_image_gp)/2)*2 - 1);
        hPlot = videopatternplots('setup',numberOfTargets, threshold);
        
        Im = single(img);
        Im_gp = step(hGaussPymd3, Im);

        % Frequency domain convolution.
        Im_p(1:ri, 1:ci) = Im_gp;    % Zero-pad
        img_fft = step(hFFT2D2, Im_p);
        corr_freq = img_fft .* target_fft;
        corrOutput_f = step(hIFFFT2D, corr_freq);
        corrOutput_f = corrOutput_f(rt:ri, ct:ci);

        % Calculate image energies and block run tiles that are size of
        % target template.
        IUT_energy = (Im_gp).^2;
        IUT = step(hConv2D, IUT_energy, C_ones);
        IUT = sqrt(IUT);

        % Calculate normalized cross correlation.
        norm_Corr_f = (corrOutput_f) ./ (IUT * target_energy);
        xyLocation = step(hFindMax, norm_Corr_f);

        % Calculate linear indices.
        linear_index = sub2ind([ri-rt, ci-ct]+1, xyLocation(:,2),...
            xyLocation(:,1));

        norm_Corr_f_linear = norm_Corr_f(:);
        norm_Corr_value = norm_Corr_f_linear(linear_index);
        detect = (norm_Corr_value > threshold);
        target_roi = zeros(length(detect), 4);
        ul_corner = (gain.*(xyLocation(detect, :)-1))+1;
        target_roi(detect, :) = [ul_corner, fliplr(target_size(detect, :))];

        % Draw bounding box.   
        locat = cell(1, numberOfTargets);
        h = cell(1, numberOfTargets);
        api = cell(1, numberOfTargets);
        Imf = insertShape(Im, 'Rectangle', target_roi, 'Color', 'green');
        hf = figure('Color', get(0, 'defaultuicontrolbackgroundcolor'), ...
        'Name', 'Similar Objects', ...
        'NumberTitle', 'off');
        imshow(rgbImage);
        for j = 1:size(target_roi,1)
            h{j} = imrect(gca, target_roi(j,:)); 
            api{j} = iptgetapi(h{j});
            api{j}.addNewPositionCallback(@(p) title(mat2str(p,3)));  
            fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));  
            api{j}.setPositionConstraintFcn(fcn);  
        
            uicontrol(hf, 'style', 'pushbutton', 'Units', 'Pixels', ...
            'String', 'Confirm Positions', ...
            'Position', [340 10 100 20], ...
            'Callback', @submitFcn);
        end
        uiwait;
        close(hf);
        return;
        
        function submitFcn(varargin)
            for k = 1:length(h)
                locat{k} = api{k}.getPosition();
            end
            uiresume;
        end
end

