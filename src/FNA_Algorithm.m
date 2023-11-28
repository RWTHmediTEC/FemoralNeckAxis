function GD = FNA_Algorithm(GD)
%FNA_ALGORITHM
%    - An optimization algorithm for establishing a femoral neck axis (FNA)
%
%   INPUT
%       GD - A struct containing several fields:
%         SUBJECT DATA
%           GD.Subject.Mesh: The mesh of the proximal femur
%           GD.Subject.TFM
%         ALGORITHM SETTINGS
%           GD.Algorithm.PlaneVariationRange
%           GD.Algorithm.StepSize
%           GD.Algorithm.NoCuttingPlanes
%           GD.Algorithm.Objective
%         VISUALIZATION SETTINGS
%           GD.Visualization
%           GD.Figure.D2Handle
%           GD.Figure.D3Handle
%           GD.Figure.DispersionHandle
%           GD.Algorithm.PlotPlaneVariation
%           GD.Algorithm.EllipsePlot
%           GD.Verbose
%
%   OUTPUT
%         RESULTS
%           GD.Results.PlaneRotMat
%           GD.Results.CenterLine & GD.Results.CenterLineIdx
%         ITERATION
%           GD.Iteration.Rough
%           GD.Iteration.OldMin
%
%   REFERENCE
%       Inspired by: 2010 - Li et al. - Automating Analyses of the Distal 
%       Femur Articular Geometry Basedon Three-Dimensional Surface Data
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2017-2023 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
% 

visu = GD.Visualization;
if visu
    % Figure & subplot handles
    H3D = GD.Figure.D3Handle;
    H2D = GD.Figure.D2Handle;
    % Clear subplots
    % Right
    title(H2D,''); cla(H2D)
    % Left
    title(H3D,''); ClearPlot(H3D, {'Patch','Scatter','Line'})
end

%% Settings
% The angles are varied in StepSize� increments within following range:
PVR = GD.Algorithm.PlaneVariationRange;
StepSize = GD.Algorithm.StepSize;

% Ranges
Range_a = -PVR:StepSize:PVR;
Range_b = -PVR:StepSize:PVR;

% Plot Plane Variation
PlotPlaneVariation = GD.Algorithm.PlotPlaneVariation;

% Plot Ellipses & Foci for each plane variation into the GUI figure
EllipsePlot = GD.Algorithm.EllipsePlot;

% Objective of the iteration process
Objective = GD.Algorithm.Objective;

% Verbositiy
verbose = GD.Verbose;

%% START OF THE FRAMEWORK -------------------------------------------------
% An optimization algorithm for establishing a femoral neck axis (FNA)

% Bone Surface
Bone = transformPoint3d(GD.Subject.Mesh, GD.Subject.TFM);

% Number of Cutting Planes
NoCP = GD.Algorithm.NoOfCuttingPlanes;

% Neck Cuts (NC)
% NC = [];

% Plane variation loop counter
PV_Counter = 0;

RangeLength_a = length(Range_a);
RangeLength_b = length(Range_b);

% Variable to save the results
R.dispersion = nan(RangeLength_a,RangeLength_b);
R.perimeter  = nan(RangeLength_a,RangeLength_b);

% Cell array to save the results of each plane variation
CutVariations = cell(RangeLength_a,RangeLength_b);

if verbose
    % Start updated command window information
    dispstat('','init');
    dispstat('Initializing the iteration process...','keepthis','timestamp');
end

