function P3D = CalculatePointInEllipse3D(P2D_XY, P2D_Z, RotTFM)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020-2023 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

% Point in 3D in XY-plane
P3D_XY = [P2D_XY, P2D_Z];
% Rotate point into plane variation
P3D = transformPoint3d(P3D_XY, RotTFM);

end