FROM dart:3.6.0

WORKDIR /app

COPY pubspec.* ./

RUN dart pub get

COPY . .

EXPOSE 8080

CMD ["dart", "bin/main.dart"]