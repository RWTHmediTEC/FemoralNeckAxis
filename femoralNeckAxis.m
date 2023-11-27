function [FNA, FNA_TFM] = femoralNeckAxis(femur, side, neckAxis, shaftAxis, varargin)
%FEMORALNECKAXIS optimizes the femoral neck axis (FNA)
%
% INPUT:
%   - REQUIRED:
%     femur - struct: A clean mesh of the femur defined by the fields
%       vertices (double [Nx3]) and faces (integer [Mx3])
%     side - Char: 'L' or 'R' femur
%     neckAxis - Double [1x6]: Initial femoral neck axis with the
%       approximate center of the neck isthmus as origin
%     shaftAxis - Double [1x6]: Initial femoral shaft axis with the
%       approximate middle of the shaft as origin
%
%   - ADDITIONAL:
%     'Subject' - Char: Identification of the subject. Default is 'anonymous'.
%     'PlaneVariationRange' - Integer [1x1]: Defines the size of the search
%                             field of the rough iterations. Default value
%                             is 4° resulting in a quadratic search field
%                             of -/+ 4°. Values between 1° and 16° are
%                             valid. 4° seems to be a proper value for the
%                             tested meshes. Higher values increase the
%                             number of plane variations and the running
%                             time. Lower values may miss the global
%                             disperion minimum.
%     'StepSize' - Integer [1x1]: Defines the step size during the rough
%                  iterations. Default value is 2°. Values between 1° and
%                  4° are valid. E.g. with a PlaneVariationRange of 4° it
%                  results in a search field of:
%                  ((4° x 2 / 2°) + 1)² = 25 plane variations
%     'Objective' - Char: The objective of the iteration process:
%                   'perimeter': Min. perimiter of the neck (default)
%                   'dispersion': Min. dispersion of centers of
%                                 ellipses fitted to countours of neck.
%     'NoOfCuttingPlanes' - Integer [1x1]: The number of cutting planes.
%                           Values between 2 and 30 are valid. 
%                           Default is 15.
%     'Visualization' - Logical: Figure output. Default is true.
%     'Verbose' - Logical: Command window output. Default is true.
%
% OUTPUT:
%     FNA - Double [1x6]: The optimized femoral neck axis.
%     FNA_TFM - Double [4x4]: Transformation of the bone into the neck axis CS
%
% EXAMPLE:
%     Run the file 'femoralNeckAxis_example.m' or 'femoralNeckAxis_GUI.m'.
%
% TODO/IDEAS:
%
% AUTHOR: Maximilian C. M. Fischer
% 	mediTEC - Chair of Medical Engineering, RWTH Aachen University
% VERSION: 2.0.0
% DATE: 2020-11-17
% COPYRIGHT (C) 2017 - 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

% Validate inputs
[GD.Subject.Side, GD.Subject.Name, ...
    GD.Algorithm.PlaneVariationRange, GD.Algorithm.StepSize, GD.Algorithm.Objective, GD.Algorithm.NoOfCuttingPlanes, ...
    GD.Visualization, GD.Verbose] = ...
    validateAndParseInputs(femur, side, neckAxis, shaftAxis, varargin{:});

% FNA path
GD.ToolPath = fileparts([mfilename('fullpath'), '.m']);

% Add path for external functions
addpath(genpath(fullfile(GD.ToolPath, 'src')));

% Compile mex file if not exist
mexPath = fullfile(GD.ToolPath, 'src', 'external', 'intersectPlaneSurf');
if ~exist(fullfile(mexPath, 'IntersectPlaneTriangle.mexw64'),'file') && ~isunix
    mex(fullfile(mexPath, 'IntersectPlaneTriangle.cpp'),'-v','-outdir', mexPath);
elseif ~exist(fullfile(mexPath, 'IntersectPlaneTriangle.mexa64'),'file') && isunix
    mex(fullfile(mexPath, 'IntersectPlaneTriangle.cpp'),'-v','-outdir', mexPath);
end

