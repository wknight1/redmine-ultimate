# Dockerfile

# 1. Redmine 최신 안정 버전을 기반 이미지로 사용
FROM redmine:latest

# 2. 시스템 패키지 설치 및 언어 파일 수정을 위해 root 권한으로 전환
USER root

# git(소스코드 다운로드)과 build-essential(플러그인 설치용) 도구를 설치합니다.
RUN apt-get update && apt-get install -y --no-install-recommends git build-essential

# 3. 한국어 언어 파일(ko.yml)에서 '일감'을 '이슈'로 일괄 변경합니다.
# sed 명령어는 특정 단어를 찾아 바꿔주는 역할을 합니다.
RUN sed -i "s/일감/이슈/g" /usr/src/redmine/config/locales/ko.yml

# 4. 플러그인을 설치할 plugins 폴더로 이동합니다.
WORKDIR /usr/src/redmine/plugins

# git clone 명령으로 필요한 플러그인들을 모두 다운로드합니다. --depth 1은 용량 최적화 옵션입니다.
RUN git clone --depth 1 https://github.com/redmineup/redmine_agile.git redmine_agile && \
    git clone --depth 1 https://github.com/redmineup/redmine_checklists.git redmine_checklists && \
    git clone --depth 1 https://github.com/easysoftware/redmine-easy-gantt.git easy_gantt && \
    git clone --depth 1 https://github.com/akiko-pusu/redmine_issue_templates.git redmine_issue_templates && \
    git clone --depth 1 https://github.com/redmineup/redmine_people.git redmine_people && \
    git clone --depth 1 https://github.com/a-ono/redmine_ckeditor.git redmine_ckeditor && \
    git clone --depth 1 https://github.com/onozaty/redmine-view-customize.git redmine_view_customize && \
    git clone --depth 1 https://github.com/phlegx/redmine_gitlab_hook.git redmine_gitlab_hook && \
    git clone --depth 1 https://github.com/n-rodriguez/redmine_ai_helper.git redmine_ai_helper && \
    git clone --depth 1 https://github.com/anovi/redmine_automation.git redmine_automation

# 5. 테마를 설치할 public/themes 폴더로 이동합니다.
WORKDIR /usr/src/redmine/public/themes

# 필요한 테마들을 모두 다운로드합니다.
RUN git clone --depth 1 https://github.com/mrliptontea/PurpleMine-2.git opale && \
    git clone --depth 1 https://github.com/redmineup/a1.git a1 && \
    git clone --depth 1 https://github.com/redmineup/circle.git circle

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