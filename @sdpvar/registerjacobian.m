function [p] = registerjacobian(p)
%REGISTERJACOBIAN Register jacobians to an expression

if ~isfield(p.extra, 'jacobian')
    x = recover(depends(p), p.sess);
    p.extra.jacobian = jacobian(p,x);
end