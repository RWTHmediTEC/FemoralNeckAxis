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
%     'Subject' - Char: Identification of the subject. Default is 'unnamed'.
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
    GUIFigure = figure(...
        'Units','pixels',...
        'NumberTitle','off',...
        'Color',GD.Figure.Color,...
        'ToolBar','figure',...
        'WindowScrollWheelFcn',@M_CB_Zoom,...
        'WindowButtonDownFcn',@M_CB_RotateWithMouse,...
        'renderer','opengl');
    if     size(MonitorsPos,1) == 1
        set(GUIFigure,'OuterPosition',MonitorsPos(1,:));
    elseif size(MonitorsPos,1) == 2
        set(GUIFigure,'OuterPosition',MonitorsPos(2,:));
    end
    GD.Figure.Handle = GUIFigure;
    
    %% Subject subplot
    GD.Figure.LeftSpHandle = subplot('Position', [0.05, 0.1, 0.4, 0.8],...
        'Visible', 'off','Color',GD.Figure.Color);
    
    %% Calculation subplot
    GD.Figure.RightSpHandle = subplot('Position', [0.55, 0.1, 0.4, 0.8],'Color',GD.Figure.Color);
    axis on; axis equal; grid on; xlabel('X [mm]'); ylabel('Y [mm]');
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
    'Subject', 'unnamed', ...
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

