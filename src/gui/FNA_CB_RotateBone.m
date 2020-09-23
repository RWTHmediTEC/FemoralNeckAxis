function FNA_CB_RotateBone(hObject, ~, Axis, Angle)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

GD = guidata(hObject);

if isfield(GD.Subject,'PatchHandle')
    
    GD.Subject.PatchHandle.HandleVisibility='on';
    ClearPlot(GD.Figure.D3Handle, {'Patch','Scatter','Line'})
    
    % Calculate the Rotation Matrix for the plane variation
    %                                (z axis,y axis,x axis)
    if     sum(Axis == [1, 0, 0]) == 3
        TFM = eulerAnglesToRotation3d(     0,     0,Angle);
    elseif sum(Axis == [0, 1, 0]) == 3
        TFM = eulerAnglesToRotation3d(     0,Angle,     0);
    elseif sum(Axis == [0, 0, 1]) == 3
        TFM = eulerAnglesToRotation3d(Angle,     0,     0);
    end
    GD.Subject.TFM = TFM*GD.Subject.TFM;
    
    GD = FNA_VisualizeSubjectBone(GD);
    
else
    uiwait(errordlg('Load a bone!','modal'));
end

guidata(hObject,GD);
end