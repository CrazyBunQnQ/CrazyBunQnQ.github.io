# node 环境镜像
FROM node:buster AS build-env
# FROM node:19.6.0-buster AS build-env

# 传入构建变量, 构建时生效
ARG GITHUB_TOKEN
ARG GITHUB_EMAIL
ARG GITHUB_NAME
# 设置环境变量，镜像运行时生效
ENV GITHUB_TOKEN_ENV=${GITHUB_TOKEN}

# 创建 hexo-blog 文件夹且设置成工作文件夹
WORKDIR /usr/src

RUN node --version && \
echo "安装 hexo" && \
npm install hexo-cli -g && \
echo "下载主题" && \
git clone https://github.com/CrazyBunQnQ/hexo-theme-matery.git matery && \
echo "下载文章" && \
git clone https://github.com/CrazyBunQnQ/HexoBlog.git source && \
echo "初始化博客目录" && \
hexo init hexo-blog && \
echo "移动主题到博客目录" && \
mv matery hexo-blog/themes/ && \
echo "移动文章到源文件目录" && \
rm -r hexo-blog/source && mv source hexo-blog/ && \
echo "进入博客目录" && \
cd hexo-blog && \
# 安装所需插件
echo "安装 github 部署插件" && \
npm install --save hexo-deployer-git && \
echo "安装 搜索插件" && \
npm install --save hexo-generator-search && \
echo "安装 字数统计插件" && \
npm install --save hexo-wordcount && \
echo "安装 中文链接转拼音插件" && \
npm install --save hexo-permalink-pinyin && \
echo "安装 RSS 订阅插件" && \
npm install --save hexo-generator-feed && \
echo "安装 emoji 表情插件" && \
npm install --save hexo-filter-github-emojis && \
# echo "安装 gitalk 评论插件" && \
# npm install --save gitalk && \
# echo "安装 代码高亮插件" && \
# npm install --save hexo-prism-plugin && \
echo "安装 站点地图插件" && \
npm install --save hexo-generator-sitemap && \
echo "安装 主动推送百度搜索" && \
npm install hexo-baidu-url-submit && \
echo "========== 所有插件安装完成 ==========" && \
echo "更新 hexo 配置文件" && \
mv ./source/hexo_config.yml ./_config.yml && \
echo "设置 hexo 配置文件的 github token" && \
sed -i "s/\${GITHUB_TOKEN}/$GITHUB_TOKEN/" _config.yml && \
echo "更新主题配置文件" && \
mv ./source/_config.yml ./themes/matery/_config.yml && \
echo "设置 git 邮箱和用户名" && \
git config --global user.email "$GITHUB_EMAIL" && \
git config --global user.name "$GITHUB_NAME" && \
echo "清理博客目录、重新生成静态文件" && \
hexo clean && hexo g\
echo "部署到 github(此镜像为中间镜像，上面设置的环境变量此时不生效，hexo d 无法从环境变量中读取 token)" && \
hexo d && \
echo "添加百度搜索引擎" && \
mv ./source/baidu/* ./public/

# nginx 镜像
FROM nginx
# FROM nginx:1.21.6
# 维护者信息
MAINTAINER CrazyBunQnQ "crazybunqnq@gmail.com"

# 设置镜像时区环境变量
ENV TZ=Asia/Shanghai

# 设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#COPY . /usr/share/nginx/html/
WORKDIR /usr/share/nginx/html

# 把上一部生成的 HTML 文件复制到 Nginx 中
COPY --from=build-env /usr/src/hexo-blog/public /usr/share/nginx/html
EXPOSE 80

# docker build -t crazybun/blog-matery:20220504 --build-arg GITHUB_TOKEN="github_token" --build-arg GITHUB_EMAIL="baobao222222@qq.com" --build-arg GITHUB_NAME="CrazyBunQnQ" .

# docker run -itd --name blog-matery -p 8081:80 --restart always crazybun/blog-matery:21