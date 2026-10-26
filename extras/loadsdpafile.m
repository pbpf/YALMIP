function [F,h,S] = loadsdpafile(varargin)
%LOADSDPAFILE Loads a problem definition in the SDPA format
%
%    [F,h] = loadsdpafile('filename')  Loads the problem min(h(x)), F(x)>0 from file 'filename'
%    [F,h] = loadsdpafile         A "Open" - box will be opened
%
%    [F,h,S] = loadsdpafile('filename',S) loads into the given session;
%    without one, a fresh session is created and returned as the third output.

if numel(varargin) > 1 && isa(varargin{2},'yalmip.Session')
    S = varargin{2};
else
    S = yalmip.Session();
end

filename = varargin{1};

% Does the file exist
if ~exist(filename)
    filename = [filename '.dat-s'];
    if ~exist(filename)
        error(['No such file.']);
    end
end
    
% Load using SeDuMi
try    
    [At,b,c,K] = fromsdpa(filename);
    fid = fopen(filename, 'r');
    % Ugly code to find the integer data...
    tline = fgetl(fid);
    found = 0;
    integers = [];
    while ischar(tline) && ~found
        if isequal(strtrim(tline),'*INTEGERS*') || isequal(strtrim(tline),'*INTEGER')
            found = 1;
        end
        tline = fgetl(fid);
    end
    if found        
        while ischar(tline)
            integers = [integers str2num(tline(2:end))];
            tline = fgetl(fid);
        end
    end  
    fclose(fid);
catch ME
    error('LOADSDPAFILE requires SeDuMi (fromsdpa.m and its conversion/ subfolder) on the MATLAB path. Underlying error: %s', ME.message);
end

nvars = length(b);
x = S.sdpvar(nvars,1);

F = ([]);
if ~isempty(integers)
    F = [F, integer(x(integers))];
end
top = 1;
if isfield(K,'l')
    if K.l(1)>0
        X = c(top:top+K.l-1)-At(top:top+K.l-1,:)*x;
        F = F + (X(:)>=0);
        top = top + K.l;
    end
end

if isfield(K,'s')
    if any(K.s)
        for i = 1:length(K.s)
            [ix,iy,iv] = find([c(top:top+K.s(i)^2-1) At(top:top+K.s(i)^2-1,:)]);
            off = (ix-1)/(K.s(i)+1);
            if all(off == round(off))           
                X = c(top:top+K.s(i)^2-1)-At(top:top+K.s(i)^2-1,:)*x;
                F = F + (diag(reshape(X,K.s(i),K.s(i))) >= 0);
                top = top + K.s(i)^2;
            else
                X = c(top:top+K.s(i)^2-1)-At(top:top+K.s(i)^2-1,:)*x;
                F = F + (reshape(X,K.s(i),K.s(i)) >= 0);
                top = top + K.s(i)^2;
            end
        end
    end
end

h = -b'*x;

