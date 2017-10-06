function GD = VisualizeSubjectBone(GD)

figure(GD.Figure.Handle); subplot(GD.Figure.LeftSpHandle);

%% Plot the bone as patch object
BoneProps.EdgeColor = 'none';
BoneProps.FaceColor = [0.882, 0.831, 0.753];
BoneProps.FaceAlpha = 0.7;
BoneProps.EdgeLighting = 'none';
BoneProps.FaceLighting = 'gouraud';
BoneProps.HandleVisibility = 'Off';
GD.Subject.PatchHandle = patch(...
    transformPoint3d(GD.Subject.Mesh, GD.Subject.TFM), BoneProps);


%% Plot the Default Neck Plane (DNP)
PlaneProps.FaceAlpha = 0.2;
PlaneProps.EdgeColor = 'none';
PlaneProps.HandleVisibility = 'Off';
PlaneProps.FaceColor = 'k';

DNPlane=createPlane([0,0,0], [0,0,1]);
GD.DSPlane.Handle = drawPlane3d(DNPlane, PlaneProps);

%% Set view to a unified camera position
set(GD.Figure.LeftSpHandle,'CameraTarget',[0 0 0]);
set(GD.Figure.LeftSpHandle,'CameraUpVector',GD.Subject.ViewVector(1,:));
CamNormal=get(gca, 'CameraPosition')-get(gca, 'CameraTarget');
CamDist=vectorNorm3d(CamNormal);
set(gca, 'CameraPosition', get(gca, 'CameraTarget')+...
    GD.Subject.ViewVector(2,:)*CamDist);
set(GD.Figure.LeftSpHandle,'CameraViewAngle',2);

end