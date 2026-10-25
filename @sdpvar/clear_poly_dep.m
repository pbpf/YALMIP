function P = clear_poly_dep(P,x,order)

S = P.sess;
mt = S.getMonomtable();
xv = getvariables(x);
pv = getvariables(P);

mt = mt(pv,:);

polys = find(sum(mt(:,xv),2) > order);
if ~isempty(polys)
    P.lmi_variables(polys) = [];
    P.basis(:,1+polys) = [];
end






