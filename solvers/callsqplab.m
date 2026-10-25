function output = callsqplab(interfacedata) %#ok<INUSD>
%CALLSQPLAB Solver wrapper for SQPLAB (removed in the stateless refactor)
%
%   The SQPLAB MATLAB interface receives its problem data through a global
%   variable (SQPLABDATA) that is read by the external file sqplab_simul.m,
%   which is not part of YALMIP and cannot be modified. Since the stateless
%   refactoring removed all global variables, this interface can no longer
%   be supported. Use a different nonlinear solver (fmincon, IPOPT, KNITRO,
%   ...) or restore this file from the pre-refactor history if you must use
%   SQPLAB.

error('YALMIP:sqplabRemoved', ['The SQPLAB interface was removed in the stateless refactor: ', ...
    'the external sqplab_simul.m requires YALMIP to publish problem data through a global variable, ', ...
    'which the refactor eliminated. Use another nonlinear solver instead.']);
end
