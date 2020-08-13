function GD = ANA_LoadSubject(hObject, GD)

if ishandle(hObject)
    GD = guidata(hObject);
    
    % Subject data path
    GD.Subject.PathMAT = [GD.ToolPath GD.Subject.DataPath];
    
    load(GD.Subject.PathMAT,'F')
    Subject=F(str2double(GD.Subject.Name));
    % Store subject data
    GD.Subject.Mesh.vertices = Subject.mesh.vertices;
    GD.Subject.Mesh.faces = Subject.mesh.faces;
    GD.Subject.Side = upper(Subject.side(1));
    GD.Subject.NeckAxis = Subject.LM.NeckAxis;
    GD.Subject.ShaftAxis = Subject.LM.ShaftAxis;
end

%% Check direction of neck and shaft axis
% Neck axis should point in lateral direction
[~, NeckShaftIts] = distanceLines3d(GD.Subject.NeckAxis, GD.Subject.ShaftAxis);
if sign(GD.Subject.NeckAxis(4:6)) ~= sign(normalizeVector3d(NeckShaftIts(1:3)-GD.Subject.NeckAxis(1:3)))
    GD.Subject.NeckAxis(4:6)=-GD.Subject.NeckAxis(4:6);
end
GD.Subject.initalNeckAxis = normalizeLine3d(GD.Subject.NeckAxis);


%% Create initial transformation
TRANS = createTranslation3d(-GD.Subject.initalNeckAxis(1:3));
ROT = createRotationVector3d(GD.Subject.initalNeckAxis(4:6),[0 0 1]);
GD.Subject.TFM = ROT*TRANS;



if GD.Visualization == 1
    %% Configure subplots
    GD.Subject.ViewVector(1,:)= normalizeVector3d(GD.Subject.ShaftAxis(4:6));
    GD.Subject.ViewVector(2,:)= normalizeVector3d(crossProduct3d(GD.Subject.ViewVector(1,:),GD.Subject.initalNeckAxis(4:6)));
    GD.Subject.ViewVector = transformVector3d(GD.Subject.ViewVector, GD.Subject.TFM);
    if GD.Subject.ViewVector(1,3) > 0
        GD.Subject.ViewVector(1,:)=-GD.Subject.ViewVector(1,:);
    end
    switch GD.Subject.Side
        case 'R'
            Side = 'Right';
            if GD.Subject.ViewVector(2,2) < 0
                GD.Subject.ViewVector(2,:)=-GD.Subject.ViewVector(2,:);
            end
        case 'L'
            Side = 'Left';
            if GD.Subject.ViewVector(2,2) < 0
                GD.Subject.ViewVector(2,:)=-GD.Subject.ViewVector(2,:);
            end
    end
    set(GD.Figure.Handle, 'Name', [Side ' femur of subject: ' GD.Subject.Name]);
    % Clear right subplot
    rSP = GD.Figure.RightSpHandle;
    cla(rSP, 'reset');
    axis(rSP,'on','equal');
    grid(rSP,'on');
    xlabel(rSP,'X [mm]'); ylabel(rSP,'Y [mm]');
    set(rSP, 'Color', GD.Figure.Color);
    
    % Left subject subplot and properties
    lSP = GD.Figure.LeftSpHandle;
    cla(lSP,'reset');
    xlabel(lSP,'X [mm]'); ylabel(lSP,'Y [mm]'); zlabel(lSP,'Z [mm]');
    axis(lSP,'off');
    set(lSP,'Color',GD.Figure.Color);
    light1 = light(lSP); light(lSP, 'Position', -1*(get(light1,'Position')));
    cameratoolbar('SetCoordSys','none')
    
    %% Visualize Subject Bone with the Default Neck Plane (DNP)
    GD = ANA_VisualizeSubjectBone(GD);
    axis(lSP,'equal');
    
    % Plot a dot into the Point of Origin
    scatter3(lSP, 0,0,0,'k','filled')
end

if ishandle(hObject); guidata(hObject,GD); end
end