function GD = FNA_VisualizeSubjectBone(GD)


H3D = GD.Figure.D3Handle;
hold(H3D, 'on')

%% Plot the bone as patch object
boneProps.EdgeColor = 'none';
boneProps.FaceColor = [0.882, 0.831, 0.753];
boneProps.FaceAlpha = 0.7;
boneProps.EdgeLighting = 'none';
boneProps.FaceLighting = 'gouraud';
boneProps.HandleVisibility = 'Off';
GD.Subject.PatchHandle = patch(H3D,...
    transformPoint3d(GD.Subject.Mesh, GD.Subject.TFM), boneProps);

%% Plot the Default Neck Plane (DNP)
planeProps.FaceAlpha = 0.2;
planeProps.EdgeColor = 'none';
planeProps.HandleVisibility = 'Off';
planeProps.FaceColor = 'k';
DNPlane=createPlane([0,0,0], [0,0,1]);
GD.DNPlaneHandle = drawPlatform(H3D, DNPlane, 100, planeProps);

%% Set view to a unified camera position
set(H3D,'CameraTarget',[0 0 0]);
set(H3D,'CameraUpVector',GD.Subject.ViewVector(1,:));
CamNormal=get(H3D, 'CameraPosition')-get(H3D, 'CameraTarget');
CamDist=vectorNorm3d(CamNormal);
set(H3D, 'CameraPosition', get(H3D, 'CameraTarget')+...
    GD.Subject.ViewVector(2,:)*CamDist);
set(H3D,'CameraViewAngle',2);

end