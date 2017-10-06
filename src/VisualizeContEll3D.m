function VisualizeContEll3D(P, RotTFM, EllColor)

%% Contour
% % Plot contour-part in pseudo 3D in X-Y-Plane
% CP3D_XYP = P.xyz(P.ExPts.A:P.ExPts.B, :);
% CP3D_XYP(:,3) = 0;
% plot3(CP3D_XYP(:,1),CP3D_XYP(:,2),CP3D_XYP(:,3),'k','Linewidth',2);

% Plot contour-part in 3D
CP3D = transformPointsInverse(RotTFM, P.xyz);
plot3(CP3D(:,1),CP3D(:,2),CP3D(:,3),'k','Linewidth',2);


%% Ellipse
% Calculate ellipse points
E2D_XY = CalculateEllipsePoints(P.Ell.z', P.Ell.a, P.Ell.b, P.Ell.g, 100);
E2D_XY(:,3) = 0;

% % Plot ellipses in pseudo 3D in X-Y-Plane
% plot3(E2D_XY(:,1), E2D_XY(:,2), E2D_XY(:,3),'Color', EllColor,'Linewidth',1);

% Plot ellipses in 3D
E3D_XY = E2D_XY; E3D_XY(:,3) = P.xyz(1,3);
% Rotation into the plane variation
E3D = transformPointsInverse(RotTFM, E3D_XY);
plot3(E3D(:,1), E3D(:,2), E3D(:,3),'Color', EllColor,'Linewidth',1);


end