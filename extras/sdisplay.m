function symb_pvec = sdisplay(pvec,precision)
%SDISPLAY Symbolic display of SDPVAR expression
%
% As variables in YALMIP do not have any actual names internally, the
% command is not guaranteed to recover the variable names you use in the
% work-space correctly. It tries to figure out the names of the variables
% by searching in the work-space for variables involving the same variable
% indicies, but this can fails in many instances.
%
% EXAMPLES
%  sdpvar x y
%  sdisplay(x^2+y^2)
%    ans =
%       'x^2+y^2'
%
% Optionally, we can supply an option to round the data to N decimal digits
%
%  sdisplay(pi*x1^2,4)
%    ans = '3.1416*x^2'

if nargin < 2
    precision = inf;
end

% Support displaying non-sdpvar input
if ~isa(pvec,'sdpvar')
    for r1=1:size(pvec,1)
        for r2=1:size(pvec,2)
            p = full(pvec(r1,r2));
            if isa(p,'double')
                symb_pvec{r1,r2} = num2str2(p,precision);
            else
                symb_pvec{r1,r2} = p;
            end
        end
    end
    if prod(size(symb_pvec))==1 & nargout==0
        display(symb_pvec{1,1});
        clear symb_pvec
    end
    return;
end

% Figure out the symbolic names. Variables created with a display name
% (S.sdpvar("x",[3 1])) carry their name in the session registry; unnamed
% variables are shown as internal(id).
S = session(pvec);

global_LinearVariables = depends(pvec);
global_x = recover(global_LinearVariables, S);
[global_exponent_p,global_ordered_list] = exponents(pvec,global_x);
global_exponent_p = full(global_exponent_p);
global_names = S.getvariablenames(global_LinearVariables);

for pi = 1:size(pvec,1)
    for pj = 1:size(pvec,2)
        p = pvec(pi,pj);
        if isa(p,'double')
            symb_p = num2str2(p,precision);
        else            
            symb_p = createSymbolicExpression(p,global_LinearVariables,global_names,precision,S);           
        end        
        symb_pvec{pi,pj} = symb_p;
    end
end

if prod(size(symb_pvec))==1 & nargout==0
    display(symb_pvec{1,1});
    clear symb_pvec
end

function symb_p =  createSymbolicExpression(p,global_LinearVariables,global_names,precision,S)
LinearVariables = depends(p);
x = recover(LinearVariables);
[exponent_p,ordered_list] = exponents(p,x);
exponent_p = full(exponent_p);
[~,map] = ismember(LinearVariables,global_LinearVariables);
for j = 1:length(map)
    if map(j) == 0 
        map(j) = length(global_names)+1;
        global_names{end+1} = ['internal(' num2str(LinearVariables(j)) ')'];
    end
end
names = {global_names{map}};
for i = 1:length(x)
    if is(x(i),'compound')
        E = S.extstruct(LinearVariables(i));
        if length(E.arg)==2
           arg = E.arg{1};
           symb_arg = createSymbolicExpression(arg,global_LinearVariables,global_names,precision);
           names{i} = [E.fcn '(' symb_arg ')'];
        end
    end
end


% Remove 0 constant
symb_p = '';
if size(ordered_list,1)>0
    nummonoms = size(ordered_list,1);
    if full(getbasematrix(p,0)) ~= 0
        symb_p = num2str2(full(getbasematrix(p,0)),precision);
    end
elseif all(exponent_p(1,:)==0)
    symb_p = num2str2(full(getbasematrix(p,0)),precision);
    exponent_p = exponent_p(2:end,:);
    nummonoms = size(exponent_p,1);
else
    nummonoms = size(exponent_p,1);
end

% Loop through all monomial terms
for i = 1:nummonoms
    coeff = full(getbasematrixwithoutcheck(p,i));
    switch coeff
        case 1
            coeff='+';
        case -1
            coeff = '-';
        otherwise
            if isreal(coeff)
                if coeff >0
                    coeff = ['+' num2str2(coeff,precision)];
                else
                    coeff=[num2str2(coeff,precision)];
                end
            else
                coeff = ['+' '(' num2str2(coeff,precision) ')' ];
            end
    end
    if isempty(ordered_list)
        symb_p = [symb_p coeff symbmonom(names,exponent_p(i,:))];
    else
        symb_p = [symb_p coeff symbmonom_noncommuting(names,ordered_list(i,:))];
    end
end
% Clean up some left overs, lazy coding...
symb_p = strrep(symb_p,'+*','+');
symb_p = strrep(symb_p,'-*','-');
if symb_p(1)=='+'
    symb_p = symb_p(2:end);
end
if symb_p(1)=='*'
    symb_p = symb_p(2:end);
end


function s = symbmonom(names,monom)
s = '';
for j = 1:length(monom)
    if abs( monom(j))>0
        if isempty(names{j})
            names{j} = ['internal(' num2str(j) ')'];
        end
        s = [s '*' names{j}];
        if monom(j)~=1
            s = [s '^' num2str(monom(j))];
        end
    end
end

function s = symbmonom_noncommuting(names,monom)
s = '';
j = 1;
while j <= length(monom)
    if abs( monom(j))>0
        if isempty(names{monom(j)})
            names{monom(j)} = ['internal(' num2str(j) ')'];
        end
        s = [s '*' names{monom(j)}];
        power = 1; 
        k = j;
        while j<length(monom) & monom(j) == monom(j+1)
            power = power + 1;
            j = j + 1;
            %if j == (length(monom)-1)
            %    j = 5;
            %end
        end
        if power~=1
            s = [s '^' num2str(power)];
        end
    end
    j = j + 1;
end

function s = num2str2(x,precision)
if isinf(precision) 
    if isreal(x)
        s = sprintf('%.12g',x);
    else
        s = sprintf('%.12g+%.12gi',real(x),imag(x));
    end
else  
    if isreal(x)
        s = sprintf('%.12g',round(x*10^precision)/10^precision);
    else
        s = sprintf('%.12g+%.12gi',round(real(x)*10^precision)/10^precision,round(imag(x)*10^precision)/10^precision);
    end
end
s(s==10)=[];
s(s==32)=[];


