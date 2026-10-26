function properties = assertProperty(properties,checkfor,default)
if ~isfield(properties,checkfor)
    properties.(checkfor) = default;
end