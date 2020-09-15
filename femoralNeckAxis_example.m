clearvars; close all; opengl hardware

%% Select subject
Idx = 5;

load('data\F','F')

Subject=F(Idx);

% Read subject surface data and store
femur = F(Idx).mesh;
Side = F(Idx).side;

% Create the neck axis from the vertex indices
NeckAxis = F(Idx).LM.NeckAxis;
% Create the shaft axis from the vertex indices
ShaftAxis = F(Idx).LM.ShaftAxis;

%% Select different options by commenting 
% Default mode
[FNAxis, FNA_TFM] = femoralNeckAxis(femur, Side, NeckAxis, ShaftAxis, ...
    'Subject', num2str(Idx));
% Silent mode
% [FNAxis, FNA_TFM] = femoralNeckAxis(femur, Side, NeckAxis, ShaftAxis, ...
%     'Subject', num2str(Idx), 'Visu', false, 'Verbose', false);
% Other options
% [FNAxis, FNA_TFM] = femoralNeckAxis(femur, Side, NeckAxis, ShaftAxis, ...
%     'Subject', num2str(Idx), 'Objective', 'dispersion');
% [FNAxis, FNA_TFM] = femoralNeckAxis(femur, Side, NeckAxis, ShaftAxis, ...
%     'PlaneVariationRange', 12, 'StepSize', 3);

%% Visualization
figure('Units','pixels','Color','w','ToolBar','figure','Position',[680 50 560 420],...
'WindowScrollWheelFcn',@M_CB_Zoom,'WindowButtonDownFcn',@M_CB_RotateWithMouse,...
    'renderer','opengl');
axes('Color','w'); axis on equal;
xlabel('X [mm]'); ylabel('Y [mm]'); zlabel('Z [mm]');
cameratoolbar('SetCoordSys','none')

% Bone
BoneProps.EdgeColor = 'none';
BoneProps.FaceColor = [0.882, 0.831, 0.753];
BoneProps.FaceAlpha = 0.7;
BoneProps.EdgeLighting = 'none';
BoneProps.FaceLighting = 'gouraud';
patch(F(Idx).mesh, BoneProps);

% FNAxis
drawLine3d(FNAxis, 'b');

% Light
light1 = light; light('Position', -1*(get(light1,'Position')));


% [List.f, List.p] = matlab.codetools.requiredFilesAndProducts([mfilename '.m']);
% List.f = List.f'; List.p = List.p';