for I_a = 1:RangeLength_a
    for I_b = 1:RangeLength_b
        
        % Systematic Variation of Cutting Plane Orientation
        
        % (Abdu.) (Addu.)                       |
        % Lateral  Medial Rotation   Angle      | Intern  Extern Rotation    Angle
        %     +       -    X-Axis  Range_a(I_a) |  -        +     Y-Axis  Range_b(I_b)
        
        % Calculate the Rotation Matrix for the plane variation
        % (All rotations around the fixed axes / around the global basis)
        %                               (  Z-Axis      Y-Axis        X-Axis   )
        NC.PRM = eulerAnglesToRotation3d(    0    , Range_b(I_b), Range_a(I_a));
        invPRM=NC.PRM'; % in this case TFM' == inv(TFM)
        PlaneNormal = transformVector3d([0 0 1], NC.PRM);
        
        % Create cutting plane origins
        NC.Origin = [0 0 0];
        for p=1:NoCP
            % Distance between the plane origins has to be 1 mm in the 
            % direction of the plane normal, e.g. for NoPpC = 9:
            % -4, -3, -2, -1, 0, +1, +2, +3, +4
            NC.PlaneOrigins(p,:) = NC.Origin+(-(0.5+NoCP/2)+p)*PlaneNormal;
        end
        
        % Create NoP Neck Contour Profiles (NC.P)
        tempContour = IntersectMeshPlaneParfor(Bone, NC.PlaneOrigins, PlaneNormal);
        for c=1:NoCP
            % If there is more than one closed contour after the cut, use the longest one
            [~, IobC] = max(cellfun(@(x) sum(sqrt(sum(diff(x').^2,2))), tempContour{c}));
            NC.P(c).xyz = tempContour{c}{IobC}';
            % Close contour: Copy start value to the end, if needed
            if ~isequal(NC.P(c).xyz(1,:),NC.P(c).xyz(end,:))
                NC.P(c).xyz(end+1,:) = NC.P(c).xyz(1,:);
            end
            % Rotation back, parallel to XY-Plane (Default Neck Plane)
            NC.P(c).xyz = transformPoint3d(NC.P(c).xyz, invPRM);
            % If the contour is sorted clockwise
            if varea(NC.P(c).xyz(:,1:2)') < 0 % The contour has to be closed
                % Sort the contour counter-clockwise
                NC.P(c).xyz = flipud(NC.P(c).xyz);
                NC.P(c).xyz(end,:) = [];
                NC.P(c).xyz = circshift(NC.P(c).xyz, [-1,0]);
            else
                NC.P(c).xyz(end,:) = [];
            end
            [~, IYMax] = max(NC.P(c).xyz(:,2));
            % Set the start of the contour to the maximum Y value
            if IYMax ~= 1
                NC.P(c).xyz = NC.P(c).xyz([IYMax:size(NC.P(c).xyz,1),1:IYMax-1],:);
            end
            % Close contour: Copy start value to the end, if needed
            if ~isequal(NC.P(c).xyz(1,:),NC.P(c).xyz(end,:))
                NC.P(c).xyz(end+1,:) = NC.P(c).xyz(1,:);
            end
            % Calculate length of the contour
            NC.P(c).length=polygonLength(NC.P(c).xyz(:,1:2));
        end
        
        switch Objective
            case 'perimeter'
                % Calculate the minimum perimeter of the cuts
                R.perimeter(I_a,I_b) = min([NC.P.length]);
                if visu
                    %% Visualization during iteration
                    % RIGHT subplot: Plot the ellipses in 2D in the XY-plane
                    if EllipsePlot
                        % Clear right subplot
                        cla(H2D);
                        hold(H2D,'on')
                        % Plot contours in 2D
                        C2D_Handle=arrayfun(@(x) plot(H2D, x.xyz(:,1),x.xyz(:,2),'k'), NC.P,'uni',0);
                        [~, minPlaneIdx] = min([NC.P.length]);
                        % Set color of min. perimeter to red
                        C2D_Handle{minPlaneIdx}.Color='r';
                        C2D_Handle{minPlaneIdx}.LineWidth=2;
                        hold(H2D,'off')
                    end
                    
                    % LEFT Subplot: Plot plane variation, contour-parts, ellipses in 3D
                    ClearPlot(H3D, {'Patch','Scatter','Line'})
                    % Plot the plane variation
                    if PlotPlaneVariation
                        title(H3D, ['\alpha = ' num2str(Range_a(I_a)) '� & ' ...
                            '\beta = '  num2str(Range_b(I_b)) '�.'])
                        drawPlatform(H3D, createPlane([0, 0, 0], PlaneNormal),100,...
                            'FaceColor','g','FaceAlpha', 0.5);
                    end
                    % Plot contour-parts & ellipses
                    if EllipsePlot
                        C3D = arrayfun(@(x) transformPoint3d(x.xyz, NC.PRM), NC.P,'uni',0);
                        C3D_Handle = cellfun(@(x) plot3(H3D, x(:,1),x(:,2),x(:,3),'k'), C3D,'uni',0);
                        % Set color of min. perimeter to red
                        C3D_Handle{minPlaneIdx}.Color='r';
                        C3D_Handle{minPlaneIdx}.LineWidth=2;
                    end
                    drawnow
                end
            case 'dispersion'
                %% Algorithm 2
                % A least-squares fitting algorithm for extracting geometric measures
                Contours=cell(NoCP,1);
                for c=1:NoCP
                    % Part of the contour, that is used for fitting
                    Contours{c} = NC.P(c).xyz(:,1:2)';
                end
                % Parametric least-squares fitting and analysis of cross-sectional profiles
                tempEll2D = FitEllipseParfor(Contours, verbose);
                for c=1:NoCP
                    NC.P(c).Ell.z = tempEll2D(1:2,c)';
                    NC.P(c).Ell.a = tempEll2D(3,c);
                    NC.P(c).Ell.b = tempEll2D(4,c);
                    NC.P(c).Ell.g = tempEll2D(5,c);
                end
                
                % Calculate the ellipse foci (Foci2D) and the major (A) & minor (B) axis points (AB)
                Center2D = nan(NoCP,2);
                for c=1:NoCP
                    [Foci2D, NC.P(c).Ell.AB] = CalculateEllipseFoci2D(...
                        NC.P(c).Ell.z', NC.P(c).Ell.a, NC.P(c).Ell.b, NC.P(c).Ell.g);
                    % Posterior Focus (pf): Foci2D(1,:), Anterior Focus (af): Foci2D(2,:)
                    NC.P(c).Ell.pf = Foci2D(1,:);
                    Center2D(c,:) = NC.P(c).Ell.z;
                end
                % Calculate the dispersion as Eccentricity Measure
                R.dispersion(I_a,I_b) = CalculateDispersion(Center2D);
                
                if visu
                    %% Visualization during iteration
                    % RIGHT subplot: Plot the ellipses in 2D in the XY-plane
                    if EllipsePlot
                        % Clear right subplot
                        cla(H2D);
                        hold(H2D,'on')
                        % Plot the ellipses in 2D
                        for c=1:NoCP
                            FNA_VisualizeEll2D(H2D, NC.P(c), 'm');
                        end
                        hold(H2D,'off')
                    end
                    
                    % LEFT Subplot: Plot plane variation, contour-parts, ellipses in 3D
                    ClearPlot(H3D, {'Patch','Scatter','Line'})
                    % Plot the plane variation
                    if PlotPlaneVariation
                        title(H3D, ['\alpha = ' num2str(Range_a(I_a)) '� & ' ...
                            '\beta = '  num2str(Range_b(I_b)) '�.'])
                        drawPlatform(H3D, createPlane([0, 0, 0], PlaneNormal),100,...
                            'FaceColor','g','FaceAlpha', 0.5);
                    end
                    % Plot contour-parts & ellipses
                    if EllipsePlot
                        for c=1:NoCP
                            FNA_VisualizeContEll3D(H3D, NC.P(c), NC.PRM, 'm');
                        end
                    end
                    drawnow
                end
        end
        
        % Save the calculation in cell array
        CutVariations{I_a,I_b} = NC;
        
        % Count the variation
        PV_Counter=PV_Counter+1;
        
        if verbose
            % Variation info in command window
            dispstat(['Plane variation ' num2str(PV_Counter) ' of ' ...
                num2str(RangeLength_a*RangeLength_b) '. '...
                char(945) ' = ' num2str(Range_a(I_a)) '� & '...
                char(946) ' = ' num2str(Range_b(I_b)) '�.'],'timestamp');
        end
    end
end

if verbose
    % Stop updated command window information
    dispstat('','keepprev');
end

%% Results
if sum(sum(~isnan(R.(Objective))))>=4
    if visu
        % convergence plot
        GD.Figure.DispersionHandle.Visible = 'on';
        hold(GD.Figure.DispersionHandle,'on')
        [Surf2.X, Surf2.Y] = meshgrid(Range_a, Range_b);
        Surf2.X = Surf2.X + GD.Iteration.OldMin(1);
        Surf2.Y = Surf2.Y + GD.Iteration.OldMin(2);
        surf(GD.Figure.DispersionHandle, Surf2.X', Surf2.Y', R.(Objective))
    end
       
    % Searching the cutting plane with minimum objective
    [minObj.Value, minDIdx] = min(R.(Objective)(:));
    [minObj.I_a, minObj.I_b] = ind2sub(size(R.(Objective)),minDIdx);
    minObj.a = Range_a(minObj.I_a); minObj.b = Range_b(minObj.I_b);
    if verbose
        disp([newline ' Minimum ' Objective ': ' num2str(minObj.Value, '%1.2f') ' mm for ' ...
            char(945) ' = ' num2str(minObj.a) '� & ' ...
            char(946) ' = ' num2str(minObj.b) '�.' newline])
    end
    
    GD.Iteration.OldMin(1) = GD.Iteration.OldMin(1)+minObj.a;
    GD.Iteration.OldMin(2) = GD.Iteration.OldMin(2)+minObj.b;
    
    % Stop the Rough Iteration if the minimum objective lies inside the
    % search space and not on the borders.
    if minObj.a == -PVR || minObj.a == PVR || minObj.b == -PVR || minObj.b == PVR
        GD.Iteration.Rough = 1;
    else
        GD.Iteration.Rough = 0;
    end
    
    MinNC = CutVariations{minObj.I_a,minObj.I_b};
    
    switch Objective
        case 'perimeter'
            % The transformation matrix for the plane variation with minimum perimeter
            GD.Results.PlaneRotMat = MinNC.PRM'; % in this case TFM' == inv(TFM)
            [~, minPlaneIdx] = min([MinNC.P.length]);
            PeriCen2D = polygonCentroid(unique(MinNC.P(minPlaneIdx).xyz(:,1:2),'rows','stable'));
            PeriCen3D = transformPoint3d([PeriCen2D, MinNC.P(minPlaneIdx).xyz(1,3)], MinNC.PRM);
            GD.Results.PlaneRotMat = createTranslation3d(-PeriCen3D)*GD.Results.PlaneRotMat;
            
            PlaneNormal = transformVector3d([0 0 1],MinNC.PRM);
            GD.Results.CenterLine = [PeriCen3D, PlaneNormal];
            GD.Results.CenterLineIdx = lineToVertexIndices(GD.Results.CenterLine, Bone);
        case 'dispersion'
            % The rotation matrix for the plane variation with minimum dispersion
            GD.Results.PlaneRotMat = MinNC.PRM'; % in this case TFM' == inv(TFM)
            
            % Calculate centers in 3D for minimum dispersion
            EllpCen3D = nan(NoCP,3);
            for c=1:NoCP
                % Save the ellipse center for the Line fit
                EllpCen3D(c,:) = CalculatePointInEllipse3D(...
                    MinNC.P(c).Ell.z, MinNC.P(c).xyz(1,3), MinNC.PRM);
            end
            
            % Calculate axis through the posterior foci
            GD.Results.CenterLine = fitLine3d(EllpCen3D);
            GD.Results.CenterLineIdx = lineToVertexIndices(GD.Results.CenterLine, Bone);
    end
    
    %% Visualization of Results
    if visu
        % Results in the main figure
        % Plot the cutting plane with minimum dispersion (Left subplot)
        ClearPlot(H3D, {'Patch','Scatter','Line'})
        PlaneNormal = transformVector3d([0 0 1],MinNC.PRM);
        drawPlatform(H3D, createPlane([0 0 0], PlaneNormal),100,...
            'FaceColor','w','FaceAlpha', 0.5);
        
        switch Objective
            case 'perimeter'
                % Plot the contours in 2D (Right subplot) for minimum perimeter
                cla(H2D);
                title(H2D, ['Min. perimeter of the contours in red: ' num2str(minObj.Value,'%.1f') ' mm'])
                hold(H2D,'on')
                % Plot contours in 2D
                C2D_Handle = arrayfun(@(x) plot(H2D, x.xyz(:,1),x.xyz(:,2),'k'), MinNC.P,'uni',0);
                [~, minPlaneIdx] = min([MinNC.P.length]);
                % Set color of min. perimeter to red
                C2D_Handle{minPlaneIdx}.Color='r';
                C2D_Handle{minPlaneIdx}.LineWidth=2;
                % Plot centroid in 2D for min. perimeter
                scatter(H2D, PeriCen2D(1),PeriCen2D(2),'r','filled', 'tag', 'SPN')
                
                % Plot min. perimeter in 3D
                title(H3D, 'Normal of the isthmus plane (min. perimeter)')
                hold(H3D,'on')
                C3D = arrayfun(@(x) transformPoint3d(x.xyz, MinNC.PRM), MinNC.P,'uni',0);
                C3D_Handle = cellfun(@(x) plot3(H3D, x(:,1),x(:,2),x(:,3),'k'), C3D,'uni',0);
                % Set color of min. perimeter to red
                C3D_Handle{minPlaneIdx}.Color='r';
                C3D_Handle{minPlaneIdx}.LineWidth=2;
                % Plot centroid in 3D for min. perimeter
                scatter3(H3D, PeriCen3D(1),PeriCen3D(2),PeriCen3D(3),'r','filled', 'tag', 'SPN')
                % Plot contour normal of the minimum perimeter
                drawLine3d(H3D, GD.Results.CenterLine, 'color','r', 'tag','SPN');
            case 'dispersion'
                % Plot the ellipses in 2D (Right subplot) for minimum dispersion
                cla(H2D);
                title(H2D, ['Minimum dispersion of the centers: ' num2str(minObj.Value,'%.2f') ' mm'])
                hold(H2D,'on')
                % Plot the ellipses in 2D
                for c=1:NoCP
                    FNA_VisualizeEll2D(H2D, MinNC.P(c), 'm');
                end
                hold(H2D,'off')
                
                % Delete old 3D ellipses & contours, if exist
                title(H3D, 'Line fit through the centers for minimum dispersion')
                hold(H3D,'on')
                % Plot contours, ellipses & foci in 3D for minimum dispersion
                for c=1:NoCP
                    FNA_VisualizeContEll3D(H3D, MinNC.P(c), MinNC.PRM, 'm');
                end
                
                % Plot centers in 3D for minimum dispersion
                scatter3(H3D, EllpCen3D(:,1),EllpCen3D(:,2),EllpCen3D(:,3),'b','filled', 'tag', 'CEA')
                
                % Plot axis through the centers for minimum dispersion
                drawLine3d(H3D, GD.Results.CenterLine, 'color','b', 'tag','CEA');
        end
        drawnow
        
        % Enable the Save button
        if isfield(GD.Figure, 'SaveResultsHandle')
            GD.Figure.SaveResultsHandle.Enable = 'on';
        end
    end
end

end