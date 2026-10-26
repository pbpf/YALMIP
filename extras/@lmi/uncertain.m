function sys = uncertain(F)
%UNCERTAIN Declare all variables in a set of constraints as uncertain

sys = recover(depends(F),sessOf(F));
sys = [F, uncertain(sys)];
