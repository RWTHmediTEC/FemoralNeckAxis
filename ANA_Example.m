clearvars; close all; opengl hardware
% [List.f, List.p] = matlab.codetools.requiredFilesAndProducts('ANA_GUI.m');
% List.f = List.f'; List.p = List.p';

%% Select subject
Idx = 4;

load('data\F','F')

Subject=F(Idx);

% Read subject surface data and store
Vertices = F(Idx).mesh.vertices;
Faces = F(Idx).mesh.faces;
Side = F(Idx).side;

% Axis indices
NeckAxisIdx = F(Idx).LM.NeckAxis;
ShaftAxisIdx = F(Idx).LM.ShaftAxis;
NeckOrthogonalIdx = F(Idx).LM.NeckOrthogonal;

%% Select different options by commenting 
% Default mode
[CEA, ANATFM] = ANA(Vertices, Faces, Side, NeckAxisIdx, ShaftAxisIdx, NeckOrthogonalIdx, 'Subject', num2str(Idx));
% Silent mode
% [CEA, ANATFM] = ANA(Vertices, Faces, Side, NeckAxisIdx, ShaftAxisIdx, ...
%     NeckOrthogonalIdx, 'Subject', num2str(Idx), 'Visualization', false, 'Verbose', false);
% Other options
% [CEA, ANATFM] = ANA(Vertices, Faces, Side, NeckAxisIdx, ShaftAxisIdx, NeckOrthogonalIdx, ...
%     'PlaneVariationRange', 12, 'StepSize', 3);

%% Visualization
figure('Units','pixels','Color','w','ToolBar','figure',...
'WindowScrollWheelFcn',@M_CB_Zoom,'WindowButtonDownFcn',@M_CB_RotateWithLeftMouse,...
    'renderer','opengl');
axes('Color','w'); axis on; xlabel('X [mm]'); ylabel('Y [mm]'); zlabel('Z [mm]');
daspect([1 1 1])
cameratoolbar('SetCoordSys','none')

% Bone
BoneProps.EdgeColor = 'none';
BoneProps.FaceColor = [0.882, 0.831, 0.753];
BoneProps.FaceAlpha = 0.7;
BoneProps.EdgeLighting = 'none';
BoneProps.FaceLighting = 'gouraud';
patch(F(Idx).mesh, BoneProps);

% CEA
CEA_TFM = transformLine3d(CEA, inv(ANATFM));
drawLine3d(CEA_TFM, 'b');

% Light
light1 = light; light('Position', -1*(get(light1,'Position')));