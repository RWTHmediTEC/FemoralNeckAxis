function DD_CB_PlaneVariationRange(hObject, ~)
    GD = guidata(hObject);
    Index = get(hObject,'Value');
    GD.Algorithm3.PlaneVariationRange = Index-1;
    guidata(hObject,GD);
end