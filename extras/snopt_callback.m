function [F,G] = snopt_callback(x,model)
% SNOPT user callback. The compiled model is passed via the function handle
% installed by solvers/callsnopt.m (no persistent or global state).

if model.SimpleLinearObjective | model.SimpleQuadraticObjective
    [f,df] = fmincon_fun_liftlayer(x,model);
    [g,geq,dg,dgeq] = fmincon_con_liftlayer(x,model);
else
    [f,df,xevaled] = fmincon_fun_liftlayer(x,model);
    [g,geq,dg,dgeq] = fmincon_con_liftlayer(x,model,xevaled);
end

F = [f;g;geq];
n = length(x);
m = length(g);
p = length(geq);
G = [reshape(df,1,n);dg';dgeq'];
if ~isempty(model.A)
    F = [F;model.A*x - model.b];
    G = [G;model.A];
end
if ~isempty(model.Aeq)
    F = [F;model.Aeq*x - model.beq];
    G = [G;model.Aeq];
end
G = full(G(model.sparsityElements));
