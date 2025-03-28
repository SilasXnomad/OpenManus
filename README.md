# xx

```bash
docker build -t temp -f webchrome.Dockerfile .
docker run --rm -d -p 5900:5900 -p 9222:9222 -p 6080:6080 -p 8080:8080 -v ./config:/app/config --name temp
# silasxnomad/openmanus:v0.0.1
```
