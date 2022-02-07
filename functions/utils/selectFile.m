function outputFiles = selectFile(inputfiles,filter,InputFileDelimit)

filter = convertCharsToStrings(filter);
% rfiles = getAllFiles('./results/',sprintf('*table.mat'),1);
% 
% selectList = ["voxel2","noise"]; targetVoxel = [1 5 1 0.5 4.93];
% 
% selectList = ["voxel1","noise"]; targetVoxel = [1 -5 1 0.5 4.93];


% fileName = getAllFiles('./Gray/MotionComp_RefScan1/010522/','*sFit.mat',2);
idx = [];
for ii= 1:length(inputfiles)
    s = strsplit(inputfiles{ii}, InputFileDelimit);

    if length(filter) == sum(contains(s,filter))
        idx(ii) = 1;
    else
        idx(ii) = 0;
    end
end

 outputFiles =  cell(size(find(idx')));
 [outputFiles{:}]=inputfiles{find(idx)};


end