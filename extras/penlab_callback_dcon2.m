function [G,model] = penlab_callback_dcon2(x,k,model)

x = x(:);

G = spalloc(length(model.c),length(model.c),0);
