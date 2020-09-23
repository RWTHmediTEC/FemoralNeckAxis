function FNA_VisualizeContEll3D(H, P, RotTFM, EllColor)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

%% Contour
% Plot contour-part in 3D
CP3D = transformPoint3d(P.xyz, RotTFM);
plot3(H, CP3D(:,1),CP3D(:,2),CP3D(:,3), 'k', 'Linewidth',2);

%% Ellipse
% Calculate ellipse points
E2D_XY = CalculateEllipsePoints(P.Ell.z', P.Ell.a, P.Ell.b, P.Ell.g, 100);
% Plot ellipses in 3D
E3D_XY = E2D_XY; E3D_XY(:,3) = P.xyz(1,3);
% Rotation into the plane variation
E3D = transformPoint3d(E3D_XY, RotTFM);
plot3(H, E3D(:,1), E3D(:,2), E3D(:,3),'Color',EllColor, 'Linewidth',1);

end