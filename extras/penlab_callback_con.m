function [G,model] = penlab_callback_con(x,model)

x = x(:);

G = [model.Aeq;model.A]*x;
