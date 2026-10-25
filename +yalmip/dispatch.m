function varargout = dispatch(S, varargin)
%DISPATCH Session-state command implementation (former yalmip.m switch).
%
%   Pure function over the session handle S: no global or persistent
%   state. Session methods delegate here, preserving the original
%   dispatcher argument conventions (varargin{1} = command string).

switch varargin{1}
    
    case 'clearsolution'
        S.optSolution{1}.variables = [];
        S.optSolution{1}.optvar  =[];
        S.optSolution{1}.values  =[];
        S.activeSolution = 1;
        S.tempintVariables = [];   
        S.tempbinVariables = [];   
        S.intVariables = [];   
        S.binVariables = [];   
        
    case 'monomtable'
        varargout{1} = S.monomtable;
        n = size(S.monomtable,1);
        if size(S.monomtable,2) < n
            % Normalize the monomtalbe. Some external functions presume the
            % table is square
            varargout{1}(n,n) = 0;
            S.monomtable = varargout{1};
            need_new = size(S.monomtable,1) - length(S.hash);            
            S.hash = [S.hash ; 3*gen_rand_hash(size(S.monomtable,1),need_new,1)];
            S.hashedmonomtable = S.monomtable*S.hash;
        end
        if nargout == 2
            varargout{2} = S.variabletype;
        elseif nargout == 4
            varargout{2} = S.variabletype;
            varargout{3} = S.hashedmonomtable;
            varargout{4} = S.hash;
        end
        
    case 'setmonomtable'
        % New monom table
        S.monomtable = varargin{2};
        if nargin>=4
            % User has up-dated the hash tables him self.
            S.hashedmonomtable=varargin{4};
            S.hash = varargin{5};
        end
        if size(S.monomtable,2)>length(S.hash)
            need_new = size(S.monomtable,1) - length(S.hash);
            S.hash = [S.hash ; 3*gen_rand_hash(size(S.monomtable,1),need_new,1)];
        end
        if size(S.monomtable,1)>size(S.hashedmonomtable,1)
            % Need to add some hash values
            need_new = size(S.monomtable,1) - size(S.hashedmonomtable,1);
            temp = S.monomtable(end-need_new+1:end,:);
            S.hashedmonomtable = [S.hashedmonomtable;temp*S.hash];
        end
        if nargin >= 3 && ~isempty(varargin{3})
            S.variabletype = varargin{3};
            if length(S.variabletype) ~=size(S.monomtable,1)
                error('ASSERT')
            end
        else
            S.variabletype = zeros(size(S.monomtable,1),1)';
            nonlinear = ~(sum(S.monomtable,2)==1 & sum(S.monomtable~=0,2)==1);
            if ~isempty(nonlinear)
                %mt = S.monomtable;
                S.variabletype(nonlinear) = 3;
                quadratic = sum(S.monomtable,2)==2;
                S.variabletype(quadratic) = 2;
                bilinear = max(S.monomtable,[],2)<=1;
                S.variabletype(bilinear & quadratic) = 1;
                signomial = any(0>S.monomtable,2) | any(S.monomtable-fix(S.monomtable),2);
                S.variabletype(signomial) = 4;
            end
        end
        
    case 'variabletype'
        varargout{1} = S.variabletype;
        
    case {'addextendedvariable','addEvalVariable'}
        varargin{2}
        disp('Obsolete use of the terms addextendedvariable and addEvalVariable');
        error('Obsolete use of the terms addextendedvariable and addEvalVariable');
                
    case 'defineVectorizedUnitary'
             
        varargin{2} = strrep(varargin{2},'sdpvar/',''); % Clean due to different behaviour of the function mfilename in ML 5,6 and 7
        
        % Is this operator variable already defined
        correct_operator = [];
        if ~isempty(S.ExtendedMap)
                                              
            OperatorName = varargin{2};
            Arguments = {varargin{3:end}};
            this_hash = create_trivial_hash(firstSDPVAR(Arguments));
            correct_operator = find([S.ExtendedMapHashes == this_hash]);
            
            if ~isempty(correct_operator)
                correct_operator = correct_operator(strcmp(OperatorName,{S.ExtendedMap(correct_operator).fcn}));
            end
                                                                         
            for i = correct_operator                
                if this_hash == S.ExtendedMap(i).Hash
                    if isequaln(Arguments, {S.ExtendedMap(i).arg{1:end-1}});
                        if length(S.ExtendedMap(i).computes)>1
                            varargout{1} =  recover(S.ExtendedMap(i).computes);
                        else
                            varargout{1} =  S.ExtendedMap(i).var;
                        end
                        varargout{1} = setoperatorname(varargout{1},varargin{2});
                        return
                    end
                end
            end
        else
            this_hash = create_trivial_hash(firstSDPVAR({varargin{3:end}}));
        end
        
        X = varargin{3:end};
        if is(X,'unitary')
            allXunitary = 1;
        else
            allXunitary = 0;
        end
        y = sdpvar(numel(X),1,'session',{S});
        allNewExtended = [];
        allNewExtendedIndex = [];
        allPreviouslyDefinedExtendedToIndex = [];
        allPreviouslyDefinedExtendedFromIndex = [];
        if ~isempty(S.ExtendedMap)
            correct_operator = find(strcmp(varargin{2},{S.ExtendedMap(:).fcn}));
        end
                
        z = sdpvar(numel(X),1,'session',{S}); % Standard format     y=f(z),z==arg
        
        S.auxVariables = [ S.auxVariables  getvariables(z)];
        S.auxVariables = [ S.auxVariables  getvariables(y)];
        
        vec_hashes = create_trivial_vechash(X);
        vec_isdoubles = create_vecisdouble(X);
        
        if isempty(correct_operator)
            availableHashes  = [];
        else
            availableHashes = [S.ExtendedMap(correct_operator).Hash];
        end
        
        if isempty(availableHashes) &&  length(vec_hashes)>1 && all(diff(sort(vec_hashes))>0)
            simpleAllDifferentNew = 1;
        else
            simpleAllDifferentNew = 0;
        end
        
        for i = 1:numel(X)
            % we have to search through all scalar operators
            % to find this single element
            found = 0;            
            Xi = [];
            
            if ~simpleAllDifferentNew
                if vec_isdoubles(i)
                    found = 1;
                    y(i) = feval(varargin{2},X(i));
                else
                    if ~isempty(correct_operator)
                        this_hash = vec_hashes(i);
                        correct_hash = correct_operator(find(this_hash == availableHashes));
                        
                        if ~isempty(correct_hash)
                            Xi = X(i);
                        end
                        for j = correct_hash(:)'
                            if isequal(Xi,S.ExtendedMap(j).arg{1},1)
                                allPreviouslyDefinedExtendedToIndex = [allPreviouslyDefinedExtendedToIndex i];
                                allPreviouslyDefinedExtendedFromIndex = [allPreviouslyDefinedExtendedFromIndex j];
                                found = 1;
                                break
                            end
                        end
                    end
                end
            end
            
            if ~found
                if vec_isdoubles(i)                    
                    y(i) = feval(varargin{2},X(i));
                else
                yi = y(i);
                if isempty(Xi)
                     Xi = X(i);
                end
                S.ExtendedMap(end+1).fcn = varargin{2};
                if allXunitary
                     S.ExtendedMap(end).arg = {Xi,[]};
                else
                    if is(Xi,'unitary')
                    S.ExtendedMap(end).arg = {Xi,[]};
                else
                    S.ExtendedMap(end).arg = {Xi,z(i)};
                    end
                end
                S.ExtendedMap(end).var = yi;
                S.ExtendedMap(end).computes = getvariables(yi);
                new_hash = create_trivial_hash(Xi);
                S.ExtendedMap(end).Hash = new_hash;
                S.ExtendedMapHashes = [S.ExtendedMapHashes new_hash];
				S.containsSemivar = S.containsSemivar | strcmp(varargin{2}, 'semivar');
                allNewExtendedIndex = [allNewExtendedIndex i];
                availableHashes = [availableHashes new_hash];
                correct_operator = [correct_operator length( S.ExtendedMap)];
                 end
            end
        end
    
        y(allPreviouslyDefinedExtendedToIndex) = [S.ExtendedMap(allPreviouslyDefinedExtendedFromIndex).var];
        allNewExtended = y(allNewExtendedIndex);
        y_vars = getvariables(allNewExtended);
        S.extVariables = [S.extVariables y_vars];
        y = reshape(y,size(X,1),size(X,2));
        y = setoperatorname(y,varargin{2});
        varargout{1} = y;     

        yV = getvariables(y);
        yB = getbase(y);yB = yB(:,2:end);
        xV = getvariables(X);
        xB = getbase(X);xB = xB(:,2:end);
        %S.DependencyMap(max(yV),max(xV))=sparse(0);
        for i = 1:length(yV)
            ii = yV(find(yB(i,:)));
            jj = xV(find(xB(i,:)));
            S.DependencyMap_i = [S.DependencyMap_i repmat(ii,1,length(jj))];
            S.DependencyMap_j = [S.DependencyMap_j jj(:)'];
          %  S.DependencyMap(yV(find(yB(i,:))),xV(find(xB(i,:))))=1;
        end        
        return
        
        
    case {'define','definemulti'}
        
        if strcmpi(varargin{1},'define')
            multioutput = 0;
            nout = [1 1];
        else
            multioutput = 1;
            nout = varargin{end};
            varargin = {varargin{1:end-1}};            
        end
        
        for i = 1:length(varargin)
            if isa(varargin{i},'sdpvar')
                varargin{i} = clearcreationtime(varargin{i});
                varargin{i} = clearconicinfo(varargin{i});
            end
        end
        
        varargin{2} = strrep(varargin{2},'sdpvar/',''); % Clean due to different behaviour of the function mfilename in ML 5,6 and 7
        
        % Is this operator variable already defined
        correct_operator = [];
        if ~isempty(S.ExtendedMap)
                                              
            OperatorName = varargin{2};
            Arguments = {varargin{3:end}};
            this_hash = create_trivial_hash(firstSDPVAR(Arguments));
            correct_operator = find([S.ExtendedMapHashes == this_hash]);
            
            if ~isempty(correct_operator)
                correct_operator = correct_operator(strcmp(OperatorName,{S.ExtendedMap(correct_operator).fcn}));
            end
                                                                         
            for i = correct_operator
                if isequaln(Arguments, {S.ExtendedMap(i).arg{1:end-1}});
                    if length(S.ExtendedMap(i).computes)>1
                        varargout{1} =  recover(S.ExtendedMap(i).computes);
                    else
                        varargout{1} =  S.ExtendedMap(i).var;
                    end
                    varargout{1} = setoperatorname(varargout{1},varargin{2});
                    return
                end
            end
        else
            this_hash = create_trivial_hash(firstSDPVAR({varargin{3:end}}));
        end
        
        switch varargin{2}
            
            case {'max_internal'}
                % MAX is a bit special since we need one
                % new variable for each column...
                % (can be implemented standard way, but this is better
                % for performance, and since MAX is so common...
                X = varargin{3:end};
                [n,m] = size(X);
                if min([n m]) == 1
                    y = sdpvar(1,1,'session',{S});
                    S.ExtendedMap(end+1).fcn = varargin{2};
                    S.ExtendedMap(end).arg = {varargin{3:end},[]};
                    S.ExtendedMap(end).var = y;
                    S.ExtendedMap(end).computes = getvariables(y);
                    S.extVariables = [S.extVariables getvariables(y)];
                    S.ExtendedMap(end).Hash = this_hash;
                    S.ExtendedMapHashes = [S.ExtendedMapHashes this_hash];
                else
                    y = sdpvar(1,m,'session',{S});
                    for i = 1:m
                        if isa(X(:,i),'double')
                            y(i) = max(X(:,i));
                        else
                            S.ExtendedMap(end+1).fcn = varargin{2};
                            S.ExtendedMap(end).arg = {X(:,i),[]};
                            S.ExtendedMap(end).var = y(i);
                            S.ExtendedMap(end).computes = getvariables(y(i));
                            new_hash = create_trivial_hash(X(:,i));
                            S.ExtendedMap(end).Hash = new_hash;
                            S.ExtendedMapHashes = [S.ExtendedMapHashes new_hash];
                        end
                    end
                    S.extVariables = [S.extVariables getvariables(y)];
                end
                y = setoperatorname(y,varargin{2});
                
            case {'abs'}
                % ABS is a bit special since we need one
                % new variable for each element...
                X = varargin{3:end};
                y = sdpvar(numel(X),1,'session',{S});
                allNewExtended = [];
                allNewExtendedIndex = [];
                allPreviouslyDefinedExtendedToIndex = [];
                allPreviouslyDefinedExtendedFromIndex = [];
                if ~isempty(S.ExtendedMap)
                    correct_operator = find(strcmp(varargin{2},{S.ExtendedMap(:).fcn}));
                end
                if numel(X)==1
                    found = 0;
                    if ~isempty(correct_operator)
                        this_hash = create_trivial_hash(X);
                        for j = correct_operator;% find(correct_operator)
                            if this_hash == S.ExtendedMap(j).Hash
                                if isequal(X,S.ExtendedMap(j).arg{1},1)
                                    %  y = S.ExtendedMap(j).var;
                                    allPreviouslyDefinedExtendedToIndex = [1];
                                    allPreviouslyDefinedExtendedFromIndex = [j];
                                    found = 1;
                                    break
                                end
                            end
                        end
                    end
                    if ~found
                        S.ExtendedMap(end+1).fcn = varargin{2};
                        S.ExtendedMap(end).arg = {X,binvarCore(S, 1),[]};
                        S.ExtendedMap(end).var = y;
                        S.ExtendedMap(end).computes = getvariables(y);
                        new_hash = create_trivial_hash(X);
                        S.ExtendedMap(end).Hash = new_hash;
                        S.ExtendedMapHashes = [S.ExtendedMapHashes new_hash];
                        allNewExtended = y;
                        allNewExtendedIndex = 1;
                    end
                else
                    aux_bin = binvarCore(S, numel(X),1);
                    vec_hashes = create_trivial_vechash(X);
                    vec_isdoubles = create_vecisdouble(X);
                    for i = 1:numel(X)
                        % This is a bummer. If we scalarize the abs-operator,
                        % we have to search through all scalar abs-operators
                        % to find this single element
                        found = 0;
                        Xi = X(i);
                        if vec_isdoubles(i)%isa(Xi,'double')
                            found = 1;
                            y(i) = abs(X(i));
                        else
                            if ~isempty(correct_operator)
                                this_hash = vec_hashes(i);                                
                                j = correct_operator(find(this_hash == S.ExtendedMapHashes(correct_operator)));
                                if ~isempty(j)
                                    for matches = 1:length(j)
                                        if isequal(Xi,S.ExtendedMap(j(matches)).arg{1},1)
                                            allPreviouslyDefinedExtendedToIndex = [allPreviouslyDefinedExtendedToIndex i];
                                            allPreviouslyDefinedExtendedFromIndex = [allPreviouslyDefinedExtendedFromIndex j];
                                            found = 1;                                        
                                            break
                                        end    
                                    end
                                end
                            end
                        end
                        if ~found
                            yi = y(i);
                            S.ExtendedMap(end+1).fcn = varargin{2};
                            S.ExtendedMap(end).arg = {Xi,aux_bin(i),[]};
                            S.ExtendedMap(end).var = yi;
                            S.ExtendedMap(end).computes = getvariables(yi);
                            new_hash = create_trivial_hash(Xi);
                            S.ExtendedMap(end).Hash = new_hash;
                            S.ExtendedMapHashes = [S.ExtendedMapHashes new_hash];
                            allNewExtendedIndex = [allNewExtendedIndex i];
                            % Add this to the list of possible matches.
                            % Required for repeated elements in argument
                            % (such as a symmetric matrix)
                            correct_operator = [correct_operator length(S.ExtendedMap)];
                        end
                    end
                end
                y(allPreviouslyDefinedExtendedToIndex) = [S.ExtendedMap(allPreviouslyDefinedExtendedFromIndex).var];
                allNewExtended = y(allNewExtendedIndex);
                y_vars = getvariables(allNewExtended);
                S.extVariables = [S.extVariables y_vars];
                y = reshape(y,size(X,1),size(X,2));
                y = setoperatorname(y,varargin{2});
                                
            otherwise
                % This is the standard operators. INPUTS -> 1 scalar output
                if isequal(varargin{2},'or') || isequal(varargin{2},'xor') || isequal(varargin{2},'and') || isequal(varargin{2},'not')
                    y = binvarCore(S, 1,1);
                elseif isequal(varargin{2},'sign')
                    y = intvarCore(S, nout(1),nout(2));
                else
                    y = sdpvar(nout(1),nout(2),'session',{S});
                end
                if ~strcmpi({'sort'},varargin{2})
                    % Oh fuck is this ugly. Sort assumes ordering on some
                    % variables, and thus assumes no z in between. This
                    % will be generalized when R^n -> R^m is supported for
                    % real
                    
                    % Actually, we can skip these normalizing variables for
                    % everything which isn't based on callbacks. This saves
                    % a lot of setup time on huge models
                    if ~(strcmp(varargin{2},'norm') || strcmp(varargin{2},'abs'))
                        z = sdpvar(size(varargin{3},1),size(varargin{3},2),'full','session',{S}); % Standard format     y=f(z),z==arg
                        S.auxVariables = [ S.auxVariables  getvariables(z)];
                    else
                        z = [];
                    end
                    S.auxVariables = [ S.auxVariables  getvariables(y)];
                else
                    z = [];
                end
                for i = 1:prod(nout)
                    % Avoid subsref to save time
                    if prod(nout) == 1
                        yi = y;
                    else
                        yi = y(i);
                    end                
                    S.ExtendedMap(end+1).fcn = varargin{2};
                    S.ExtendedMap(end).arg = {varargin{3:end},z};
                    S.ExtendedMap(end).var = yi;
                    S.ExtendedMap(end).computes = getvariables(y);
                    S.ExtendedMap(end).Hash = this_hash;
                    S.ExtendedMapHashes = [S.ExtendedMapHashes this_hash];
                    S.extVariables = [S.extVariables getvariables(yi)];
					S.containsSemivar = S.containsSemivar | strcmp(varargin{2}, 'semivar');
                end
                y = setoperatorname(y,varargin{2});
        end
        for i = 3:length(varargin)
            if isa(varargin{i},'sdpvar')
                yalmip.dispatch(S,'setdependence',getvariables(y),getvariables(varargin{i}));
            end
        end        
        varargout{1} = clearconic(y);
        return
        
    case 'setdependence'
        if ~isempty(varargin{2}) && ~isempty(varargin{3})
            if isa(varargin{2},'sdpvar')
                varargin{2} = getvariables(varargin{2});
            end
            if isa(varargin{3},'sdpvar')
                varargin{3} = getvariables(varargin{3});
            end
            % This dies not work since the arguments have different
            % ordering. Try for instance x=sdpvar(2),[x>=0,abs(x)>=0]
            % nx = max(size(S.DependencyMap,1),max(varargin{2}));
            % ny = max(size(S.DependencyMap,2),max(varargin{3}));
            % index = sub2ind([nx ny], varargin{2},varargin{3});
            % if size(S.DependencyMap,1) < nx || size(S.DependencyMap,2) < ny
            %     S.DependencyMap(nx,ny) = 0;
            % end
            
            temp1 = repmat(varargin{2},size(varargin{3},2),1);temp1 = temp1(:)';
            temp2 = repmat(varargin{3},1,size(varargin{2},2));temp2 = temp2(:)';
           
            S.DependencyMap_i = [S.DependencyMap_i temp1];
            S.DependencyMap_j = [S.DependencyMap_j temp2];
            
            n = size(S.monomtable,1);
            if size(S.DependencyMap,1) < n
                S.DependencyMap(n,1)=0;
            end
            if size(S.DependencyMap,2) < n
                S.DependencyMap(end,n)=0;
            end
        end
        
    case 'setdependenceUser'
        if ~isempty(varargin{2}) && ~isempty(varargin{3})
            if isa(varargin{2},'sdpvar')
                varargin{2} = getvariables(varargin{2});
            end
            if isa(varargin{3},'sdpvar')
                varargin{3} = getvariables(varargin{3});
            end
            S.DependencyMapUser(varargin{2},varargin{3}) = 1;
            n = size(S.monomtable,1);
            if size(S.DependencyMapUser,1) < n
                S.DependencyMapUser(n,1)=0;
            end
            if size(S.DependencyMapUser,2) < n
                S.DependencyMapUser(end,n)=0;
            end
        end
        
    case 'getdependence'
        %varargout{1} =   S.DependencyMap;
        if isempty(S.DependencyMap_i)
            varargout{1} = sparse(0);
        else
            try
                varargout{1} = sparse(S.DependencyMap_i,S.DependencyMap_j,1);
            catch
                1
            end
        end
        n =  size(S.monomtable,1);
        if size(varargout{1},1) < n || size(varargout{1},2)<n
            varargout{1}(n,n) = 0;
        end
        
    case 'getdependenceUser'
        varargout{1} =   S.DependencyMapUser;
        n =  size(S.monomtable,1);
        if size(varargout{1},1) < n || size(varargout{1},2)<n
            varargout{1}(n,n) = 0;
        end
        
        
    case 'getarguments'
        varargout{1} = yalmip.dispatch(S,'extstruct',getvariables(varargin{2}));
        
    case 'auxvariables'
        varargout{1} = S.auxVariables;
        
    case 'auxvariablesW'
        varargout{1} = S.auxVariablesW;
        
    case 'extvariables'
        varargout{1} = S.extVariables;
        
    case 'extstruct'
        if nargin == 1
            varargout{1} = S.ExtendedMap;
        elseif length(varargin{2})==1
            found = 0;
            varargout{1} = [];
            i = 1;
            while ~found && i <=length(S.ExtendedMap)
                if varargin{2} == getvariables(S.ExtendedMap(i).var)
                    found = 1;
                    varargout{1} = S.ExtendedMap(i);
                end
                i = i + 1;
            end
        else
            % If requests several extended variables, returns as cell
            found = zeros(1,length(varargin{2}));
            varargout{1} = cell(0,length(varargin{2}));
            i = 1;
            while ~all(found) && i <=length(S.ExtendedMap)
                j = find(varargin{2} == getvariables(S.ExtendedMap(i).var));
                if ~isempty(j)
                    found(j) = 1;
                    varargout{1}{j} = S.ExtendedMap(i);
                end
                i = i + 1;
            end
        end
  
     case 'expvariables'    
        expvariables     = [];      
        for i = 1:length(S.ExtendedMap)
           if any(strcmpi(S.ExtendedMap(i).fcn,{'exp','pexp','log','slog','plog','logsumexp','kullbackleibler','entropy'}))
             expvariables = [ expvariables S.ExtendedMap(i).computes];
           end
        end
        varargout{1} = expvariables;       
        
    case 'rankvariables'
        i = 1;
        rankvariables     = [];
        dualrankvariables = [];
        for i = 1:length(S.ExtendedMap)
            if strcmpi('rank',S.ExtendedMap(i).fcn)
                rankvariables = [rankvariables getvariables(S.ExtendedMap(i).var)];
            end
            if strcmpi('dualrank',S.ExtendedMap(i).fcn)
                dualrankvariables = [dualrankvariables getvariables(S.ExtendedMap(i).var)];
            end
        end
        varargout{1} = rankvariables;
        varargout{2} = dualrankvariables;
        
    case {'lmiid','ConstraintID'}
        if not(isempty(S.LMIid))
            S.LMIid = S.LMIid+1;
            varargout{1}=S.LMIid;
        else
            S.LMIid=1;
            varargout{1}=S.LMIid;
        end
        
    case 'setnonlinearvariables'
        error('Internal error (ref. setnonlinearvariables). Report please.')
        
    case {'clear'}
        W = evalin('caller','whos');
        for i = 1:size(W,1)
            if strcmp(W(i).class,'sdpvar') || strcmp(W(i).class,'lmi')
                evalin('caller', ['clear ' W(i).name ';']);
            end
        end
        
        S.LMIid = 0;
        S.duals_index = [];
        S.duals_data = [];
        S.duals_associated_index = [];
        S.duals_associated_data  = [];
        
        
        S.sosid = 0;
        S.sos_index = [];
        S.sos_data = [];
        S.sos_ParV = [];
        S.sos_Q    = [];
        S.sos_v    = [];
        
        S.monomtable = spalloc(0,0,0);
        S.hashedmonomtable = [];
        S.hash = [];
        S.boundlist = [];
        S.variabletype = spalloc(0,0,0);
        S.intVariables = [];
        S.binVariables = [];
        S.tempintVariables = [];
        S.tempbinVariables = [];
        S.semicontVariables = [];
        S.uncVariables = [];
        S.parVariables = [];
        S.extVariables = [];
        S.auxVariables = [];
        S.auxVariablesW = [];
        S.logicVariables = [];
        ;S.complexpair = [];
        S.internalconstraints = [];
        S.ExtendedMap = [];
        S.ExtendedMapHashes = [];
        S.DependencyMap = sparse(0);
        S.DependencyMap_i = [];
        S.DependencyMap_j = [];
        S.DependencyMapUser = sparse(0);
        S.optSolution{1}.info = 'Initialized by YALMIP';
        S.optSolution{1}.variables = [];
        S.optSolution{1}.optvar = [];
        S.optSolution{1}.values = [];
        S.activeSolution = 1;
        
        S.nonCommutingTable = [];
		
		S.containsSemivar = false;
        
        gemInPath('clear');
        
    case 'cleardual'
        if nargin==1
            S.duals_index = [];
            S.duals_data = [];
            S.duals_associated_index = [];
            S.duals_associated_data = [];
        else
            if ~isempty(S.duals_index)
                S.lmiid = varargin{2};
                for i = 1:length(varargin{2})
                    j = find(S.duals_index==S.lmiid(i));
                    if ~isempty(j)
                        S.duals_index = S.duals_index([1:1:j-1 j+1:1:length(S.duals_index)]);
                        S.duals_data = {S.duals_data{[1:1:j-1 j+1:1:length(S.duals_data)]}};
                    end
                end
            end
        end
        
    case 'associatedual'
        S.duals_associated_index = [S.duals_associated_index varargin{2}];
        S.duals_associated_data{end+1} = varargin{3};
        
    case 'addcomplexpair'
        S.complexpair = [S.complexpair;varargin{2}];
        
    case 'getcomplexpair'
        error('Please report this error!')
        varargout{1} = S.complexpair;
        return
        
    case 'setallsolution'
        S.optSolution{S.activeSolution}.optvar = varargin{2}.optvar;
        S.optSolution{S.activeSolution}.variables = varargin{2}.variables;
        S.optSolution{S.activeSolution}.values = [];
        return
        
    case 'setvalues'
        S.optSolution{S.activeSolution}.values = varargin{2};
        
    case 'numbersolutions'
        varargout{1} = length(S.optSolution);
            
    case 'selectsolution'
        if length(S.optSolution)>=varargin{2}
            S.activeSolution = varargin{2};
        else
            error('Solution not available');
        end
        
    case 'setsolution'
                           
        if nargin < 3
            solutionIndex = 1;
        else
            solutionIndex = varargin{3};
        end
        S.activeSolution = 1;
        
        % Clear trailing solutions
        if solutionIndex < length(S.optSolution)
            S.optSolution = {S.optSolution{1:solutionIndex}};
        elseif solutionIndex > length(S.optSolution)+1
            for j = length(S.optSolution)+1:solutionIndex
                S.optSolution{j}.optvar=[];
                S.optSolution{j}.variables=[];
                S.optSolution{j}.values=[];
            end
        elseif solutionIndex == length(S.optSolution)+1
            S.optSolution{solutionIndex}.optvar=[];
            S.optSolution{solutionIndex}.variables=[];
            S.optSolution{solutionIndex}.values=[];
        end
        
        if isempty(S.optSolution{solutionIndex}.variables)
            S.optSolution{solutionIndex} = varargin{2};
        else
            % Just save some stuff first
            newSolution = varargin{2};
            oldSolution = S.optSolution{solutionIndex};
            optSolution = varargin{2};
            keep_these = find(~ismember(oldSolution.variables,newSolution.variables));
            S.optSolution{solutionIndex}.optvar    = [oldSolution.optvar(keep_these);newSolution.optvar(:)];
            S.optSolution{solutionIndex}.variables = [oldSolution.variables(keep_these);newSolution.variables(:)];
        end
        % clear evaluated values (only used cache-wise)
        S.optSolution{solutionIndex}.values = [];
        return
        
        %    case 'setsolution'
        %
        %         if isempty(S.optSolution.variables)
        %             S.optSolution = varargin{2};
        %         else
        %             % Just save some stuff first
        %             newSolution = varargin{2};
        %             oldSolution = S.optSolution;
        %             optSolution = varargin{2};
        %             keep_these = find(~ismember(oldSolution.variables,newSolution.variables));
        %             S.optSolution.optvar    = [oldSolution.optvar(keep_these);newSolution.optvar(:)];
        %             S.optSolution.variables = [oldSolution.variables(keep_these);newSolution.variables(:)];
        %         end
        %         % clear evaluated values (only used cache-wise)
        %         S.optSolution.values = [];
        %         return
        
    case 'addauxvariables'
        S.auxVariables = [S.auxVariables varargin{2}(:)'];
        
    case 'addauxvariablesW'
        S.auxVariablesW = [S.auxVariablesW varargin{2}(:)'];
        
        
    case 'getsolution'
        varargout{1} = S.optSolution{S.activeSolution};
        return
        
    case 'setdual'
        S.duals_index = varargin{2};
        S.duals_data = varargin{3};
        
        temp1 = [];
        temp2 = [];
        if ~isempty(S.duals_associated_index)
            if ~isempty(intersect(S.duals_index,S.duals_associated_index))
                for i = 1:length(S.duals_index)
                    itshere = find(S.duals_associated_index==S.duals_index(i));
                    if ~isempty(itshere)
                        temp1 = [temp1;S.duals_associated_data{itshere}(:)];
                        temp2 = [temp2;S.duals_data{i}(:)];
                    end
                    if length(temp1)>1000
                        assign(temp1,temp2);
                        temp1 = [];
                        temp2 = [];
                    end
                end
            end
            if ~isempty(temp1)
                assign(temp1,temp2);
            end
        end
        
    case 'dual'
        if isempty(S.duals_index)
            varargout{1}=[];
        else
            LMIid = varargin{2};
            index_to_dual = find(LMIid==S.duals_index);
            if isempty(index_to_dual)
                varargout{1}=[];
            else
                varargout{1} = S.duals_data{index_to_dual};
            end
        end
        
    case 'clearsos'
        if nargin==1
            S.sos_index = [];
            S.sos_data = [];
            S.sos_ParV = [];
            S.sos_Q    = [];
            S.sos_v    = [];
            
        end
        
    case 'setsos'
        if ~isempty(S.sos_index)
            where = find(S.sos_index==varargin{2});
            if ~isempty(where)
                S.sos_index(where) = varargin{2};
                S.sos_data{where} = varargin{3};
                S.sos_ParV{where} = varargin{4};
                S.sos_Q{where} = varargin{5};
                S.sos_v{where} = varargin{6};
                
            else
                S.sos_index(end+1) = varargin{2};
                S.sos_data{end+1} = varargin{3};
                S.sos_ParV{end+1} = varargin{4};
                S.sos_Q{end+1} = varargin{5};
                S.sos_v{end+1} = varargin{6};
                
            end
        else
            S.sos_index(end+1) = varargin{2};
            S.sos_data{end+1} = varargin{3};
            S.sos_ParV{end+1} = varargin{4};
            S.sos_Q{end+1} = varargin{5};
            S.sos_v{end+1} = varargin{6};
        end
        
    case 'sosid'
        if not(isempty(S.sosid))
            S.sosid = S.sosid+1;
            varargout{1}=S.sosid;
        else
            S.sosid=1;
            varargout{1}=S.sosid;
        end
        
    case 'getsos'
        if isempty(S.sos_index)
            varargout{1}=[];
            varargout{2}=[];
            varargout{3}=[];
            varargout{4}=[];
        else
            SOSid = varargin{2};
            index_to_sos = find(SOSid==S.sos_index);
            if isempty(index_to_sos)
                varargout{1}=[];
                varargout{2}=[];
                varargout{3}=[];
                varargout{4}=[];
            else
                varargout{1} = S.sos_data{index_to_sos};
                varargout{2} = S.sos_ParV{index_to_sos};
                varargout{3} = S.sos_Q{index_to_sos};
                varargout{4} = S.sos_v{index_to_sos};
                % FIX
            end
        end
        
        
    case 'getinternalsetstate'
        varargout{1} = internal_setstate; % Get internal state, called from saveobj
        
    case 'setinternalsetstate'
        internal_setstate = varargin{2}; % Set internal state, called from loadobj
        
    case 'getinternalsdpvarstate'
        varargout{1} = internal_sdpvarstate; % Get internal state, called from saveobj
        
    case 'setinternalsdpvarstate'
        internal_sdpvarstate = varargin{2}; % Set internal state, called from loadobj
        
        % Back-wards compability....
        if ~isfield(internal_sdpvarstate,'extVariables')
            S.extVariables = [];
        end
        if ~isfield(internal_sdpvarstate,'ExtendedMap')
            S.ExtendedMap = [];
			S.containsSemivar = false;
        end
        if ~isfield(internal_sdpvarstate,'ExtendedMapHashes')
            S.ExtendedMapHashes = [];
        end  
        if ~isfield(internal_sdpvarstate,'variabletype')
            S.variabletype = ~(sum(S.monomtable,2)==1 & sum(S.monomtable~=0,2)==1);
        end
        if ~isfield(internal_sdpvarstate,'hash')
            S.hash=[];
            S.hashedmonomtable=[];
        end
        
        % Re-compute some stuff for safety
        S.variabletype = S.variabletype(:)';
        S.variabletype = spalloc(size(S.monomtable,1),1,0)';
        nonlinear = ~(sum(S.monomtable,2)==1 & sum(S.monomtable~=0,2)==1);
        if ~isempty(nonlinear)
            mt = S.monomtable;
            S.variabletype(nonlinear) = 3;
            quadratic = sum(S.monomtable,2)==2;
            S.variabletype(quadratic) = 2;
            bilinear = max(S.monomtable,[],2)<=1;
            S.variabletype(bilinear & quadratic) = 1;
            signomial = any(0>S.monomtable,2) | any(S.monomtable-fix(S.monomtable),2);
            S.variabletype(signomial) = 4;
        end
        
        [n,m] = size(S.monomtable);
        if n>m
            S.monomtable(n,n) = 0;
        end
        
        if size(S.monomtable,2)>length(S.hash)
            % Need new hash-keys
            S.hash = [S.hash ; 3*gen_rand_hash(size(S.monomtable,1),need_new,1)];
        end
        if size(S.monomtable,1)>size(S.hashedmonomtable,1)
            % Need to add some hash values
            need_new = size(S.monomtable,1) - size(S.hashedmonomtable,1);
            S.hashedmonomtable = [S.hashedmonomtable;S.monomtable(end-need_new+1:end,:)*S.hash];
        end
        
        
        
    case {'version','ver'}
        varargout{1} = '20250626';
        
    case 'setintvariables'
        S.intVariables = varargin{2};
        
    case 'intvariables'
        varargout{1} = S.intVariables;
        
    case 'setbinvariables'
        S.binVariables = varargin{2};
        
    case 'binvariables'
        varargout{1} = S.binVariables;
        
    case 'settempintvariables'
        S.tempintVariables = varargin{2};
        
    case 'tempintvariables'
        varargout{1} = S.tempintVariables;
        
    case 'settempbinvariables'
        S.tempbinVariables = varargin{2};
        
    case 'tempbinvariables'
        varargout{1} = S.tempbinVariables;
                
        
    case 'quantvariables'
        varargout{1} = [S.binVariables S.intVariables];
        
    case 'setsemicontvariables'
        S.semicontVariables = varargin{2};
        
    case 'semicontvariables'
        varargout{1} = S.semicontVariables;
        
    case 'setuncvariables'
        S.uncVariables = varargin{2};
        
    case 'uncvariables'
        varargout{1} = S.uncVariables;
        
    case 'setparvariables'
        S.parVariables = varargin{2};
        
    case 'parvariables'
        varargout{1} = S.parVariables;
        
    case 'nonCommutingVariables'
        if isempty(S.nonCommutingTable)
             varargout{1} = [];
        else
            varargout{1} = find(isnan(S.nonCommutingTable(:,1)));
        end
            
    case 'nonCommutingTable'
        if nargin == 2
            S.nonCommutingTable = varargin{2};       
        else
            varargout{1} = S.nonCommutingTable;
        end
        
    case 'nonlinearvariables'
        error('Internal error (ref. nonlinear variables). Report!')
        varargout{1} = S.nonlinearvariables;
        if nargout==2
            varargout{2} = S.nonlinearvariablesCompressed;
        end
        %
    case {'addinternal'}
        S.internalconstraints{end+1} = varargin{1};
        
        %  case {'setnvars'}
        %      sdpvar('setnvars',varargin{2},'session',{S});
        
    case {'nvars'}
        varargout{1} = size(S.monomtable,1);
        % varargout{1} = sdpvar('nvars','session',{S});
        
    case {'info'}
        version_str = yalmipversion(); release = '';
        [version,release] = deal(version_str,release);
        currentversion = num2str(version(1));
        i = 1;
        while i<length(version)
            i = i+1;
            currentversion = [currentversion '.' num2str(version(i))];
        end
        
        info_str = ['- - - - YALMIP ' currentversion ' ' num2str(release) ' - - - -'];
        
        disp(' ');
        disp(char(repmat(double('*'),1,length(info_str))));
        disp(info_str)
        disp(char(repmat(double('*'),1,length(info_str))));
        disp(' ');
        disp(['Variable     Size'])
        spaces = ['                                    '];
        ws = evalin('caller','whos');
        n = 0;
        for i = 1:size(ws,1)
            if strcmp(ws(i).class,'sdpvar')
                n = n+1;
                wsname = ws(i).name;
                wssize = [num2str(ws(i).size(1)) 'x' num2str(ws(i).size(2))];
                disp([wsname spaces(1:13-length(wsname)) wssize]);
            end
        end
        if n == 0
            disp('No SDPVAR objects found');
        end
        disp(' ');
        disp(['LMI']);
        n = 0;
        for i = 1:size(ws,1)
            if strcmp(ws(i).class,'lmi')
                n = n+1;
                wsname = ws(i).name;
                disp([wsname]);
            end
        end
        if n == 0
            disp('No SET objects found');
        end
        
    case 'getbounds'
        if ~isfield(internal_sdpvarstate,'boundlist')
            S.boundlist = inf*repmat([-1 1],size(S.monomtable,1),1);
        elseif isempty(S.boundlist)
            S.boundlist = inf*repmat([-1 1],size(S.monomtable,1),1);
        end
        indicies = varargin{2};
        if max(indicies)>size(S.boundlist,1)
            need_new = max(indicies)-size(S.boundlist,1);
            S.boundlist = [S.boundlist;inf*repmat([-1 1],size(S.monomtable,1),1)];
        end
        varargout{1} = S.boundlist(indicies,:);
        varargout{2} = S.boundlist(indicies,:);
        
    case 'setbounds'
        if ~isfield(internal_sdpvarstate,'boundlist')
            S.boundlist = inf*repmat([-1 1],size(S.monomtable,1),1);
        elseif isempty(S.boundlist)
            S.boundlist = inf*repmat([-1 1],size(S.monomtable,1),1);
        end
        indicies = varargin{2};
        if size(S.boundlist,1)<min(indicies)
            S.boundlist = [S.boundlist;repmat([-inf inf],max(indicies)-size(S.boundlist,1),1)];
        end
        S.boundlist(indicies,1) = -inf ;
        S.boundlist(indicies,2) = inf;
        
        S.boundlist(indicies(:),1) = varargin{3};
        S.boundlist(indicies(:),2) = varargin{4};
        varargout{1}=0;
        
    case 'extendedmap'
        varargout{1} = S.ExtendedMap;
        
    case  'logicextvariables'
        logicextvariables = [];
        for i = 1:length(S.ExtendedMap)
            %            if ismember(S.ExtendedMap(i).fcn,{'or','and'})
            if isequal(S.ExtendedMap(i).fcn,'or') || isequal(S.ExtendedMap(i).fcn,'and')
                logicextvariables = [logicextvariables S.extVariables(i)];
            end
        end
        varargout{1} = logicextvariables;
        
    case 'logicVariables'
        varargout{1} = S.logicVariables;
        
    case 'addlogicvariable'
        % This code essentially the same as the addextended code. The only
        % difference is that we keep track of logic variables in order to
        % know when we have to collect bounds for the big-M relaxations.
        
        varargin{2} = strrep(varargin{2},'sdpvar/','');
        
        % Is this operator variable already defined
        if ~isempty(S.ExtendedMap)
            i = 1;
            while i<=length(S.ExtendedMap)
                if isequal(varargin{2},S.ExtendedMap(i).fcn) && isequal({varargin{3:end}}, {S.ExtendedMap(i).arg{1:end-1}})
                    varargout{1} =  S.ExtendedMap(i).var;
                    return
                end
                i = i + 1;
            end
        end
        
        % This is the standard operators. INPUTS -> 1 scalar output
        y = sdpvar(1,1,'session',{S});
        S.ExtendedMap(end+1).fcn = varargin{2};
        S.ExtendedMap(end).arg = {varargin{3:end}};
        S.ExtendedMap(end).var = y;
        S.extVariables = [S.extVariables getvariables(y)];
        S.logicVariables = [S.logicVariables getvariables(y)];
		S.containsSemivar = S.containsSemivar | strcmp(varargin{2}, 'semivar');
        varargout{1} = y;
        return
        
    case 'setNonHermitianNonCommuting'
        S.nonHermitiannonCommutingTable(varargin{2}) = 1;
        
    case 'solver'
        if (nargin==2)
            if isa(varargin{2},'char')
                solver = varargin{2};
                S.preferedSolver = solver;
            else
                error('Second argument should be a string with solver name');
            end
        else
            if isempty(S.preferedSolver)
                varargout{1}='';
            else
                varargout{1} = S.preferedSolver;
            end
        end
		
	case 'containsSemivar'
		varargout = {S.containsSemivar};
    
    case 'gemInPath'
        varargout{1} = gemInPath;
    
    otherwise
        if isa(varargin{1},'char')
            disp(['The command ''' varargin{1} ''' is not valid in YALMIP.m']);
        else
            disp('The first argument should be a string');
        end
end

end
function h = create_vecisdouble(x)
    B = getbase(x);
    h = ~any(B(:,2:end),2);
end

function h = create_trivial_hash(x)
    try
        h = sum(getvariables(x)) + sum(sum(getbase(x)));
    catch
        h = 0;
    end
end

function h = create_trivial_vechash(x)
    try
        B = getbase(x);
        h = sum(B')'+(B | B)*[0;getvariables(x)'];    
    catch
        h = 0;
    end
end

function X = firstSDPVAR(List)
    X = [];
    for i = 1:length(List)
        if isa(List{i},'sdpvar')
            X = List{i};
            break
        end
    end
end
