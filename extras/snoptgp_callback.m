function [F,G] = snoptgp_callback(x,model)
% SNOPT GP user callback. The compiled model is passed via the function
% handle installed by the solver wrapper (no persistent or global state).

[f,df] = fmincon_fungp(x,model);
[g,geq,dg,dgeq] = fmincon_congp(x,model);
F = [f;g;geq];
n = length(x);
m = length(g);
p = length(geq);
G = [reshape(df,1,n);dg';dgeq'];
