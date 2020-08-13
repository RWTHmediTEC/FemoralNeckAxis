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
[~, NeckShaftIts, ShaftNeckIts] = distanceLines3d(GD.Subject.NeckAxis, GD.Subject.ShaftAxis);
if sign(GD.Subject.NeckAxis(4:6)) ~= sign(normalizeVector3d(NeckShaftIts(1:3)-GD.Subject.NeckAxis(1:3)))
    GD.Subject.NeckAxis(4:6)=-GD.Subject.NeckAxis(4:6);
end
% Shaft axis should point in distal direction
if sign(GD.Subject.ShaftAxis(4:6)) ~= sign(normalizeVector3d(GD.Subject.ShaftAxis(1:3)-ShaftNeckIts))
    GD.Subject.ShaftAxis(4:6)=-GD.Subject.ShaftAxis(4:6);
end
% !!! Include sanity checks after transformation !!!

GD.Subject.initalNeckAxis = normalizeLine3d(GD.Subject.NeckAxis);
GD.Subject.ViewVector(1,:)= normalizeVector3d(GD.Subject.ShaftAxis(4:6));
switch GD.Subject.Side
    case 'R'
        GD.Subject.ViewVector(2,:)= normalizeVector3d(...
            crossProduct3d(GD.Subject.ViewVector(1,:),GD.Subject.initalNeckAxis(4:6)));
    case 'L'
        GD.Subject.ViewVector(2,:)= normalizeVector3d(...
            crossProduct3d(GD.Subject.initalNeckAxis(4:6), GD.Subject.ViewVector(1,:)));
end

%% Create initial transformation
TRANS = createTranslation3d(-GD.Subject.initalNeckAxis(1:3));
ROT = createRotationVector3d(GD.Subject.initalNeckAxis(4:6),[0 0 1]);
GD.Subject.TFM = ROT*TRANS;

GD.Subject.ViewVector = transformVector3d(GD.Subject.ViewVector, GD.Subject.TFM);

if GD.Visualization == 1
    %% Configure subplots
    switch GD.Subject.Side; case 'R'; Side = 'Right'; case 'L'; Side = 'Left'; end
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
    axis(lSP,'off');
%     xlabel(lSP,'X [mm]'); ylabel(lSP,'Y [mm]'); zlabel(lSP,'Z [mm]');
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