function GD = FNA_LoadSubject(hObject, GD)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

if ishandle(hObject)
    GD = guidata(hObject);
    
    % Subject data path
    for p=1:length(GD.Subject.DataPath)
        load(fullfile(GD.ToolPath, GD.Subject.DataPath{p}, [GD.Subject.Name '.mat'])) %#ok<LOAD> 
    end
    
    % Store subject data
    GD.Subject.Mesh = B(ismember({B.name}, ['Femur_' GD.Subject.Side])).mesh;
    GD.Subject.NeckAxis = normalizeLine3d(NeckAxis);
    GD.Subject.ShaftAxis = normalizeLine3d(ShaftAxis);
end

%% Check direction of neck and shaft axis
% Neck axis should point in lateral direction
[~, NeckShaftIts] = distanceLines3d(GD.Subject.NeckAxis, GD.Subject.ShaftAxis);
if sign(GD.Subject.NeckAxis(4:6)) ~= sign(normalizeVector3d(NeckShaftIts(1:3)-GD.Subject.NeckAxis(1:3)))
    GD.Subject.NeckAxis(4:6)=-GD.Subject.NeckAxis(4:6);
end


%% Create initial transformation
TRANS = createTranslation3d(-GD.Subject.NeckAxis(1:3));
ROT = createRotationVector3d(GD.Subject.NeckAxis(4:6),[0 0 1]);
GD.Subject.TFM = ROT*TRANS;

if GD.Visualization
    % Inital view of the 3D plot
    GD.Subject.ViewVector(1,:) = GD.Subject.ShaftAxis(4:6);
    GD.Subject.ViewVector(2,:) = normalizeVector3d(...
        crossProduct3d(GD.Subject.ViewVector(1,:), GD.Subject.NeckAxis(4:6)));
    GD.Subject.ViewVector = transformVector3d(GD.Subject.ViewVector, GD.Subject.TFM);
    if GD.Subject.ViewVector(1,3) > 0
        GD.Subject.ViewVector(1,:) = -GD.Subject.ViewVector(1,:);
    end
    switch GD.Subject.Side
        case 'R'
            Side = 'Right';
            if GD.Subject.ViewVector(2,2) < 0
                GD.Subject.ViewVector(2,:) = -GD.Subject.ViewVector(2,:);
            end
        case 'L'
            Side = 'Left';
            if GD.Subject.ViewVector(2,2) < 0
                GD.Subject.ViewVector(2,:) = -GD.Subject.ViewVector(2,:);
            end
    end
    GD.Figure.Handle.Name = [Side ' femur of subject: ' GD.Subject.Name];
    
    % Clear dispersion plot
    ClearPlot(GD.Figure.DispersionHandle, {'Surf'})
    GD.Figure.DispersionHandle.Visible = 'off';
    
    % Clear 2D plot
    H2D = GD.Figure.D2Handle;
    cla(H2D, 'reset');
    axis(H2D,'on','equal');
    grid(H2D,'on');
    xlabel(H2D,'X [mm]'); ylabel(H2D,'Y [mm]');
    set(H2D, 'Color', GD.Figure.Color);
    
    % Left 3D plot and properties
    H3D = GD.Figure.D3Handle;
    cla(H3D,'reset');
    xlabel(H3D,'X [mm]'); ylabel(H3D,'Y [mm]'); zlabel(H3D,'Z [mm]');
    axis(H3D,'off');
    set(H3D,'Color',GD.Figure.Color);
    light1 = light(H3D); light(H3D, 'Position', -1*(get(light1,'Position')));
    cameratoolbar('SetCoordSys','none')
    
    %% Visualize Subject Bone with the Default Neck Plane (DNP)
    GD = FNA_VisualizeSubjectBone(GD);
    axis(H3D,'equal');
    
    % Plot a dot into the Point of Origin
    scatter3(H3D, 0,0,0,'k','filled')
end

if ishandle(hObject); guidata(hObject,GD); end
end