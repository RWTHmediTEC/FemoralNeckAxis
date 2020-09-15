function DD_CB_PlaneVariationRange(hObject, ~)
    GD = guidata(hObject);
    Index = get(hObject,'Value');
    GD.FNA_Algorithm.PlaneVariationRange = Index;
    guidata(hObject,GD);
end