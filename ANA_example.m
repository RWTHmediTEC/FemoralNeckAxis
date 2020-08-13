clearvars; close all; opengl hardware

%% Select subject
Idx = 1;

load('data\F','F')

Subject=F(Idx);

% Read subject surface data and store
femur = F(Idx).mesh;
Side = F(Idx).side;

% Create the neck axis from the vertex indices
NeckAxis=createLine3d(...
    femur.vertices(F(Idx).LM.NeckAxis(1),:),...
    femur.vertices(F(Idx).LM.NeckAxis(2),:));
% Create the shaft axis from the vertex indices
ShaftAxis=createLine3d(...
    femur.vertices(F(Idx).LM.ShaftAxis(1),:),...
    femur.vertices(F(Idx).LM.ShaftAxis(2),:));
% Create the neck orthogonal from the vertex indices
NeckOrthogonal=createLine3d(...
    femur.vertices(F(Idx).LM.NeckOrthogonal(1),:),...
    femur.vertices(F(Idx).LM.NeckOrthogonal(2),:));
% Neck axis starts at the intersection of neck axis and neck orthogonal
[~, NeckAxis(1:3), ~] = distanceLines3d(NeckAxis, NeckOrthogonal);

%% Select different options by commenting 
% Default mode
[ANAxis, ANATFM] = ANA(femur.vertices, femur.faces, Side, NeckAxis, ShaftAxis, ...
    'Subject', num2str(Idx));
% Silent mode
% [ANAxis, ANATFM] = ANA(femur.vertices, femur.faces, Side, NeckAxis, ShaftAxis, ...
%     'Subject', num2str(Idx), 'Visu', false, 'Verbose', false);
% Other options
% [ANAxis, ANATFM] = ANA(femur.vertices, femur.faces, Side, NeckAxis, ShaftAxis, ...
%     'Subject', num2str(Idx), 'Objective', 'dispersion');
% [ANAxis, ANATFM] = ANA(femur.vertices, femur.faces, Side, NeckAxis, ShaftAxis, ...
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

% ANAxis
drawLine3d(ANAxis, 'b');

% Light
light1 = light; light('Position', -1*(get(light1,'Position')));


% [List.f, List.p] = matlab.codetools.requiredFilesAndProducts([mfilename '.m']);
% List.f = List.f'; List.p = List.p';