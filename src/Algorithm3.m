function GD = Algorithm3(GD)
%ALGORITHM3
%    - An optimization algorithm for establishing a anatomical neck axis (ANA)
%
%   REFERENCE:
%       none
%
%   INPUT:
%       Todo
%
%   OUTPUT:
%       Todo
%
%   AUTHOR: MCMF
%

if GD.Visualization == 1
    % Figure & subplot handles
    H.Fig = GD.Figure.Handle;
    H.lSP = GD.Figure.LeftSpHandle;
    H.rSP = GD.Figure.RightSpHandle;
    
    % Clear subplots
    % Right
    figure(H.Fig); subplot(H.rSP); title(''); cla
    % Left
    figure(H.Fig); subplot(H.lSP); title(''); ClearPlot(H.Fig, H.lSP, {'Patch','Scatter','Line'})
end

%% Settings
% Algorithm 3 - Part 1
% The angles are varied in StepSize° increments within following range:
PVR = GD.Algorithm3.PlaneVariationRange;
StepSize = GD.Algorithm3.StepSize;

% Ranges
Range_a = -PVR:StepSize:PVR;
Range_b = -PVR:StepSize:PVR;

% Plot Plane Variation
PlotPlaneVariation = GD.Algorithm3.PlaneVariaton;

% Algorithm 3 - Part 2
% Plot Ellipses & Foci for each plane variation into the GUI figure
EllipsePlot = GD.Algorithm3.EllipsePlot;

%% START OF THE FRAMEWORK BY LI -------------------------------------------
% Algorithm 3 - Part 1
% An optimization algorithm for establishing a anatomical neck axis (ANA)

% Bone Surface
Bone = transformPoint3d(GD.Subject.Mesh, GD.Subject.TFM);

% Number of Planes
NoP = GD.Cond.NoPpC;

% Neck Cuts (NC)
NC.Color = 'm';

% Plane variation loop counter
PV_Counter = 0;

RangeLength_a = length(Range_a);
RangeLength_b = length(Range_b);

% Variable to save the results
% R=[];
R.Dispersion = nan(RangeLength_a,RangeLength_b);
R.Perimeter = nan(RangeLength_a,RangeLength_b);

% Cell array to save the results of each plane variation
CutVariations = cell(RangeLength_a,RangeLength_b);

