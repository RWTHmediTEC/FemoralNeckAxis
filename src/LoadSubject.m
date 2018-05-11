function GD = LoadSubject(hObject, GD)

if ishandle(hObject)
    GD = guidata(hObject);
    
    % Subject data path
    GD.Subject.PathMAT = [GD.ToolPath GD.Subject.DataPath];
    
    load(GD.Subject.PathMAT,'F')
    Subject=F(str2double(GD.Subject.Name));
    % Store subject data
    GD.Subject.Mesh.vertices = Subject.mesh.vertices;
    GD.Subject.Mesh.faces = Subject.mesh.faces;
    GD.Subject.Side = Subject.side;
    GD.Subject.NeckAxisIdx = Subject.LM.NeckAxis;
    GD.Subject.ShaftAxisIdx = Subject.LM.ShaftAxis;
    GD.Subject.NeckOrthogonalIdx = Subject.LM.NeckOrthogonal;
end

% Create the neck axis from the vertex indices
NeckAxis=createLine3d(...
    GD.Subject.Mesh.vertices(GD.Subject.NeckAxisIdx(1),:),...
    GD.Subject.Mesh.vertices(GD.Subject.NeckAxisIdx(2),:));
NeckAxis(4:6)=normalizeVector3d(NeckAxis(4:6));
% Create the shaft axis from the vertex indices
ShaftAxis=createLine3d(...
    GD.Subject.Mesh.vertices(GD.Subject.ShaftAxisIdx(1),:),...
    GD.Subject.Mesh.vertices(GD.Subject.ShaftAxisIdx(2),:));
ShaftAxis(4:6)=normalizeVector3d(ShaftAxis(4:6));
% Create the neck orthogonal from the vertex indices
NeckOrthogonal=createLine3d(...
    GD.Subject.Mesh.vertices(GD.Subject.NeckOrthogonalIdx(1),:),...
    GD.Subject.Mesh.vertices(GD.Subject.NeckOrthogonalIdx(2),:));
NeckOrthogonal(4:6)=normalizeVector3d(NeckOrthogonal(4:6));
% Neck axis starts at the intersection of neck axis and neck orthogonal
[~, NeckAxis(1:3), ~] = distanceLines3d(NeckAxis, NeckOrthogonal);

GD.Subject.initalNeckAxis = NeckAxis;
GD.Subject.ViewVector(1,:)=-ShaftAxis(4:6);
GD.Subject.ViewVector(2,:)= NeckOrthogonal(4:6);

%% Create initial transformation
TRANS = createTranslation3d(-GD.Subject.initalNeckAxis(1:3));
ROT = createRotationVector3d(GD.Subject.initalNeckAxis(4:6),[0 0 1]);
GD.Subject.TFM = ROT*TRANS;

GD.Subject.ViewVector = transformVector3d(GD.Subject.ViewVector, GD.Subject.TFM);

switch GD.Subject.Side
    case 'R'
        Side = 'Right';
    case 'L'
        Side = 'Left';
end

if GD.Visualization == 1
    %% Configure subplots
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
    axis(lSP,'on');
    xlabel(lSP,'X [mm]'); ylabel(lSP,'Y [mm]'); zlabel(lSP,'Z [mm]');
    set(lSP,'Color',GD.Figure.Color);
    light1 = light(lSP); light(lSP, 'Position', -1*(get(light1,'Position')));
    cameratoolbar('SetCoordSys','none')
    
    %% Visualize Subject Bone with the Default Neck Plane (DNP)
    GD = VisualizeSubjectBone(GD);
    axis(lSP,'equal');
    
    % Plot a dot into the Point of Origin
    scatter3(lSP, 0,0,0,'k','filled')
end

if ishandle(hObject); guidata(hObject,GD); end
end