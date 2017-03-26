--  缓存目录中存放的文件名是一个随机值。
local TMP_PATH = "/imagetrick/data/tmp/"
-- 文件路径为 path + URL . 中间路径要在没有时创建文件夹。
local IMAGE_PATH = "/imagetrick/data/image/"

--  缓存目录中存放的文件名是一个随机值。
--local TMP_PATH = "/Users/luoxianming/Documents/Testing/pictrix/file/tmp/"
-- 文件路径为 path + URL . 中间路径要在没有时创建文件夹。
--local IMAGE_PATH = "/Users/luoxianming/Documents/Testing/pictrix/file/image/"
local prixutil = require("trickutil")

local _M = {}

local mt = { __index = _M }

local function fileExisting( path )
	local file = io.open(path, "r")
	if file then file:close() end
	return file ~= nil
end 
-- 如果文件不存在， 则表示要下载新的文件。
function _M.existing (self)
	if(self.image_path == nil) then
    	self.image_path = string.gsub(self.url,"/","_")
    	if string.len(self.image_path) > 254 then
    		self:errorEnd("文件名太大 ：".. self.image_path .." ，出错!!!")
    	end
    	self.image_path = IMAGE_PATH .. self.image_path
	end
    return fileExisting(self.image_path )
end

--  创建 缓冲文件。 如果出错返回error
function _M.touchTmp( self )
	if self.tmp_path == nil then
		local urlhash = prixutil.hashString(self.url)
		local time = prixutil.accuratetime()
		local filename = urlhash .. time
		self.tmp_path = TMP_PATH .. filename
		local err
		self.tmp,err = io.open(self.tmp_path,"wb")
		if self.tmp == nil then
			self:errorEnd("打开文件失败， 原因:"..err.." 路径 :"..self.tmp_path)
		end
	end
end

function _M.errorEnd( self , info )
	if self.tmp ~= nil then
		self.tmp:close()
		prixutil.deletefile(self.tmp_path)
	end
	self.error(info)
end
-- 下载时， 边读边写文件。
function _M.appendData( self , data)
	self.tmp:write(data)
end

-- 将文件移动到 最终目录中。
function _M.release( self )
	self.tmp:close()
	if prixutil.movefile(self.tmp_path , self.image_path) ~= 0 then
		self:errorEnd("移动文件失败 ： " .. self.tmp_path .. " --> " ..self.image_path .. "   原因未知")
	end
end

--  errorfun(errString) 出错处理， 一般为打印日志，以及
function _M.new (self, URL,errorfun)
	if (URL == nil) then 
		return nil
	end
    return setmetatable({url = URL,error = errorfun}, mt)
end

return _M
