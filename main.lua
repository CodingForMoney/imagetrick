local magick = require("magick")
local http = require("resty.http")
local fileutil = require("fileutil")


-- 设置项
local TMP_PATH = "/data/pictrix/tmp/"
local IMAGE_PATH = "/data/pictrix/image/"
--  debug模式
local DEBUG = true 

--  认证的域名
local verifiedHosts = {
	"image.mucfc.com",
	"img13.buyimg.com",
	"adminweb.younigou.com",
	"resource.luoxianming.cn"
}
-- 可以转换的图片类型
local enableImageTypes = {
	"jpeg",
	"webp",
	"png"
}
-- 可以处理的原始图片类型
local enableContentTypes = {
	"image/jp2",
	"image/jpeg",
	"image/webp",
	"image/png"
}

--  最大处理图片大小 10M  超过这个大小的图片不予处理
local  MaxImageLength = 10000000
local host
local path
--  检测uri路径是否正确，即是否在我们的域名白名单下
--  true 表示合法， false表示不合法 
local function checkURIIsCorrect( URL )
	local firstSlash = URL:find("/")
	if firstSlash == nil then
		return false
	end
	-- ngx.log(ngx.ERR,"slash   " .. firstSlash .. "  URL :"..URL)
	host = URL:sub(1 , firstSlash - 1)
	path = URL:sub(firstSlash)
	for i, v in ipairs(verifiedHosts) do
	  if v == host then
	  	return true
	  end
	end
	return false
end
--  检测下载链接的contentType ， 如果出错，不予处理
local function checkContentType( type )
	for i, v in ipairs(enableContentTypes) do
	  if v == type then
	  	return true
	  end
	end
	return false
end


local function checkFormat( format )
	for i, v in ipairs(enableImageTypes) do
	  	if v == format then
	  		return true
	  	end
	end
	return false
end 

local function getContentTypeFromImageType( format )
	local mimetype 
	if format == "jpeg" then
		mimetype = "image/jpeg"
	end
	if format == "png" then
		mimetype = "image/png"
	end
	if format == "webp" then
		mimetype = "image/webp"
	end
	ngx.header['Content-Type'] = format 
end 

--  检测作图参数是否正确
local  function checkArgsIsCorrect( args )
	
	return true
end


--  图片文件
local imagefile


local function errorHandler( info )
	if DEBUG then	
		ngx.say(info)
		ngx.exit(ngx.HTTP_OK)
	else
		ngx.log(ngx.ERR,info)
		ngx.exit(500)
	end
	
end 

--  图片处理
--  请求作图参数写法
 -- ? format = webp 转换格式 , 限定 enableImageTypes
 -- & heigth = xx  高度， 如果没有指定宽度，则指按高度比例进行压缩
 -- & width = xx  宽度 ， 如果没有指定高度，则按 宽度比 进行压缩
 -- & quality = xx 质量， 限定1-100 。 
local function triximage( args )
	local img = magick.load_image(imagefile.image_path)
	if img == nil then
		errorHandler("未找到图片， 这是不可能的！！！")
	end
	local imageFormat = img:get_format()
	getContentTypeFromImageType (imageFormat)
	-- ngx.say ("当前图片类型是" .. img:get_format() )
	-- ngx.say ("当前图片质量是" ..  img:get_quality() )
	if  args == nil then
		--  没有作图参数， 不需要作图
		ngx.print(img:get_blob())
		img:destroy()
		img = nil
		return
	end
	-- 先转换格式 
	local format = args["format"]
	if format ~= nil then
		if checkFormat(format) ~= true then
			errorHandler("转换格式失败 ，目标格式错误" .. format)
		end
		getContentTypeFromImageType (format)
		if imageFormat ~= format then
			img:set_format(format)
		end
	end
	
	-- 再转质量
	local quality = tonumber (args["quality"])
	if quality ~= nil then
		if quality > 1 and quality < 100 then
			img:set_quality(quality)
		end
	end
	--  最后， 处理尺寸
	local width = tonumber (args["width"])
	local heigth = tonumber (args["heigth"])
	local imageWidth = img:get_width()
	local imageHeight = img:get_height()
	if width == nil and heigth == nil then
		ngx.print(img:get_blob())
		img:destroy()
		img = nil
		return
	end
	if width ~= nil and width >= imageWidth then
		ngx.print(img:get_blob())
		img:destroy()
		img = nil
		return
	end

	if heigth ~= nil and heigth >= imageHeight then
		ngx.print(img:get_blob())
		img:destroy()
		img = nil
		return
	end
	if width == nil then
		width = heigth / imageHeight * imageWidth
	end
	if heigth == nil then
		heigth = width / imageWidth * imageHeight
	end 
	img:resize(width,heigth)
	ngx.print(img:get_blob())
	img:destroy()
	img = nil
end

--  下载源图
local function downloadimage( )
	--  下载
	local httpc = http.new()
	-- The generic form gives us more control. We must connect manually.
	httpc:set_timeout(3000)
	local cres,cerr = httpc:connect(host, 80)
	if not cres then
		errorHandler("failed to connect: " .. cerr)
	return
	end
	-- And request using a path, rather than a full URI.
	local res, err = httpc:request{
		method = "GET",
	  	path = path,
	}
	if not res then
		errorHandler("failed to request: " .. err)
	return
	end
	if 200 ~= res.status then
		--  是否需要进行特殊处理
		--errorHandler()
	    	ngx.exit(res.status)
	end
	local  headers = res.headers
	if checkContentType(headers["Content-Type"]) == false then
		errorHandler("错误的图片类型")
	end
	if tonumber (headers["Content-Length"]) > MaxImageLength then
		errorHandler("资源太大")
	end
	-- Now we can use the body_reader iterator, to stream the body according to our desired chunk size.
	local reader = res.body_reader
	imagefile:touchTmp()
	
	-- 如果设置了reader , 就没有 res.body了。
	repeat
	local chunk, err = reader(8192)
	if err then
	  errorHandler("分段下载失败" .. err)
	  break
	end
	if chunk then
	  	imagefile:appendData(chunk)
	end
	until not chunk
	imagefile:release()
	httpc:close()
-- httpc:set_keepalive() 使用优化
end


function dumpTab(tab,ind)
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

function main(  )
	if DEBUG then
		ngx.header['Content-Type']="text/html;charset=UTF-8"
	end
	if ngx.req.get_method() ~= "GET" then
		errorHandler("不是get方法！！")
		return
	end
	local URL = ngx.var.document_uri
	URL = URL:sub(2,URL:len())
	if checkURIIsCorrect(URL) ~= true then
		errorHandler("域名不正确，不予请求")
		return
	end
	local args = ngx.req.get_uri_args()
	if checkArgsIsCorrect(args) ~= true then
		errorHandler("参数错误， 不予处理")
		return
	end
	imagefile = fileutil:new(URL,errorHandler) 
	if imagefile:existing() then
		triximage(args)
	else
		downloadimage()
		triximage(args)
	end

end


main()

