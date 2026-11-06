# サイドクエスト (演習 11) の参考。compose.yaml はこのファイルを使わず、公式イメージに site/ をマウントするだけ。
# 自分でイメージを作って動かす場合: docker build -t hidamari . && docker run --rm -p 8080:80 hidamari
FROM nginx:alpine
COPY site/ /usr/share/nginx/html/
