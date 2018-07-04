function GD = ANA_VisualizeSubjectBone(GD)

% figure(GD.Figure.Handle);
lSP = GD.Figure.LeftSpHandle;
hold(lSP, 'on')

%% Plot the bone as patch object
boneProps.EdgeColor = 'none';
boneProps.FaceColor = [0.882, 0.831, 0.753];
boneProps.FaceAlpha = 0.7;
boneProps.EdgeLighting = 'none';
boneProps.FaceLighting = 'gouraud';
boneProps.HandleVisibility = 'Off';
GD.Subject.PatchHandle = patch(lSP,...
    transformPoint3d(GD.Subject.Mesh, GD.Subject.TFM), boneProps);

%% Plot the Default Neck Plane (DNP)
planeProps.FaceAlpha = 0.2;
planeProps.EdgeColor = 'none';
planeProps.HandleVisibility = 'Off';
planeProps.FaceColor = 'k';
DNPlane=createPlane([0,0,0], [0,0,1]);
GD.DNPlaneHandle = drawPlatform(lSP, DNPlane, 100, planeProps);

%% Set view to a unified camera position
set(lSP,'CameraTarget',[0 0 0]);
set(lSP,'CameraUpVector',GD.Subject.ViewVector(1,:));
CamNormal=get(lSP, 'CameraPosition')-get(lSP, 'CameraTarget');
CamDist=vectorNorm3d(CamNormal);
set(lSP, 'CameraPosition', get(lSP, 'CameraTarget')+...
    GD.Subject.ViewVector(2,:)*CamDist);
set(lSP,'CameraViewAngle',2);

end