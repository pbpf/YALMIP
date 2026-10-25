function selectsolution(k)
%SELECTSOLUTION Obsolete helper (was a global-state shortcut)
%
%   Solution selection is done on a session: S.selectsolution(k), or by
%   passing the desired solution struct to VALUE/DUAL directly.

error('YALMIP:sessionRequired','Use S.selectsolution(k) on a yalmip.Session object, or pass the solution struct explicitly to VALUE/DUAL.')
