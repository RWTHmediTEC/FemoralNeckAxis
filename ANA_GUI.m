clearvars; close all; clc; opengl hardware;
% [List.f, List.p] = matlab.codetools.requiredFilesAndProducts('ANA_GUI.m');
% List.f = List.f'; List.p = List.p';

addpath(genpath('..\..\..\General\Code\#external\matGeom'))

% Current Path
CTP = pwd; 

% USP path
GD.ToolPath = [fileparts([mfilename('fullpath'), '.m']) '\'];

% Add path
addpath(genpath([GD.ToolPath 'src']));

% Compile mex file if not exist
cd([GD.ToolPath 'src\external\intersectPlaneSurf'])
if ~exist('IntersectPlaneTriangle.mexw64','file')
    mex('IntersectPlaneTriangle.cpp','-v');
end
cd(CTP);

% Number of cutting planes 
GD.Cond.NoPpC = 9;

%% Figure
GD.Verbose = true;
GD.Visualization = true;
GD.Figure.Color = [1 1 1];
MonitorsPos = get(0,'MonitorPositions');
GUIFigure = figure('Units','pixels',...
    'Color',GD.Figure.Color,'ToolBar','figure',...
    'WindowScrollWheelFcn',@M_CB_Zoom,'WindowButtonDownFcn',@M_CB_RotateWithLeftMouse,...
    'renderer','opengl');
if     size(MonitorsPos,1) == 1
    set(GUIFigure,'OuterPosition',MonitorsPos(1,:));
elseif size(MonitorsPos,1) == 2
    set(GUIFigure,'OuterPosition',MonitorsPos(2,:));
end
GD.Figure.Handle = GUIFigure;
view(3)

%% Subject subplot
GD.Figure.LeftSpHandle = subplot('Position', [0.05, 0.1, 0.4, 0.8],...
    'Visible', 'off','Color',GD.Figure.Color);

%% Get Subjects
GD.Subject.DataPath = '\data\F.mat';
load([GD.ToolPath GD.Subject.DataPath])
Subjects = cellfun(@num2str, num2cell(1:length(F))', 'uni', 0);

%% Calculation subplot
GD.Figure.RightSpHandle = subplot('Position', [0.55, 0.1, 0.4, 0.8],'Color',GD.Figure.Color);
axis on; axis equal; grid on; xlabel('X [mm]'); ylabel('Y [mm]');

%% GUI
% uicontrol Size
BSX = 0.12; BSY = 0.023;

%Font properies
FontPropsA.FontUnits = 'normalized';
FontPropsA.FontSize = 0.8;

FontPropsB.FontUnits = 'normalized';
FontPropsB.FontSize = 0.5;

%% Controls on the Top of the GUI - LEFT SIDE
% Entries of the dropdown menue as string
GD.Subject.Name = Subjects{1};
% Subject static text
uicontrol('Style','text','String','Subject: ','HorizontalAlignment','Right',...
    'Units','normalized','Position',      [0.13-BSX 0.97 BSX/2 BSY],FontPropsA)
% Subject dropdown menue
uicontrol('Style', 'popup', 'String',Subjects',...
    'Units','normalized','Position',      [0.13-BSX*1/2 0.97 BSX BSY],FontPropsB,...
    'Callback', {@DD_CB_Subject, Subjects});
% Load button
uicontrol('Units','normalized','Position',[0.13+BSX*1/2 0.97 BSX BSY],FontPropsA,...
    'String','Load','Callback',{@LoadSubject});
% Start button
uicontrol('Units','normalized','Position',[0.13+BSX*3/2 0.97 BSX BSY],FontPropsA,...
        'String','Start Calculation','Callback',@RoughFineIteration);

%% Controls on the Top of the GUI - RIGHT SIDE
GD.Algorithm3.EllipsePlot = 0;
uicontrol('Style','checkbox','Units','normalized',...
    'Position',[0.75-BSX*3/2 0.97 BSX BSY],FontPropsB,...
    'String','Alg. 3: Plot Ellipses & Foci',...
    'Callback',@CB_CB_EllipsePlot,'Value',0);
GD.Algorithm3.PlaneVariaton = 0;
uicontrol('Style','checkbox','Units','normalized',...
    'Position',[0.75-BSX*1/2 0.97 BSX BSY],FontPropsB,...
    'String','Alg. 3: Plot Plane Variation',...
    'Callback', @CB_CB_PlaneVariation);
GD.Algorithm3.PlaneVariationRange = 4;
uicontrol('Style','text','Units','normalized',...
    'Position',[0.75+BSX*1/2 0.97 BSX-(1/3*BSX) BSY],FontPropsB,...
    'String','-/+ Plane Variaton in [°]: ','HorizontalAlignment','Right')
uicontrol('Style', 'popup','Units','normalized',...
    'Position',[0.75+BSX*1/2+(2/3*BSX) 0.97 BSX-(2/3*BSX) BSY],FontPropsB,...
    'String',cellfun(@num2str,num2cell(1:16),'UniformOutput',false),...
    'Callback',@DD_CB_PlaneVariationRange,'Value',4);
uicontrol('Style','text','Units','normalized',...
    'Position',[0.75+BSX*1/2 0.97-BSY BSX-(1/3*BSX) BSY],FontPropsB,...
    'String','Step size [°]: ','HorizontalAlignment','Right')
GD.Algorithm3.StepSize = 2;
uicontrol('Style', 'popup','Units','normalized',...
    'Position',[0.75+BSX*1/2+(2/3*BSX) 0.97-BSY BSX-(2/3*BSX) BSY],FontPropsB,...
    'String',cellfun(@num2str,num2cell(1:4),'UniformOutput',false),...
    'Callback',@DD_CB_StepSize,'Value',2);

%% Controls on the Bottom of the GUI - LEFT SIDE
% Fine-tuning Rotate-buttons
uicontrol('Units','normalized','Position',[0.25-BSX*3/2 0.01+BSY/2 BSX BSY/2],FontPropsA,...
    'String','Rotate bone around pos. X-Axis','Callback',{@B_CB_RotateBone, [1, 0, 0], 2});
uicontrol('Units','normalized','Position',[0.25-BSX*3/2 0.01 BSX BSY/2],FontPropsA,...
    'String','Rotate bone around neg. X-Axis','Callback',{@B_CB_RotateBone, [1, 0, 0], -2});
uicontrol('Units','normalized','Position',[0.25-BSX*1/2 0.01+BSY/2 BSX BSY/2],FontPropsA,...
    'String','Rotate bone around pos. Y-Axis','Callback',{@B_CB_RotateBone, [0, 1, 0], 2});
uicontrol('Units','normalized','Position',[0.25-BSX*1/2 0.01 BSX BSY/2],FontPropsA,...
    'String','Rotate bone around neg. Y-Axis','Callback',{@B_CB_RotateBone, [0, 1, 0], -2});
uicontrol('Units','normalized','Position',[0.25+BSX*1/2 0.01+BSY/2 BSX BSY/2],FontPropsA,...
    'String','Rotate bone around pos. Z-Axis','Callback',{@B_CB_RotateBone, [0, 0, 1], 2});
uicontrol('Units','normalized','Position',[0.25+BSX*1/2 0.01 BSX BSY/2],FontPropsA,...
    'String','Rotate bone around neg. Z-Axis','Callback',{@B_CB_RotateBone, [0, 0, 1], -2});

%% Controls on the Bottom of the GUI - RIGHT SIDE
% Save button
GD.Results.B_H_SaveResults = ...
uicontrol('Units','normalized','Position',[0.75-BSX*1/2 0.01 BSX BSY],FontPropsA,...
    'String','Save Results','Enable','off','Callback',@B_CB_SaveResults);

%% Guidata to share data among callbacks
guidata(GUIFigure, GD);
