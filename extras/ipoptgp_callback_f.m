function f = ipoptgp_callback_f(x,prob)

M = prob.memo;
x = x(:);
[f,M.df] = fmincon_fungp(x,prob);
M.xF = x;
