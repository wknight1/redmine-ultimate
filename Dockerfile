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

# 5. 테마를 설치할 themes 폴더로 이동합니다. (Redmine 6+ 버전)
WORKDIR /usr/src/redmine/public/themes

# 기존 테마 백업 및 확인
RUN echo "=== Existing themes ===" && \
    ls -la /usr/src/redmine/public/themes/ && \
    find /usr/src/redmine/public/themes -name "application.css"

# Git 테마 설치 (opale)
RUN git clone --depth 1 https://github.com/gagnieray/opale.git opale && \
    echo "Opale theme structure:" && \
    find opale -type f | head -10

# 로컬 테마 ZIP 파일들을 복사하고 구조 분석
COPY redminecrm_theme-1_2_0.zip highrise_theme-1_2_0.zip coffee_theme-1_0_0.zip a1_theme-4_1_2.zip circle_theme-2_2_3.zip /tmp/themes/

# 각 ZIP 파일의 내부 구조를 확인하고 올바르게 설치
RUN cd /tmp/themes && \
    \
    echo "=== RedmineCRM Theme Installation ===" && \
    unzip -q redminecrm_theme-1_2_0.zip -d /tmp/redminecrm_extract && \
    find /tmp/redminecrm_extract -type f | head -10 && \
    cp -r /tmp/redminecrm_extract/* /usr/src/redmine/public/themes/ && \
    \
    echo "=== Highrise Theme Installation ===" && \
    unzip -q highrise_theme-1_2_0.zip -d /tmp/highrise_extract && \
    find /tmp/highrise_extract -type f | head -10 && \
    cp -r /tmp/highrise_extract/* /usr/src/redmine/public/themes/ && \
    \
    echo "=== Coffee Theme Installation ===" && \
    unzip -q coffee_theme-1_0_0.zip -d /tmp/coffee_extract && \
    find /tmp/coffee_extract -type f | head -10 && \
    cp -r /tmp/coffee_extract/* /usr/src/redmine/public/themes/ && \
    \
    echo "=== A1 Theme Installation ===" && \
    unzip -q a1_theme-4_1_2.zip -d /tmp/a1_extract && \
    find /tmp/a1_extract -type f | head -10 && \
    cp -r /tmp/a1_extract/* /usr/src/redmine/public/themes/ && \
    \
    echo "=== Circle Theme Installation ===" && \
    unzip -q circle_theme-2_2_3.zip -d /tmp/circle_extract && \
    find /tmp/circle_extract -type f | head -10 && \
    cp -r /tmp/circle_extract/* /usr/src/redmine/public/themes/ && \
    \
    rm -rf /tmp/themes /tmp/*_extract

# 테마 구조 확인 및 수정
RUN echo "=== Theme Structure Fix ===" && \
    for theme_dir in /usr/src/redmine/public/themes/*/; do \
        theme_name=$(basename "$theme_dir"); \
        echo "Processing: $theme_name"; \
        \
        # stylesheets 디렉토리가 있는지 확인
        if [ -d "$theme_dir/stylesheets" ]; then \
            echo "  ✓ stylesheets directory exists"; \
        else \
            echo "  ! Creating stylesheets directory"; \
            mkdir -p "$theme_dir/stylesheets"; \
        fi; \
        \
        # application.css 파일 확인 및 생성
        if [ -f "$theme_dir/stylesheets/application.css" ]; then \
            echo "  ✓ application.css exists"; \
        elif [ -f "$theme_dir/application.css" ]; then \
            echo "  ! Moving application.css to stylesheets/"; \
            mv "$theme_dir/application.css" "$theme_dir/stylesheets/"; \
        else \
            # CSS 파일을 찾아서 application.css로 복사
            css_file=$(find "$theme_dir" -name "*.css" | head -1); \
            if [ -n "$css_file" ]; then \
                echo "  ! Creating application.css from $css_file"; \
                cp "$css_file" "$theme_dir/stylesheets/application.css"; \
            else \
                echo "  ! Creating minimal application.css"; \
                echo "/* $theme_name theme */" > "$theme_dir/stylesheets/application.css"; \
            fi; \
        fi; \
    done

# 최종 테마 검증
RUN echo "=== Final Theme Verification ===" && \
    echo "All directories in themes:" && \
    find /usr/src/redmine/public/themes -maxdepth 1 -type d | sort && \
    echo "" && \
    echo "Valid themes (with application.css):" && \
    find /usr/src/redmine/public/themes -name "application.css" | while read css_file; do \
        theme_name=$(echo "$css_file" | sed 's|.*themes/||; s|/stylesheets/application.css||'); \
        echo "  ✓ $theme_name"; \
    done && \
    echo "" && \
    chown -R redmine:redmine /usr/src/redmine/public/themes

# 6. Redmine 루트 폴더로 이동하여 플러그인들이 필요로 하는 라이브러리(Gem)를 설치합니다.
WORKDIR /usr/src/redmine

# Gemfile과 Gemfile.lock에서 중복된 puma gem 완전 제거
RUN grep -v 'gem "puma"' Gemfile > Gemfile.tmp && mv Gemfile.tmp Gemfile && \
    sed -i '/puma/d' Gemfile.lock 2>/dev/null || true

# flux_tags 플러그인의 초기화 오류 수정
RUN if [ -f "plugins/flux_tags/init.rb" ]; then \
        sed -i 's/if MAJOR = 6/if MAJOR == 6/' plugins/flux_tags/init.rb; \
    fi

# AI Helper 설정 파일 생성 (경고 제거)
RUN mkdir -p config/ai_helper && \
    echo '{}' > config/ai_helper/config.json

# CVS 경고 해결을 위해 CVS 패키지 설치 (선택사항)
RUN apt-get update && apt-get install -y cvs || echo "CVS installation failed, skipping..."

RUN bundle config set without 'development test' && \
    bundle config set deployment false && \
    bundle install --jobs 4 --retry 3 && \
    gem cleanup stringio

# 7. 컨테이너 시작 시 실행될 스크립트를 이미지 안으로 복사하고 실행 권한을 부여합니다.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 8. 보안을 위해 다시 일반 사용자인 redmine으로 전환합니다.
USER redmine

# 9. 이 이미지로 컨테이너를 시작할 때 실행할 기본 명령을 지정합니다.
ENTRYPOINT ["/entrypoint.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]