function FNA_VisualizeEll2D(H, P, Color)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

z = P.Ell.z;
a = P.Ell.a;
b = P.Ell.b;
alpha = P.Ell.g;
AB = P.Ell.AB;

% Plot ellipses & foci in 2D
scatter(H, z(1),z(2),'MarkerEdgeColor', [0,0,0], 'MarkerFaceColor',Color);
drawEllipse(H, z(1),z(2), a, b, rad2deg(alpha), 'Color', Color);
quiver(H, repmat(z(1),2,1),repmat(z(2),2,1), AB(:,1), AB(:,2),...
    ':k','Autoscale','off','ShowArrowHead','off');
quiver(H, repmat(z(1),2,1),repmat(z(2),2,1),-AB(:,1),-AB(:,2),...
    ':k','Autoscale','off','ShowArrowHead','off');

end