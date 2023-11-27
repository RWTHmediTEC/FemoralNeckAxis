%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

clearvars; close all

% Add src path
addpath(genpath([fileparts([mfilename('fullpath'), '.m']) '\src']));

%% Clone example data
if ~exist('VSD', 'dir')
    try
        !git clone https://github.com/RWTHmediTEC/VSDFullBodyBoneModels VSD
        rmdir('VSD/.git', 's')
    catch
        warning([newline 'Clone (or copy) the example data from: ' ...
            'https://github.com/RWTHmediTEC/VSDFullBodyBoneModels' newline 'to: ' ...
            fileparts([mfilename('fullpath'), '.m']) '\VSD' ...
            ' and try again!' newline])
        return
    end
end

% Select subjects of the VSD
subjectXLSX = 'VSD\MATLAB\res\VSD_Subjects.xlsx';
Subjects = readtable(subjectXLSX);
Subjects{2:2:height(Subjects),7} = 'R';
Subjects{1:2:height(Subjects),7} = 'L'; 

for s=1:size(Subjects, 1)
    name = Subjects{s,1}{1};
    side = Subjects{s,7};
    
    % Prepare distal femur
    load(['VSD\Bones\' name '.mat'], 'B');
    load(['data\' name '.mat'],'NeckAxis','ShaftAxis');
    femur = B(ismember({B.name}, ['Femur_' side])).mesh;
    
    %% Select different options by commenting
    % Default mode
    [FNA, FNA_TFM] = femoralNeckAxis(femur, side, NeckAxis, ShaftAxis, 'Subject',name);
    % Silent mode
    % [FNA, FNA_TFM] = femoralNeckAxis(femur, side, NeckAxis, ShaftAxis, 'Subject',name,...
    %    'Visu', false, 'Verbose', false);
    % Other options
    % [FNA, FNA_TFM] = femoralNeckAxis(femur, side, NeckAxis, ShaftAxis, 'Subject',name,...
    %    'Objective', 'dispersion');
    % [FNA, FNA_TFM] = femoralNeckAxis(femur, side, NeckAxis, ShaftAxis, 'Subject',name,...
    %    'PlaneVariationRange', 12, 'StepSize', 3);
    
end

% [List.f, List.p] = matlab.codetools.requiredFilesAndProducts([mfilename '.m']);
% List.f = List.f'; List.p = List.p';