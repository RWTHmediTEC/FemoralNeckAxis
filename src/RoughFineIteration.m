function GD = RoughFineIteration(hObject, GD)
if ishandle(hObject); GD = guidata(hObject); end

% Variable to save the rotation values during the rough iterations
GD.Results.OldDMin(1) = 0; GD.Results.OldDMin(2) = 0;
GD.Results.AxHandle = nan;


%% Rough Iteration
if GD.Verbose == 1
    disp('----- Starting Rough Iteration -----------------------------------');
end
GD.Iteration.Rough = 1;
% Execute the Rough Iteration until the minimum dispersion lies inside
% the search space and not on the borders.
while GD.Iteration.Rough == 1
    GD = Algorithm3(GD);
    GD.Subject.TFM = GD.Results.PlaneRotMat*GD.Subject.TFM;
    if GD.Visualization == 1
        % Clear left subplot
        title(GD.Figure.LeftSpHandle,'');
        ClearPlot(GD.Figure.LeftSpHandle, {'Patch','Scatter','Line'})
        delete(GD.Subject.PatchHandle);
        delete(GD.DNPlaneHandle);
        % Plot bone with newest transformation
        GD = VisualizeSubjectBone(GD);
        drawnow;
    end
end
if GD.Verbose == 1
    disp('----- Finished Rough Iteration -----------------------------------');
    disp(' ');
end


%% Fine Iteration
if GD.Verbose == 1
    disp('----- Starting Fine Iteration ------------------------------------');
end
% Save the GUI values of Plane Variation Range & Step Size
OldPVRange  = GD.Algorithm3.PlaneVariationRange;
OldStepSize = GD.Algorithm3.StepSize;

% The new Step Size for the Fine Iteration
FineStepSize = 0.5;
if GD.Algorithm3.StepSize >= 1
    % The new Plane Variation Range is the Step Size of the Rough
    GD.Algorithm3.PlaneVariationRange = GD.Algorithm3.StepSize;
else
    % Minimal Plane Variation Range is the fine Step Size.
    GD.Algorithm3.PlaneVariationRange = FineStepSize;
end
GD.Algorithm3.StepSize = FineStepSize;
GD = Algorithm3(GD);
% Calculate the anatomical neck axis (ANA) in the ANA system
% ANA_ANA = transformLine3d(GD.Results.CenterLine, GD.Results.PlaneRotMat);
% Calculate the anatomical neck axis in the input bone system
GD.Results.ANA = transformLine3d(GD.Results.CenterLine, inv(GD.Subject.TFM));
% Sanity check
ANA_Idx = lineToVertexIndices(GD.Results.ANA, GD.Subject.Mesh);
assert(isequal(GD.Results.CenterLineIdx, ANA_Idx))
if numel(ANA_Idx)~=2
    warning(['Anatomical neck axis (ANA) should have 2 intersection ' ...
        'points with the bone surface. But number of intersection', ...
         'points is: ' num2str(numel(ANA_Idx)) '!']);
end

% Calculate the transformation from the initial bone position into the ANA
GD.Subject.TFM  = GD.Results.PlaneRotMat*GD.Subject.TFM;

if GD.Verbose == 1
    disp('----- Finished Fine Iteration ------------------------------------');
    disp(' ');
end

% Set Plane Variation Range & Step Size to the old GUI values
GD.Algorithm3.PlaneVariationRange = OldPVRange;
GD.Algorithm3.StepSize = OldStepSize;

if ishandle(hObject); guidata(hObject,GD); end
end
