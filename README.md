## imagetrick

Picture processing server powered by Openresty and GraphicsMagick

## test by using docker 
	
It's really hard to push the image to Docker Registry behind the Wall😢. You should build image by the `Dockerfile`.

	docker build -test=imagetrick .
	docker run -d -p port:8059 imagetrick
	
`imagetrick` just support for `size` ,`quailty` and `format`.

	http://localhost:8080/resource.luoxianming.cn/radians_circle.jpg?format=webp&quality=75&width=200