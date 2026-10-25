function f = ipopt_callback_f(x,model)

x = x(:);
M = model.memo;
[f,M.df] = fmincon_fun_liftlayer(x,model);
M.xF = x;
