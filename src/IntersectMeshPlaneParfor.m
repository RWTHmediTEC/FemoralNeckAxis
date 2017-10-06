function Contours = IntersectMeshPlaneParfor(Mesh, PlaneOrigins, PlaneNormals)

if size(PlaneOrigins,2)~=3 
    error('Size of PlaneOrigins has to be Nx3')
end

if size(PlaneNormals,2)~=3 
    error('Size of PlaneNormals has to be Nx3')
end

if size(PlaneNormals,1)~=size(PlaneOrigins,1) && size(PlaneNormals,1)~=1
    error('Size of PlaneNormals has to the same as PlaneOrigins or 1x3')
end

if size(PlaneNormals,1)==1
    PlaneNormals = repmat(PlaneNormals, size(PlaneOrigins,1),1);
end

parfor p=1:size(PlaneOrigins,1)
    % To speed things up, use only the faces in the cutting plane as input 
    % for intersectPlaneSurf
    % Logical index to the vertices below the plane
    VBPl_LI = isBelowPlane(Mesh.vertices, createPlane(PlaneOrigins(p,:), PlaneNormals(p,:)));
    % Logical index to three vertices of each face
    FBP_LI = VBPl_LI(Mesh.faces);
    % Faces in the plane, 1 or 2 vertices == 0
    FacesInPlane = CutFacesOffMesh(Mesh, (sum(FBP_LI, 2) > 0 & sum(FBP_LI, 2) < 3) );
    Contours{p} = intersectPlaneSurf(FacesInPlane, PlaneOrigins(p,:), PlaneNormals(p,:));
end; clear p
