# Dockerfile

# 1. Redmine 최신 안정 버전을 기반 이미지로 사용
FROM redmine:latest

# 2. 시스템 패키지 설치 및 언어 파일 수정을 위해 root 권한으로 전환
USER root

# git(소스코드 다운로드)과 build-essential(플러그인 설치용) 도구를 설치합니다.
# redmine-apijs 플러그인을 위한 python3, python3-pil, python3-scour, libimage-exiftool-perl, ffmpegthumbnailer도 함께 설치합니다.
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    python3 \
    python3-pil \
    python3-scour \
    libimage-exiftool-perl \
    ffmpegthumbnailer \
    unzip

# 3. 한국어 언어 파일(ko.yml)에서 '일감'을 '이슈'로 일괄 변경합니다.
# sed 명령어는 특정 단어를 찾아 바꿔주는 역할을 합니다.
RUN sed -i "s/일감/이슈/g" /usr/src/redmine/config/locales/ko.yml

# 4. 플러그인을 설치할 plugins 폴더로 이동합니다.
WORKDIR /usr/src/redmine/plugins

# git clone 명령으로 필요한 플러그인들을 모두 다운로드합니다. --depth 1은 용량 최적화 옵션입니다.
RUN git clone --depth 1 https://github.com/jcatrysse/redmine_issue_todo_lists2.git redmine_issue_todo_lists2 && \
    git clone --depth 1 https://github.com/luigifab/redmine-apijs.git redmine_apijs && \
    git clone --depth 1 https://github.com/haru/redmine_ai_helper.git redmine_ai_helper

# 로컬 ZIP 플러그인 파일들을 복사하고 압축 해제합니다.
COPY wbs-redmine-6.zip redmineflux_inplace_issue_editor_6.0.0.zip redmineflux_mentions_6.0.0.zip redmineflux_tags_6.1.0.zip gantt-pro-redmine-6.zip /tmp/plugins/
RUN cd /tmp/plugins && \
    unzip -q wbs-redmine-6.zip -d /usr/src/redmine/plugins/ && \
    unzip -q redmineflux_inplace_issue_editor_6.0.0.zip -d /usr/src/redmine/plugins/ && \
    unzip -q redmineflux_mentions_6.0.0.zip -d /usr/src/redmine/plugins/ && \
    unzip -q redmineflux_tags_6.1.0.zip -d /usr/src/redmine/plugins/ && \
    unzip -q gantt-pro-redmine-6.zip -d /usr/src/redmine/plugins/ && \
    rm -rf /tmp/plugins

# 5. 테마를 설치할 public/themes 폴더로 이동합니다.
WORKDIR /usr/src/redmine/public/themes

# 필요한 테마들을 모두 다운로드합니다.
RUN git clone --depth 1 https://github.com/gagnieray/opale.git opale_gagnieray

# 로컬 테마 ZIP 파일들을 복사하고 압축 해제합니다. (Redmine 6+ 버전이므로 themes 디렉토리 사용)
COPY redminecrm_theme-1_2_0.zip highrise_theme-1_2_0.zip coffee_theme-1_0_0.zip a1_theme-4_1_2.zip circle_theme-2_2_3.zip /tmp/themes/
RUN cd /tmp/themes && \
    unzip -q redminecrm_theme-1_2_0.zip -d /usr/src/redmine/public/themes/ && \
    unzip -q highrise_theme-1_2_0.zip -d /usr/src/redmine/public/themes/ && \
    unzip -q coffee_theme-1_0_0.zip -d /usr/src/redmine/public/themes/ && \
    unzip -q a1_theme-4_1_2.zip -d /usr/src/redmine/public/themes/ && \
    unzip -q circle_theme-2_2_3.zip -d /usr/src/redmine/public/themes/ && \
    rm -rf /tmp/themes

# 6. Redmine 루트 폴더로 이동하여 플러그인들이 필요로 하는 라이브러리(Gem)를 설치합니다.
WORKDIR /usr/src/redmine
RUN bundle install --without development test --no-deployment

# 7. 컨테이너 시작 시 실행될 스크립트를 이미지 안으로 복사하고 실행 권한을 부여합니다.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 8. 보안을 위해 다시 일반 사용자인 redmine으로 전환합니다.
USER redmine

# 9. 이 이미지로 컨테이너를 시작할 때 실행할 기본 명령을 지정합니다.
ENTRYPOINT ["/entrypoint.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]