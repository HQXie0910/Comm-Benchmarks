
% The source coding is JPEG and JPEG
source_cod = 0; % 0 is JPEG, 1 is JPEG-2000
quality = 75; % the output quality of image for jepg, value range is 0~100
CompressionRatio = 2; % the compression ratio for JPEG-2000, the value is larger than 1


PathRoot = '/import/antennas/Datasets/hx301/CLEVR_v1/images/val'; % the source path
PathOut = '/import/antennas/Datasets/hx301/CLEVR_v1/JEPG-75';  % this is the compression output path

%% Source coding--JPEG or JPEG-2000
if exist(PathOut, 'dir')==0
    mkdir(PathOut);
end
list = dir(PathRoot); %the list of dataset
list_Out = dir(PathOut);
fileNums = size(list);
fileNums_Out = size(list_Out);
if fileNums(1)~=fileNums_Out(1)
    if source_cod==0
        % read the source
        for i = 3:fileNums
            path = [PathRoot '/' list(i).name];
            image = imread(path);
            imwrite(image, [PathOut '/' 'val_' num2str(i-2, '%06d') '.jpg'],...
            'jpg', 'Quality', quality); % compress data
        end
    elseif source_cod==1
        % read the source
        for i = 3:fileNums
            path = [PathRoot '/' list(i).name];
            image = imread(path);
            imwrite(image, [PathOut '/' 'val_' num2str(i-2, '%06d') '.jp2'],...
            'jp2', 'CompressionRatio', 2); % compress data
        end
    end
else 
    disp('Already have the compressed data');

    
