#!/bin/bash
# entrypoint.sh

# 스크립트 실행 중 오류가 발생하면 즉시 중단시킵니다.
set -e

# Redmine 웹 서버를 시작하기 전에,
# 새로 추가된 플러그인들이 필요로 하는 데이터베이스 테이블 등을 생성/수정하는 명령을 실행합니다.
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

# 위 작업이 끝나면, 원래 Redmine 이미지의 기본 시작 스크립트를 실행하여 웹 서버를 구동합니다.
exec /docker-entrypoint.sh "$@"