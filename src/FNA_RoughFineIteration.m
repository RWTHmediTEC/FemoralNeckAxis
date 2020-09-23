function GD = FNA_RoughFineIteration(hObject, GD)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

if ishandle(hObject)
    GD = guidata(hObject);
    ClearPlot(GD.Figure.DispersionHandle, {'Surf'})
    GD.Figure.DispersionHandle.Visible = 'off';
end

% Variable to save the rotation values during the rough iterations
GD.Results.OldDMin(1) = 0; GD.Results.OldDMin(2) = 0;

%% Rough Iteration
if GD.Verbose == 1
    disp('----- Starting Rough Iteration -----------------------------------');
end
GD.Iteration.Rough = 1;
% Execute the Rough Iteration until the minimum dispersion lies inside
% the search space and not on the borders.
while GD.Iteration.Rough == 1
    GD = FNA_Algorithm(GD);
    GD.Subject.TFM = GD.Results.PlaneRotMat*GD.Subject.TFM;
    if GD.Visualization == 1
        % Clear left subplot
        title(GD.Figure.D3Handle,'');
        ClearPlot(GD.Figure.D3Handle, {'Patch','Scatter','Line'})
        delete(GD.Subject.PatchHandle);
        delete(GD.DNPlaneHandle);
        % Plot bone with newest transformation
        GD = FNA_VisualizeSubjectBone(GD);
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
OldPVRange  = GD.FNA_Algorithm.PlaneVariationRange;
OldStepSize = GD.FNA_Algorithm.StepSize;

% The new Step Size for the Fine Iteration
FineStepSize = 0.5;
if GD.FNA_Algorithm.StepSize >= 1
    % The new Plane Variation Range is the Step Size of the Rough
    GD.FNA_Algorithm.PlaneVariationRange = GD.FNA_Algorithm.StepSize;
else
    % Minimal Plane Variation Range is the fine Step Size.
    GD.FNA_Algorithm.PlaneVariationRange = FineStepSize;
end
GD.FNA_Algorithm.StepSize = FineStepSize;
GD = FNA_Algorithm(GD);
% Calculate the femoral neck axis (FNA) in the FNA system
% FNA_FNA = transformLine3d(GD.Results.CenterLine, GD.Results.PlaneRotMat);
% Calculate the FNA in the input bone system
GD.Results.FNA = transformLine3d(GD.Results.CenterLine, inv(GD.Subject.TFM));
% Sanity check
FNA_Idx = lineToVertexIndices(GD.Results.FNA, GD.Subject.Mesh);
assert(isequal(GD.Results.CenterLineIdx, FNA_Idx))
if numel(FNA_Idx)~=2
    warning(['Femoral neck axis (FNA) should have 2 intersection ' ...
        'points with the bone surface. But number of intersection', ...
         'points is: ' num2str(numel(FNA_Idx)) '!']);
end

% Calculate the transformation from the initial bone position into the FNA
GD.Subject.TFM  = GD.Results.PlaneRotMat*GD.Subject.TFM;

if GD.Verbose == 1
    disp('----- Finished Fine Iteration ------------------------------------');
    disp(' ');
end

% Set Plane Variation Range & Step Size to the old GUI values
GD.FNA_Algorithm.PlaneVariationRange = OldPVRange;
GD.FNA_Algorithm.StepSize = OldStepSize;

if ishandle(hObject); guidata(hObject,GD); end
end
