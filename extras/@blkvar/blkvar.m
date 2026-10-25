function X = blkvar
% BLKVAR Constructor for block variables

X.blocks = {};
X = class(X,'blkvar',double2sdpvar(0));
	