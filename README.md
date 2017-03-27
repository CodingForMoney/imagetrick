# imagetrick

Picture processing server powered by Openresty and GraphicsMagick

## test for docker 

	docker pull dockerwhat/imagetrick
	docker run -d -p 端口:8059 dockerwhat/imagetrick
	
`imagetrick` just support for `size` ,`quailty` and `format`.

	http://localhost:8080/resource.luoxianming.cn/radians_circle.jpg?format=webp&quality=75&width=200
	
