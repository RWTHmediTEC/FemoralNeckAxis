function P3D = CalculatePointInEllipseIn3D(P2D_XY, P2D_Z, RotTFM)

% Point in 3D in XY-plane
P3D_XY = [P2D_XY, P2D_Z];
% Rotate point into plane variation
P3D = transformPointsInverse(RotTFM, P3D_XY);

end