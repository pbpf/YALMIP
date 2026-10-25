function sys = sdpvar(varargin)
%SDPVAR Create symbolic decision variable (session-based)
%
%   Since the stateless refactoring, variables are created through a
%   session object which owns the variable registry:
%
%       S = yalmip.Session();
%       x = S.sdpvar(3,1);                % Full 3x1
%       x = S.sdpvar("x",3,1);            % With display name
%       P = S.sdpvar(3,3,'symmetric');    % Symmetric 3x3
%       u = S.intvar(2,2);                % Integer (see INTVAR)
%
%   The optional display name (a char/string first argument) is used by
%   SDISPLAY instead of workspace introspection.
%
%   This file retains the internal fast-path constructors used by the
%   operator overloads; they append an optional trailing session argument
%   which is copied into the result.
%
%   See also yalmip.Session, INTVAR, BINVAR, methods('sdpvar')

superiorto('double');

if nargin==0
    error('YALMIP:sessionRequired','Create variables via a session: S = yalmip.Session(); x = S.sdpvar(3,1).')
end

if isstruct(varargin{1})
    sys = class(varargin{1},'sdpvar');
    return
end

% Internal creation pathway used by yalmip.Session methods and the
% dispatcher: the session handle travels in a cell so that this plain
% function call does not dispatch back to a Session method.
if nargin >= 2 && isequal(varargin{end-1},'session') && iscell(varargin{end})
    S = varargin{end}{1};
    args = varargin(1:end-2);
    varargin = args;
    if S.gemInPath()
        try
            superiorto('sgem');
            superiorto('gem');
        catch
        end
    end
    displayname = '';
    if ischar(varargin{1}) || isstring(varargin{1})
        displayname = char(varargin{1});
        varargin = varargin(2:end);
        if isempty(varargin)
            error('YALMIP:sessionRequired','Give the shape after the display name, e.g. S.sdpvar("x",3).')
        end
    end
% Quick cell-based only for real full/symmetric matrices, so just
% iteratively call sdpvarCore to generate all cells
if length(varargin{1}) > 1 && numel(varargin) <= 4 && numel(varargin) > 2
    if  (numel(varargin) >= 3 && (isequal('toeplitz',varargin{3}) || isequal('hankel',varargin{3})))
        n = varargin{1};
        m = varargin{2};
        structure = varargin{3};
        if numel(varargin) == 3
            field = 'real';
        else
            field = varargin{4};
        end
        for i = 1:length(varargin{1})
            sys{i} = sdpvarCore(S, n(i),m(i),structure,field);
        end
        return
    end
end

% To speed up dualization, we keep track of primal SDP cones
% [0 0] :  Nothing known (cleared in some operator, or none-cone to start with)
% [1 0] :  Primal cone
% [i 0] :  Hermitian cone
% [1 1] :  Primal cone + DOUBLE
% [1 2 x] :  Primal cone + SDPVAR
% [-1 1] : -Primal cone + DOUBLE
% [-1 2 x] : -Primal cone + SDPVAR

conicinfo = [0 0];

% *************************************************************************
% Maybe new NDSDPVAR syntax
% *************************************************************************
if numel(varargin) > 2
    if isa(varargin{3},'double') && ~isempty(varargin{3})
        sys = ndsdpvarCore(S, varargin{:});
        return
    end
end

