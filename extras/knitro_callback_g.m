function [g,geq,dg,dgeq] = knitro_callback_g(x,model)

M = model.memo;
x = x(:);
if isequal(x,M.xG)
    % Jacobian was computed earlier
   g = M.g;
   dg = M.dg;
   geq = M.geq;
   dgeq = M.dgeq;
else
    % Compute the nonlinear terms in the constraints
    [g,geq,dg,dgeq,xevaled] = fmincon_con(x,model);
    M.xG = x;
    M.g = g;
    M.dg = dg;
    M.geq = geq;
    M.dgeq = dgeq;
end
