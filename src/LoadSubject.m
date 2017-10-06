function GD = LoadSubject(hObject, GD)
if ishandle(hObject); GD = guidata(hObject); end
cd(GD.ToolPath)

if ishandle(hObject)
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

if GD.Visualization == 1
    %% Configure subplots
    figure(GD.Figure.Handle);
    set(GD.Figure.Handle, 'Name', [GD.Subject.Side ' femur of subject: ' GD.Subject.Name]);
    % Clear right subplot
    subplot(GD.Figure.RightSpHandle); cla reset;
    axis on; axis equal; grid on; xlabel('X [mm]'); ylabel('Y [mm]');
    set(GD.Figure.RightSpHandle, 'Color', GD.Figure.Color);
    
    % Left subject subplot and properties
    subplot(GD.Figure.LeftSpHandle);
    cla reset;
    axis on; xlabel('X [mm]'); ylabel('Y [mm]'); zlabel('Z [mm]');
    set(GD.Figure.LeftSpHandle,'Color',GD.Figure.Color);
    light1 = light; light('Position', -1*(get(light1,'Position')));
    daspect([1 1 1])
    cameratoolbar('SetCoordSys','none')
    
    %% Visualize Subject Bone with the Default Neck Plane (DNP)
    GD = VisualizeSubjectBone(GD);
    
    %% Find most posterior points of the condyles (mpCPts) & plot the cutting boxes
    GD = SetStartSetup(GD);
    
    % Plot a dot into the Point of Origin
    scatter3(0,0,0,'k','filled')
end

if ishandle(hObject); guidata(hObject,GD); end
end