% Supported matrix types
% - symm
% - full
% - skew
% - hank
% - toep
switch numel(varargin)
    case 1
        if isempty(varargin{1})
            sys = varargin{1};
            return
        end
        if isa(varargin{1},'sdpvar')
            sys = varargin{1};
            sys.typeflag = 0;
            return
        end
        n = varargin{1};
        m = varargin{1};
        if sum(n.*m)==0
            sys = zeros(n,m);
            return
        end
        if (n==m)
            matrix_type = 'symmetric';
            nvar = sum(n.*(n+1)/2);
            conicinfo = [1 0];
        else
            matrix_type = 'full';
            nvar = sum(n.*m);
            conicinfo = [-1 0];
        end
    case 2
        n = varargin{1};
        m = varargin{2};
        if length(n)~=length(m)
            error('The dimensions must have the same lengths')
        end
        if sum(n.*m)==0
            sys = zeros(n,m);
            return
        end
        if (n==m)
            matrix_type = 'symmetric';
            nvar = sum(n.*(n+1)/2);
            conicinfo = [1 0];
        else
            matrix_type = 'full';
            nvar = sum(n.*m);
            conicinfo = [-1 0];
        end
    case {3,4}
        n = varargin{1};
        m = varargin{2};
        if sum(n.*m)==0
            sys = zeros(n,m);
            return
        end

        % Check for complex or real
        if (numel(varargin) == 4)
            if isempty(varargin{4})
                varargin{4} = 'real';
            else
                if ~ischar(varargin{4})
                    help sdpvarCore
                    error('Fourth argument should be ''complex'' or ''real''')
                end
            end
            index_cmrl = strmatch_octavesafe(varargin{4},{'real','complex'});
            if isempty(index_cmrl)
                error('Fourth argument should be ''complex'' or ''real''. See help above')
            end
        else
            if ~ischar(varargin{3})
                help sdpvarCore
                error('Third argument should be ''symmetric'', ''full'', ''hermitian'',...See help above')
            end
            index_cmrl = 1;
        end;

        if isempty(varargin{3})
            if n==m
                index_type = 7; %Default symmetric
            else
                index_type = 4;
            end
        else
            if ~isempty(strmatch_octavesafe(varargin{3},{'complex','real'}))
                % User had third argument as complex or real
                error(['Third argument should be ''symmetric'', ''full'', ''toeplitz''... Maybe you meant S.sdpvar(n,n,''full'',''' varargin{3} ''')'])
            end
            index_type = strmatch_octavesafe(varargin{3},{'toeplitz','hankel','symmetric','full','rhankel','skew','hermitian','diagonal'});
        end

        if isempty(index_type)
            error(['Matrix type "' varargin{3} '" not supported'])
        else
            switch index_type+100*(index_cmrl-1)
                case 1
                    if n~=m
                        error('Toeplitz matrix must be square')
                    else
                        matrix_type = 'toeplitz';
                        nvar = n;
                    end

                case 2
                    if n~=m
                        error('Hankel matrix must be square')
                    else
                        matrix_type = 'hankel';
                        nvar = n;
                    end

                case 3
                    if n~=m
                        error('Symmetric matrix must be square')
                    else
                        matrix_type = 'symmetric';
                        nvar = sum(n.*(n+1)/2);
                        conicinfo = [1 0];
                    end

                case 4
                    matrix_type = 'full';
                    nvar = sum(n.*m);
                    conicinfo = [-1 0];
                    if nvar==1
                        matrix_type = 'symmetric';
                        conicinfo = [1 0];
                    end

                case 5
                    if n~=m
                        error('Hankel matrix must be square')
                    else
                        matrix_type = 'rhankel';
                        nvar = 2*n-1;
                    end

                case 6
                    if n~=m
                        error('Skew symmetric matrix must be square')
                    else
                        matrix_type = 'skew';
                        nvar = sum((n.*(n+1)/2)-n);
                    end

                case 7
                    if n~=m
                        error('Symmetric matrix must be square')
                    else
                        matrix_type = 'symmetric';
                        nvar = sum(n.*(n+1)/2);
                    end


                case 8
                    if n~=m
                        error('Diagonal matrix must be square')
                    else
                        matrix_type = 'diagonal';
                        nvar = n;
                    end

                case 101
                    if n~=m
                        error('Toeplitz matrix must be square')
                    else
                        matrix_type = 'toeplitz complex';
                        nvar = 2*n;
                    end

                case 102
                    if n~=m
                        error('Hankel matrix must be square')
                    else
                        matrix_type = 'hankel complex';
                        nvar = (2*n);
                    end

                case 103
                    if n~=m
                        error('Symmetric matrix must be square')
                    else
                        matrix_type = 'symm complex';
                        nvar = sum(2*n.*(n+1)/2);
                    end

                case 104
                    matrix_type = 'full complex';
                    nvar = 2*sum(n.*m);
                    if nvar==1
                        matrix_type = 'symm complex';
                    end

                case 105
                    if n~=m
                        error('Hankel matrix must be square')
                    else
                        matrix_type = 'rhankel complex';
                        nvar = 2*(2*n-1);
                    end

                case 106
                    if n~=m
                        error('Skew symmetric matrix must be square')
                    else
                        matrix_type = 'skew complex';
                        nvar = 2*((n*(n+1)/2)-n);
                    end

                case 107
                    if n~=m
                        error('Hermitian matrix must be square')
                    else
                        matrix_type = 'hermitian complex';
                        nvar = sum(n.*(n+1)/2+(n.*(n+1)/2-n));
                        conicinfo = [sqrt(-1) 0];
                    end

                otherwise
                    error('Bug! Report!');
            end

        end

    otherwise
        error('Wrong number of arguments in sdpvar creation');
end

if isempty(n) || isempty(m)
    error('Size must be integer valued')
end;
if ~((abs((n-ceil(n)))+ abs((m-ceil(m))))==0)
    error('Size must be integer valued')
end

[mt,variabletype,hashed_monoms,current_hash] = S.getMonomtable();
lmi_variables = (1:nvar)+size(mt,1);

for blk = 1:length(n)
    switch matrix_type

        case 'full'
            basis{blk} = [spalloc(n(blk)*m(blk),1,0) speye(n(blk)*m(blk))];%speye(nvar)];

        case 'full complex'
            basis{blk} = [spalloc(n(blk)*m(blk),1,0) speye(n(blk)*m(blk)) speye(n(blk)*m(blk))*sqrt(-1)];

        case 'symmetric'
            if n(blk)==1
                basis{blk} = sparse([0 1]);
            else
                % Hrm...fast but completely f*d up
                % Resuse old basis
                if blk > 1 && n(blk) == n(blk-1)
                    basis{blk} = basis{blk-1};
                else
                    basis{blk} = lmiBasis(n(blk));
                end
            end

        case 'symm complex'
            nvari = 2*n(blk)*(n(blk)+1)/2;
            tbasis = spalloc(n(blk)^2,1+nvari,2);
            l = 2;
            an_empty = spalloc(n(blk),n(blk),2);
            for i=1:n(blk)
                temp = an_empty;
                temp(i,i)=1;
                tbasis(:,l)=temp(:);
                l = l+1;
                for j=i+1:n(blk),
                    temp = an_empty;
                    temp(i,j)=1;
                    temp(j,i)=1;
                    tbasis(:,l)=temp(:);
                    l = l+1;
                end
            end
            for i=1:n(blk)
                temp = an_empty;
                temp(i,i)=sqrt(-1);
                tbasis(:,l)=temp(:);
                l = l+1;
                for j=i+1:n(blk),
                    temp = an_empty;
                    temp(i,j)=sqrt(-1);
                    temp(j,i)=sqrt(-1);
                    tbasis(:,l)=temp(:);
                    l = l+1;
                end
            end
            basis{blk} = tbasis;

        case 'hermitian complex'
            if blk > 1 && any(n(blk)==n(1:blk-1))
                j = max((find(n(blk)==n(1:blk-1))));
                basis{blk} = basis{j};
            else
                nvari = n(blk)*(n(blk)+1)/2+(n(blk)*(n(blk)+1)/2-n(blk));
                tbasis = spalloc(n(blk)^2,1+nvari,2);
                l = 2;
                an_empty = spalloc(n(blk),n(blk),2);
                Y = reshape(1:n(blk)^2,n(blk),n(blk));
                Y = tril(Y);
                Y = (Y+Y')-diag(sparse(diag(Y)));
                [uu,oo,pp] = unique(Y(:));
                BasisReal = sparse(1:n(blk)^2,pp+1,1);

                % Remove diagonal, flip signs, and complexify
                BasisImag = BasisReal;
                BasisImag(:,1) = [];
                index = [1];
                for i = 1:n(blk)-1
                    index = [index index(end)+n(blk)-i+1];
                end
                BasisImag(:,index) = [];
                [i,j,s] = find(BasisImag);
                s(1:2:end)=-1;
                BasisImag = sparse(i,j,s*sqrt(-1),size(BasisImag,1),size(BasisImag,2));

                tbasis = [BasisReal BasisImag];
                basis{blk} = tbasis;
            end
        case 'skew'
            if n(blk)==1
                sys = 0;
                return
            end
            if blk > 1 && n(blk) == n(blk-1)
                basis{blk} = basis{blk-1};
            else
                tbasis = spalloc(n(blk)^2,1+(n(blk)*(n(blk)+1)/2)-n(blk),2);
                l = 2;
                an_empty = spalloc(n(blk),n(blk),2);
                for i=1:n(blk)
                    for j=i+1:n(blk),
                        temp = an_empty;
                        temp(i,j)=1;
                        temp(j,i)=-1;
                        tbasis(:,l)=temp(:);
                        l = l+1;
                    end
                end
                basis{blk} = tbasis;
            end

        case 'skew complex'
            if n==1
                sys = sdpvarCore(S, 1,1)*sqrt(-1);
                return
            else
                basis = spalloc(n^2,1+nvar,2);
                l = 2;
                an_empty = spalloc(n,n,2);
                for i=1:n
                    for j=i+1:n,
                        temp = an_empty;
                        temp(i,j)=1;
                        temp(j,i)=-1;
                        basis(:,l)=temp(:);
                        l = l+1;
                    end
                end
                for i=1:n
                    for j=i+1:n,
                        temp = an_empty;
                        temp(i,j)=sqrt(-1);
                        temp(j,i)=-sqrt(-1);
                        basis(:,l)=temp(:);
                        l = l+1;
                    end
                end
            end

        case 'toeplitz'
            basis = [spalloc(n(blk)*1,1,0) speye(n(blk)*1)];

            % Notice, complex Toeplitz not Hermitian
        case 'toeplitz complex'
            basis = spalloc(n^2,1+nvar,2);
            an_empty = spalloc(n,1,1);
            for i=1:n,
                v = an_empty;
                v(i)=1;
                temp = sparse(toeplitz(v));
                basis(:,i+1) = temp(:);
            end
            for i=1:n,
                v = an_empty;
                v(i)=sqrt(-1);
                temp = sparse(toeplitz(v));
                basis(:,n+i+1) = temp(:);
            end

        case 'hankel'
            % Create a vector. We will hankelize it later
            basis = [spalloc(n(blk)*1,1,0) speye(n(blk)*1)];

        case 'diagonal'
            j = 2:n+1;
            i = 1:n+1:n^2;
            basis = sparse(i,j,ones(length(i),1),n^2,1+n);

        case 'hankel complex'
            basis = spalloc(n^2,1+nvar,2);
            an_empty = spalloc(n,1,1);
            for i=1:n,
                v = an_empty;
                v(i)=1;
                temp = sparse(hankel(v));
                basis(:,i+1) = temp(:);
            end
            for i=1:n,
                v = an_empty;
                v(i)=sqrt(-1);
                temp = sparse(hankel(v));
                basis(:,n+i+1) = temp(:);
            end

        case 'rhankel'
            basis = spalloc(n^2,1+nvar,2);
            an_empty = spalloc(2*n-1,1,1);
            for i=1:nvar,
                v = an_empty;
                v(i)=1;
                temp = sparse(hankel(v(1:n),[v(n);v(n+1:2*n-1)]));
                basis(:,i+1) = temp(:);
            end

        case 'rhankel complex'
            basis = spalloc(n^2,1+nvar,2);
            an_empty = spalloc(2*n-1,1,1);
            for i=1:nvar/2,
                v = an_empty;
                v(i)=1;
                temp = sparse(hankel(v(1:n),[v(n);v(n+1:2*n-1)]));
                basis(:,i+1) = temp(:);
            end
            for i=1:nvar/2,
                v = an_empty;
                v(i)=sqrt(-1);
                temp = sparse(hankel(v(1:n),[v(n);v(n+1:2*n-1)]));
                basis(:,nvar/2+i+1) = temp(:);
            end

        otherwise
            error('Bug! Report')
    end

end

appendYALMIPvariables(S,lmi_variables,mt,variabletype,hashed_monoms,current_hash);

% Register the display name (used by sdisplay instead of workspace sniffing)
if ~isempty(displayname)
    S.registerVariablenames(displayname, lmi_variables);
end

% Create an object
if isa(basis,'cell')
    top = 1;
    for blk = 1:length(n)
        sys{blk}.basis=basis{blk};
        nn = size(sys{blk}.basis,2)-1;
        sys{blk}.lmi_variables = lmi_variables(top:top+nn-1);
        top = top + nn;
        sys{blk}.dim(1) = n(blk);
        sys{blk}.dim(2) = m(blk);
        sys{blk}.typeflag = 0;
        sys{blk}.savedata = [];
        sys{blk}.extra = [];
        sys{blk}.extra.expanded = [];
        sys{blk}.extra.opname = '';
        sys{blk}.extra.createTime = definecreationtime;
        sys{blk}.conicinfo = conicinfo;
        sys{blk}.originalbasis = matrix_type;
        sys{blk}.sess = S;
        sys{blk}.name = displayname;
        sys{blk} = class(sys{blk},'sdpvar');
    end
    if length(n)==1
        sys = sys{1};
    end
else
    sys.basis=basis;
    sys.lmi_variables = lmi_variables;
    sys.dim(1) = n;
    sys.dim(2) = m;
    sys.typeflag = 0;
    sys.savedata = [];
    sys.extra = [];
    sys.extra.expanded = [];
    sys.extra.opname = '';
    sys.extra.createTime = definecreationtime;
    sys.conicinfo = conicinfo;
    sys.originalbasis = matrix_type;
    sys.sess = S;
    sys.name = displayname;
    sys = class(sys,'sdpvar');
    if isequal(matrix_type,'hankel')
        % To speed up generation, we have just created a vector, and now
        % hankelize it
        sys.dim(2) = 1;
        sys = hankel(sys);
    elseif isequal(matrix_type,'toeplitz')
        sys.dim(2) = 1;
        sys = toeplitz(sys);
    end
en
    end
    return
end

% 1-argument copy/convert paths used internally by operator overloads
if nargin==1
    if isa(varargin{1},'sdpvar')
        sys = varargin{1};
        sys.typeflag = 0;
        return
    end
    if isempty(varargin{1})
        sys = varargin{1};
        return
    end
    error('YALMIP:sessionRequired',['Create variables via a session: S = yalmip.Session(); x = S.sdpvar(' num2str(varargin{1}) ').'])
end

% Internal fast paths (5 to 9 arguments). An optional trailing session
% argument is stored in the result so that the session travels with every
% symbolic object created during operator evaluation.
if nargin >= 5
    if isa(varargin{end},'yalmip.Session')
        sess = varargin{end};
        varargs = varargin(1:end-1);
    else
        sess = [];
        varargs = varargin;
    end
    switch numel(varargs)
        case 5 % Fast version for internal use
            sys.basis = varargs{5};
            sys.lmi_variables=varargs{4};
            sys.dim(1) = varargs{1};
            sys.dim(2) = varargs{2};
            sys.typeflag = 0;
            sys.savedata = [];
            sys.extra = [];
            sys.extra.expanded = [];
            sys.extra.opname = '';
            sys.extra.createTime = definecreationtime;
            sys.conicinfo = 0;
            sys.originalbasis = 'unknown';
        case 6 % Fast version for internal use
            sys.basis = varargs{5};
            sys.lmi_variables=varargs{4};
            sys.dim(1) = varargs{1};
            sys.dim(2) = varargs{2};
            sys.typeflag = varargs{6};
            sys.savedata = [];
            sys.extra = [];
            sys.extra.expanded = [];
            sys.extra.opname = '';
            sys.extra.createTime = definecreationtime;
            sys.conicinfo = 0;
            sys.originalbasis = 'unknown';
        case 7 % Fast version for internal use
            sys.basis = varargs{5};
            sys.lmi_variables=varargs{4};
            sys.dim(1) = varargs{1};
            sys.dim(2) = varargs{2};
            sys.typeflag = varargs{6};
            sys.savedata = [];
            sys.extra = varargs{7};
            sys.extra.expanded = [];
            sys.extra.opname = '';
            sys.extra.createTime = '';
            sys.conicinfo = varargs{7};
            sys.originalbasis = 'unknown';
        case 8
            sys = varargs{8};
        otherwise
            error('Wrong number of arguments in sdpvar creation');
    end
    sys.sess = sess;
    if ~isfield(sys,'name')
        sys.name = '';
    end
    % Find zero-variables (not applicable for the struct-passthrough case 8)
    if numel(varargs) ~= 8
        constants = find(sys.lmi_variables==0);
        if ~isempty(constants);
            sys.lmi_variables(constants)=[];
            sys.basis(:,1) = sys.basis(:,1) + sum(sys.basis(:,1+constants),2);
            sys.basis(:,1+constants)=[];
        end
    end
    if isempty(sys.lmi_variables)
        sys = full(reshape(sys.basis(:,1),sys.dim(1),sys.dim(2)));
    else
        sys = class(sys,'sdpvar');
    end
    return
end

% All user-facing creation (1-4 arguments) requires a session.
error('YALMIP:sessionRequired','Create variables via a session: S = yalmip.Session(); x = S.sdpvar(3,1).')
