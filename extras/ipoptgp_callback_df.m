function df = ipoptgp_callback_df(x,model)

M = model.memo;
x = x(:);
if isequal(x,M.xF)
    df = M.df;
else
    [f,df] = fmincon_fungp(x,model);
    M.df = df;
end