if GD.Verbose == 1
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
        %                                       (  Z-Axis      Y-Axis        X-Axis   )
        PlaneRotMat =    eulerAnglesToRotation3d(    0    , Range_b(I_b), Range_a(I_a));
        PlaneNormal = [0, 0, 1]*PlaneRotMat(1:3,1:3)';
        NC.RotTFM = affine3d(PlaneRotMat);
        
        % Create cutting plane origins
        NC.Origin = [0 0 0];
        for p=1:NoP
            % Distance between the plane origins has to be 1 mm in the 
            % direction of the plane normal, e.g. for NoPpC = 9:
            % -4, -3, -2, -1, 0, +1, +2, +3, +4
            NC.PlaneOrigins(p,:) = NC.Origin+(-(0.5+NoP/2)+p)*PlaneNormal;
        end; clear p;
        
        % Create NoP Neck Contour Profiles (NC.P)
        tempContour = IntersectMeshPlaneParfor(Bone, NC.PlaneOrigins, PlaneNormal);
        for c=1:NoP
            % If there is more than one closed contour after the cut, use 
            % the longest one
            [~, IobC] = max(cellfun(@length, tempContour{c}));
            NC.P(c).xyz = tempContour{c}{IobC}';
            % Close contour: Copy start value to the end, if needed
            if ~isequal(NC.P(c).xyz(1,:),NC.P(c).xyz(end,:))
                NC.P(c).xyz(end+1,:) = NC.P(c).xyz(1,:);
            end
            % Rotation back, parallel to X-Y-Plane (Default Neck Plane)
            NC.P(c).xyz = transformPointsForward(NC.RotTFM, NC.P(c).xyz);
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
        end; clear c;       
        
        %% Algorithm 2
        % A least-squares fitting algorithm for extracting geometric measures
        Contours=cell(NoP,1);
        for c=1:NoP
            % Part of the contour, that is used for fitting
            Contours{c} = NC.P(c).xyz(:,1:2)';
        end
        % Parametric least-squares fitting and analysis of cross-sectional profiles
        tempEll2D = FitEllipseParfor(Contours);
        for c=1:NoP
            Ell2D.z = tempEll2D(1:2,c);
            Ell2D.a = tempEll2D(3,c);
            Ell2D.b = tempEll2D(4,c);
            Ell2D.g = tempEll2D(5,c);
            
            NC.P(c).Ell.z = Ell2D.z';
            % Unify the orientation of the ellipses
            if Ell2D.a >= Ell2D.b
                NC.P(c).Ell.a = Ell2D.a;
                NC.P(c).Ell.b = Ell2D.b;
                NC.P(c).Ell.g = Ell2D.g;
            elseif Ell2D.a < Ell2D.b
                NC.P(c).Ell.a = Ell2D.b;
                NC.P(c).Ell.b = Ell2D.a;
                NC.P(c).Ell.g = Ell2D.g+pi/2;
            end
        end; clear c
        
        
        %% Algorithm 3 - Part 2
        % An optimization algorithm for establishing the anatomical neck axis
        
        % Calculate the ellipse foci (Foci2D) and the major (A) & minor (B) axis points (AB)
        Center2D = nan(NoP,2);
        for c=1:NoP
            [Foci2D, NC.P(c).Ell.AB] = CalculateEllipseFoci2D(...
                NC.P(c).Ell.z', NC.P(c).Ell.a, NC.P(c).Ell.b, NC.P(c).Ell.g);
            % Posterior Focus (pf): Foci2D(1,:), Anterior Focus (af): Foci2D(2,:)
            NC.P(c).Ell.pf = Foci2D(1,:);
            Center2D(c,:) = NC.P(c).Ell.z;
        end; clear c
        
        % Calculate the mean perimeter of the cuts
        R.Perimeter(I_a,I_b) = mean([NC.P.length]);
        % Calculate the Dispersion as Eccentricity Measure
        R.Dispersion(I_a,I_b) = CalculateDispersion(Center2D);
        
        if GD.Visualization == 1
            %% Visualization during iteration
            % RIGHT subplot: Plot the ellipses in 2D in the XY-plane
            if EllipsePlot == 1
                % Clear right subplot
                figure(H.Fig); subplot(H.rSP); cla;
                hold on;
                % Plot the ellipses in 2D
                for c=1:NoP
                    VisualizeEll2D(NC.P(c), NC.Color);
                end; clear c
                hold off
            end
            
            % LEFT Subplot: Plot plane variation, contour-parts, ellipses in 3D
            figure(H.Fig); subplot(H.lSP);
            ClearPlot(H.Fig, H.lSP, {'Patch','Scatter','Line'})
            % Plot the plane variation
            if PlotPlaneVariation == 1
                title(['\alpha = ' num2str(Range_a(I_a)) '° & ' ...
                    '\beta = '  num2str(Range_b(I_b)) '°.'])
                drawPlane3d(createPlane([0, 0, 0], PlaneNormal),...
                    'FaceColor','g','FaceAlpha', 0.5);
            end
            % Plot contour-parts & ellipses
            if EllipsePlot == 1
                for c=1:NoP
                    VisualizeContEll3D(NC.P(c), NC.RotTFM, NC.Color);
                end; clear c
            end
            drawnow
        end
        
        % Save the calculation in cell array
        CutVariations{I_a,I_b} = NC;
        % Count the variation
        PV_Counter=PV_Counter+1;
        if GD.Verbose == 1
            % Variation info in command window
            dispstat(['Plane variation ' num2str(PV_Counter) ' of ' ...
                num2str(RangeLength_a*RangeLength_b) '. '...
                char(945) ' = ' num2str(Range_a(I_a)) '° & '...
                char(946) ' = ' num2str(Range_b(I_b)) '°.'],'timestamp');
        end
    end; clear I_b
end; clear I_a
clear NC

if GD.Verbose == 1
    % Stop updated command window information
    dispstat('','keepprev');
end


%% Results
if sum(sum(~isnan(R.Dispersion)))>=4
    % if sum(sum(~isnan(R.Dispersion))) > 3
    if GD.Visualization == 1
        %% Dispersion plot
        % A representative plot of the dispersion of focus locations
        % as a function of alpha (a) and beta (b).
        if ishandle(GD.Results.FigHandle)
            figure(GD.Results.FigHandle)
            hold on
        else
            GD.Results.FigHandle = figure('Name', GD.Subject.Name, 'Color', 'w');
        end
        xlabel('\alpha');ylabel('\beta');zlabel('Dispersion [mm]')
        title('Dispersion of focus locations as a function of \alpha & \beta')
        [Surf2.X, Surf2.Y] = meshgrid(Range_a, Range_b);
        Surf2.X = Surf2.X + GD.Results.OldDMin(1);
        Surf2.Y = Surf2.Y + GD.Results.OldDMin(2);
        surf(Surf2.X', Surf2.Y', R.Dispersion)
    end
       
    % Searching the cutting plane with minimum Dispersion
    [minD.Value, minDIdx] = min(R.Dispersion(:));
    [minD.I_a, minD.I_b] = ind2sub(size(R.Dispersion),minDIdx);
    minD.a = Range_a(minD.I_a); minD.b = Range_b(minD.I_b);
    if GD.Verbose == 1
        disp([newline ' Minimum Dispersion: ' num2str(minD.Value) ' for ' ...
            char(945) ' = ' num2str(minD.a) '° & ' ...
            char(946) ' = ' num2str(minD.b) '°.' newline])
    end
    
    GD.Results.OldDMin(1) = GD.Results.OldDMin(1)+minD.a;
    GD.Results.OldDMin(2) = GD.Results.OldDMin(2)+minD.b;
    
    % Stop the Rough Iteration if the minimum dispersion lies inside the
    % search space and not on the borders.
    if minD.a == -PVR || minD.a == PVR || minD.b == -PVR || minD.b == PVR
        GD.Iteration.Rough = 1;
    else
        GD.Iteration.Rough = 0;
    end
    
    MinNC = CutVariations{minD.I_a,minD.I_b};
    
    % The rotation matrix for the plane variation with minimum Dispersion
    GD.Results.PlaneRotMat = inv(MinNC.RotTFM.T);
    
    % Calculate centers in 3D for minimum Dispersion
    EllpCen3D = nan(NoP,3);
    for c=1:NoP
        % Save the ellipse center for the Line fit
        EllpCen3D(c,:) = CalculatePointInEllipseIn3D(...
            MinNC.P(c).Ell.z, MinNC.P(c).xyz(1,3), MinNC.RotTFM);
    end; clear c
    
    % Calculate axis through the posterior foci
    GD.Results.CenterLine = fitLine3d(EllpCen3D);
    
    % Display info about the ellipses in the command window
    EllResults = CalcAndPrintEllipseResults(MinNC, NoP, GD.Verbose);
    GD.Results.Ell.a = EllResults(1,:);
    GD.Results.Ell.b = EllResults(2,:);
    
    %% Visualization of Results
    if GD.Visualization == 1
        % Results in the main figure
        % Plot the cutting plane with minimum Dispersion (Left subplot)
        figure(H.Fig); subplot(H.lSP); ClearPlot(H.Fig, H.lSP, {'Patch','Scatter','Line'})
        PlaneNormal = [0, 0, 1]*GD.Results.PlaneRotMat(1:3,1:3)';
        drawPlane3d(createPlane([0, 0, 0], PlaneNormal),'FaceColor','w','FaceAlpha', 0.5);
        
        % Plot the ellipses in 2D (Right subplot) for minimum Dispersion
        figure(H.Fig); subplot(H.rSP); cla;
        title(['Minimum Dispersion of the centers: ' num2str(minD.Value) ' mm'])
        hold on;
        % Plot the ellipses in 2D
        for c=1:NoP
            VisualizeEll2D(MinNC.P(c), MinNC.Color);
        end; clear c
        hold off
        
        % Delete old 3D ellipses & contours, if exist
        figure(H.Fig); subplot(H.lSP);
        title('Line fit through the centers for minimum Dispersion')
        hold on
        % Plot contours, ellipses & foci in 3D for minimum Dispersion
        for c=1:NoP
            VisualizeContEll3D(MinNC.P(c), MinNC.RotTFM, MinNC.Color);
        end; clear c
        
        % Plot centers in 3D for minimum Dispersion
        scatter3(EllpCen3D(:,1),EllpCen3D(:,2),EllpCen3D(:,3),'b','filled', 'tag', 'CEA')
        
        % Plot axis through the centers for minimum Dispersion
        drawLine3d(GD.Results.CenterLine, 'color','b', 'tag','CEA');
        
        % Enable the Save button
        if isfield(GD.Results, 'B_H_SaveResults')
            set(GD.Results.B_H_SaveResults,'Enable','on')
        end
    end
end

end