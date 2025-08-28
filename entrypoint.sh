#!/bin/bash
# entrypoint.sh

set -e

echo "Initializing Redmine with plugins..."

# 임시로 원본 entrypoint의 내용을 실행하되, 서버는 시작하지 않음
if [ "$1" = 'rails' ] && [ "$2" = 'server' ]; then
    # database.yml 생성 및 초기 설정을 위해 원본 entrypoint 스크립트의 초기화 부분만 실행
    source /docker-entrypoint.sh
    
    # 데이터베이스가 준비될 때까지 대기
    echo "Waiting for database to be ready..."
    while ! bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1; do
        echo "Database not ready, waiting..."
        sleep 3
    done
    
    echo "Database is ready. Running plugin migrations..."
    
    # 플러그인 마이그레이션 실행 (경고 억제)
    RAILS_ENV=production bundle exec rake redmine:plugins:migrate 2>/dev/null || \
    RAILS_ENV=production bundle exec rake redmine:plugins:migrate
    
    echo "Plugin migrations completed. Starting Rails server..."
    
    # Asset precompilation warnings 억제를 위한 환경 변수 설정
    export RAILS_ASSET_PRECOMPILATION_SILENT=true
    export RAILS_LOG_LEVEL=error
    
    # 이제 Rails 서버 시작
    exec bundle exec rails server -b 0.0.0.0 -e production
else
    # 다른 명령어는 원본 entrypoint로 전달
    exec /docker-entrypoint.sh "$@"
fi