if GD.Visualization == 1
    %% Figure
    GD.Figure.Color = [1 1 1];
    MonitorsPos = get(0,'MonitorPositions');
    FH = figure(...
        'Units','pixels',...
        'NumberTitle','off',...
        'Color',GD.Figure.Color,...
        'ToolBar','figure',...
        'WindowScrollWheelFcn',@M_CB_Zoom,...
        'WindowButtonDownFcn',@M_CB_RotateWithMouse);
    if     size(MonitorsPos,1) == 1
        set(FH,'OuterPosition',MonitorsPos(1,:));
    elseif size(MonitorsPos,1) == 2
        set(FH,'OuterPosition',MonitorsPos(2,:));
    end
    FH.MenuBar = 'none';
    FH.ToolBar = 'none';
    FH.WindowState = 'maximized';
    GD.Figure.Handle = FH;
    set(0,'defaultAxesFontSize',14)
    
    % 3D view
    LP = uipanel('Title','3D view','FontSize',14,'BorderWidth',2,...
        'BackgroundColor',GD.Figure.Color,'Position',[0.01 0.01 0.49 0.99]);
    GD.Figure.D3Handle = axes('Parent', LP, 'Visible','off', 'Color',GD.Figure.Color);
    
    % 2D view
    RPT = uipanel('Title','2D view','FontSize',14,'BorderWidth',2,...
        'BackgroundColor',GD.Figure.Color,'Position',[0.51 0.51 0.48 0.49]);
    RH = axes('Parent', RPT, 'Visible','off', 'Color',GD.Figure.Color);
    axis(RH, 'on'); axis(RH, 'equal'); grid(RH, 'on'); xlabel(RH, 'X [mm]'); ylabel(RH, 'Y [mm]');
    GD.Figure.D2Handle = RH;
    
    % A convergence plot as a function of alpha (a) and beta (b).
    RPB = uipanel('Title','Convergence progress','FontSize',14,'BorderWidth',2,...
        'BackgroundColor',GD.Figure.Color,'Position',[0.51 0.01 0.48 0.49]);
    IH = axes('Parent', RPB, 'Visible','off', 'Color',GD.Figure.Color);
    axis(IH, 'equal', 'tight'); view(IH,3);
    xlabel(IH,'\alpha [°]');
    ylabel(IH,'\beta [°]');
    zlabel(IH, [GD.Algorithm.Objective ' [mm]'])
    switch GD.Algorithm.Objective
        case 'dispersion'
            title(IH, 'Dispersion of the ellipse centers as function of \alpha & \beta')
        case 'perimeter'
            title(IH, 'Min. perimeter of the contours as function of \alpha & \beta')
    end
    GD.Figure.DispersionHandle = IH;
end

%% Load Subject
GD.Subject.Mesh = femur;
GD.Subject.NeckAxis = normalizeLine3d(neckAxis);
GD.Subject.ShaftAxis = normalizeLine3d(shaftAxis);

GD = FNA_LoadSubject('no handle', GD);

% Visualization settings
if GD.Visualization == 1
    GD.Algorithm.PlotPlaneVariation = 1;
    GD.Algorithm.EllipsePlot = 1;
elseif GD.Visualization == 0
    GD.Algorithm.PlotPlaneVariation = 0;
    GD.Algorithm.EllipsePlot = 0;
end

% Start rough/fine iteration process
GD = FNA_RoughFineIteration('no handle', GD);

%% Results
FNA_TFM = GD.Subject.TFM;
FNA = GD.Results.FNA;

end


%==========================================================================
% Parameter validation
%==========================================================================
function [Side, Subject, ...
    PlaneVariationRange, StepSize, Objective, NoOfCuttingPlanes, ...
    Visualization, Verbose] = ...
    validateAndParseInputs(Femur, Side, NeckAxis, ShaftAxis, varargin)

Side = upper(Side(1)); % [L]eft or [R]ight

validateattributes(Femur.vertices, {'numeric'},{'ncols', 3});
validateattributes(Femur.faces, {'numeric'},{'integer','nonnegative','nonempty','ncols', 3});
validatestring(Side, {'R','L'});
validateattributes([NeckAxis; ShaftAxis],{'numeric'},{'nonempty','nonnan','real','finite','size',[nan,6]});

% Parse the input P-V pairs
defaults = struct(...
    'Subject', 'anonymous', ...
    'PlaneVariationRange', 4, ...
    'StepSize', 2, ...
    'Objective', 'perimeter',...
    'NoOfCuttingPlanes', 15, ...
    'Visualization', true, ...
    'Verbose', true);

parser = inputParser;
parser.CaseSensitive = false;

parser.addParameter('Subject', defaults.Subject, ...
    @(x)validateattributes(x,{'char'}, {}));
parser.addParameter('PlaneVariationRange', defaults.PlaneVariationRange, ...
    @(x)validateattributes(x,{'numeric'}, {'integer', 'nonempty', 'numel',1, '>=',1, '<=',16}));
parser.addParameter('StepSize', defaults.StepSize, ...
    @(x)validateattributes(x,{'numeric'}, {'integer', 'nonempty', 'numel',1, '>=',1, '<=',4}));
parser.addParameter('Objective', defaults.Objective, ...
    @(x)any(validatestring(x, {'perimeter','dispersion'})));
parser.addParameter('NoOfCuttingPlanes', defaults.NoOfCuttingPlanes, ...
    @(x)validateattributes(x,{'numeric'}, {'integer', 'nonempty', 'numel',1, '>=',2, '<=',30}));
parser.addParameter('Visualization', defaults.Visualization, ...
    @(x)validateattributes(x,{'logical'}, {'scalar','nonempty'}));
parser.addParameter('Verbose', defaults.Verbose, ...
    @(x)validateattributes(x,{'logical'}, {'scalar','nonempty'}));

parser.parse(varargin{:});

Subject             = parser.Results.Subject;
PlaneVariationRange = parser.Results.PlaneVariationRange;
StepSize            = parser.Results.StepSize;
Objective           = parser.Results.Objective;
NoOfCuttingPlanes   = parser.Results.NoOfCuttingPlanes;
Visualization       = parser.Results.Visualization;
Verbose             = parser.Results.Verbose;

end