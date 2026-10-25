function [G,model] = penlab_callback_dcon(x,model)

x = x(:);

G = [model.Aeq;model.A];
