local ffi = require("ffi")
ffi.cdef([[
	int pdeletefile(const char* filename);
	int pmovefile(const char* src , const char* dest);
	long BKDRHash(const char* str);
	long getmillisecond();
	]])

local lib = ffi.load("/imagetrick/lib/libtrickutil.so")
-- string 是 const char * 否则会爆错误。

local _M = {}
-- hash 字符串
function _M.hashString( str )
	if str == nil then
		return 0
	end
	local hash  = tostring (lib.BKDRHash(str))
	hash = hash:sub(2,hash:len()-3)
	return hash

end

-- 移动文件 0 表示成功
function _M.movefile( src , dest )
	return lib.pmovefile(src,dest)
end


-- 删除文件。 0 表示成功
function _M.deletefile( path )
	return lib.pdeletefile(path)
end

function _M.accuratetime(  )
	return tonumber(lib.getmillisecond())
end


---
-- @function: 获取table的字符串格式内容，递归
-- @tab： table
-- @ind：不用传此参数，递归用（前缀格式（空格））
-- @return: format string of the table
function _M.dumpTab(tab,ind)
  if(tab==nil)then return "nil" end
  local str="{"
  if(ind==nil)then ind="  " end
  --//each of table
  for k,v in pairs(tab) do
    --//key
    if(type(k)=="string")then
      k=tostring(k).." = "
    else
      k="["..tostring(k).."] = "
    end
    --//value
    local s=""
    if(type(v)=="nil")then
      s="nil"
    elseif(type(v)=="boolean")then
      if(v) then s="true" else s="false" end
    elseif(type(v)=="number")then
      s=v
    elseif(type(v)=="string")then
      s="\""..v.."\""
    elseif(type(v)=="table")then
      s=dumpTab(v,ind.."  ")
      s=string.sub(s,1,#s-1)
    elseif(type(v)=="function")then
      s="function : "..v
    elseif(type(v)=="thread")then
      s="thread : "..tostring(v)
    elseif(type(v)=="userdata")then
      s="userdata : "..tostring(v)
    else
      s="nuknow : "..tostring(v)
    end
    --//Contact
    str=str.."\n"..ind..k..s.." ,"
  end 
  --//return the format string
  local sss=string.sub(str,1,#str-1)
  if(#ind>0)then ind=string.sub(ind,1,#ind-2) end
  sss=sss.."\n"..ind.."}\n"
  return sss
end

return _M
