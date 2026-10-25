function df = ipopt_callback_df(x,model)

x = x(:);
M = model.memo;
if isequal(x,M.xF)
    df = M.df;
else
    [f,df] = fmincon_fun_liftlayer(x,model);
end
