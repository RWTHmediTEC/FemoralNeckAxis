function [ANA, ANATFM] = ANA(vertices, faces, side, neckAxisIdx, ...
    shaftAxisIdx, neckOrthogonalIdx, varargin)
%ANA An optimization algorithm for establishing an anatomical neck axis (ANA)
%
% INPUT:
%   - REQUIRED:
%     vertices - Double [Nx3]: A list of points of the femoral neck mesh
%     faces - Integer [Mx3]: A list of triangle faces, indexing into the vertices
%     side - Char: 'L' or 'R' femur
%     neckAxisIdx - Integer [Mx2]: Vertex indices defining a default 
%       initial neck axis
%     shaftAxisIdx - Integer [Mx2]: Vertex indices defining a default 
%       initial shaft axis
%     neckOrthogonalIdx - Integer [Mx2]: Vertex indices defining a default 
%       initial ortogonal to the neck axis in smallest the region of the neck
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
%                         'perimeter': min. perimiter of the neck (default)
%                         'dispersion': min. dispersion of centers of 
%                                     ellipses fitted to countours of neck.
%     'Visualization' - Logical: Figure output. Default is true.
%     'Verbose' - Logical: Command window output. Default is true.
%
% OUTPUT:
%     ANA - Double [1x6]: A line fitted through the centers of the ellipses
%           with minimum dispersion.
%     ANATFM - Double [4x4]: Transformation of the bone into the neck axis CS
%
% EXAMPLE:
%     Run the file 'ANA_Example.m' or 'ANA_GUI.m'.
%
% TODO/IDEAS:
%   - Parse variable NoCP
%   - Add dropdown for GD.ANA_Algorithm.Objective to ANA_GUI.m
%
% AUTHOR: Maximilian C. M. Fischer
% 	mediTEC - Chair of Medical Engineering, RWTH Aachen University
% VERSION: 1.0.0
% DATE: 2018-05-25
% LICENSE: Modified BSD License (BSD license with non-military-use clause)

% Validate inputs
[Subject, PlaneVariationRange, StepSize, GD.ANA_Algorithm.Objective, GD.Visualization, GD.Verbose] = ...
    validateAndParseOptInputs(vertices, faces, side, varargin{:});

% USP path
GD.ToolPath = [fileparts([mfilename('fullpath'), '.m']) '\'];

% Add path for external functions
addpath(genpath([GD.ToolPath 'src']));

% Compile mex file if not exist
mexPath = [GD.ToolPath 'src\external\intersectPlaneSurf'];
if ~exist([mexPath '\IntersectPlaneTriangle.mexw64'],'file')
    mex([mexPath '\IntersectPlaneTriangle.cpp'],'-v','-outdir', mexPath);
end

% Number of cutting planes per cuting box
GD.Cond.NoPpC = 15;

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
        'WindowButtonDownFcn',@M_CB_RotateWithMouse,...
        'renderer','opengl');
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
    
    %% 3D view
    LeftP = uipanel('Title','3D view','FontSize',14,'BorderWidth',2,...
        'BackgroundColor',GD.Figure.Color,'Position',[0.01 0.01 0.49 0.99]);
    GD.Figure.LeftSpHandle = axes('Parent', LeftP, 'Visible','off', 'Color',GD.Figure.Color);
    
    %% 2D view
    RPT = uipanel('Title','2D view','FontSize',14,'BorderWidth',2,...
        'BackgroundColor',GD.Figure.Color,'Position',[0.51 0.51 0.48 0.49]);
    RH = axes('Parent', RPT, 'Visible','off', 'Color',GD.Figure.Color);
    axis(RH, 'on'); axis(RH, 'equal'); grid(RH, 'on'); xlabel(RH, 'X [mm]'); ylabel(RH, 'Y [mm]');
    GD.Figure.RightSpHandle = RH;
    
    %% Convergence plot
    % A convergence plot as a function of alpha (a) and beta (b).
        RPB = uipanel('Title','Convergence progress','FontSize',14,'BorderWidth',2,...
        'BackgroundColor',GD.Figure.Color,'Position',[0.51 0.01 0.48 0.49]);
        IH = axes('Parent', RPB, 'Visible','off', 'Color',GD.Figure.Color);
        axis(IH, 'equal', 'tight'); view(IH,3);
        xlabel(IH,'\alpha [°]');
        ylabel(IH,'\beta [°]');
        zlabel(IH, [GD.ANA_Algorithm.Objective ' [mm]'])
        switch GD.ANA_Algorithm.Objective
            case 'dispersion'
                title(IH, 'Dispersion of the ellipse centers as function of \alpha & \beta')
            case 'perimeter'
                title(IH, 'Min. perimeter of the contours as function of \alpha & \beta')
        end
        GD.Results.AxHandle = IH;
end

%% Load Subject
GD.Subject.Mesh.vertices = vertices;
GD.Subject.Mesh.faces = faces;
GD.Subject.Side = side; % [L]eft or [R]ight
GD.Subject.Name = Subject; % Subject name
GD.Subject.NeckAxisIdx = neckAxisIdx;
GD.Subject.ShaftAxisIdx = shaftAxisIdx;
GD.Subject.NeckOrthogonalIdx = neckOrthogonalIdx;

GD = ANA_LoadSubject('no handle', GD);

%% Settings for the framework
% Iteration settings
GD.ANA_Algorithm.PlaneVariationRange = PlaneVariationRange;
GD.ANA_Algorithm.StepSize = StepSize;

% Visualization settings
if GD.Visualization == 1
    GD.ANA_Algorithm.PlaneVariaton = 1;
    GD.ANA_Algorithm.EllipsePlot = 1;
elseif GD.Visualization == 0
    GD.ANA_Algorithm.PlaneVariaton = 0;
    GD.ANA_Algorithm.EllipsePlot = 0;
end

% Start rough/fine iteration process
GD = ANA_RoughFineIteration('no handle', GD);

%% Results
ANATFM = GD.Subject.TFM;
ANA = GD.Results.ANA;

end


%==========================================================================
% Parameter validation
%==========================================================================
function [Subject, PlaneVariationRange, StepSize, Objective, Visualization, Verbose] = ...
    validateAndParseOptInputs(vertices, faces, side, varargin)

validateattributes(vertices, {'numeric'},{'ncols', 3});
validateattributes(faces, {'numeric'},{'integer','nonnegative','nonempty','ncols', 3});
validatestring(side, {'R','L'});
% validateattributes(InitialRot, {'numeric'},{'>=', -180, '<=', 180,'size', [1 3]});

% Parse the input P-V pairs
defaults = struct(...
    'Subject', 'anonymous', ...
    'PlaneVariationRange', 4, ...
    'StepSize', 2, ...
    'Objective', 'perimeter',...
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
parser.addParameter('Visualization', defaults.Visualization, ...
    @(x)validateattributes(x,{'logical'}, {'scalar','nonempty'}));
parser.addParameter('Verbose', defaults.Verbose, ...
    @(x)validateattributes(x,{'logical'}, {'scalar','nonempty'}));

parser.parse(varargin{:});

Subject             = parser.Results.Subject;
PlaneVariationRange = parser.Results.PlaneVariationRange;
StepSize            = parser.Results.StepSize;
Objective           = parser.Results.Objective;
Visualization       = parser.Results.Visualization;
Verbose             = parser.Results.Verbose;

end