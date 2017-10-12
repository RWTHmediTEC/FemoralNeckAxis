function B_CB_RotateBone(hObject, ~, Axis, Angle)
GD = guidata(hObject);

if isfield(GD.Subject,'PatchHandle')
    
    GD.Subject.PatchHandle.HandleVisibility='on';
    ClearPlot(GD.Figure.LeftSpHandle, {'Patch','Scatter','Line'})
    
    % Calculate the Rotation Matrix for the plane variation
    %                                (Z-Axis,Y-Axis,X-Axis)
    if     sum(Axis == [1, 0, 0]) == 3
        TFM = eulerAnglesToRotation3d(     0,     0,Angle);
    elseif sum(Axis == [0, 1, 0]) == 3
        TFM = eulerAnglesToRotation3d(     0,Angle,     0);
    elseif sum(Axis == [0, 0, 1]) == 3
        TFM = eulerAnglesToRotation3d(Angle,     0,     0);
    end
    GD.Subject.TFM = TFM*GD.Subject.TFM;
    
    GD = VisualizeSubjectBone(GD);
    
else
    uiwait(errordlg('Load a bone!','modal'));
end

guidata(hObject,GD);

