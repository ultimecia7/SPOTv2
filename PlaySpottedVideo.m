function PlaySpottedVideo(movie_name, locations)
%PLAYSPOTTEDVIDEO Summary of this function goes here
%   Detailed explanation goes here

reader = vision.VideoFileReader(movie_name,...
    'VideoOutputDataType','uint8',...
    'ImageColorSpace','RGB');

player = vision.VideoPlayer;

frameNum = 1;

loc1 = load('result1.mat');
loc2 = load('result2.mat');
loc3 = load('result3.mat');
loc4 = load('result4.mat');

while ~isDone(reader)
      videoFrame = step(reader);
      step(player, videoFrame);
      videoFrame = insertShape(videoFrame, 'Rectangle', loc1.loc(frameNum,:), 'Color', 'green');
      videoFrame = insertShape(videoFrame, 'Rectangle', loc2.loc(frameNum,:), 'Color', 'green');
      videoFrame = insertShape(videoFrame, 'Rectangle', loc3.loc(frameNum,:), 'Color', 'green');
      videoFrame = insertShape(videoFrame, 'Rectangle', loc4.loc(frameNum,:), 'Color', 'green');
      frameNum = frameNum +1;
      imshow(videoFrame);
end

release(player);
release(videoFReader);
    
end

