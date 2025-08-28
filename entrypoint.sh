#!/bin/bash
# entrypoint.sh

set -e

# 먼저 원본 Redmine entrypoint를 백그라운드에서 실행하여 database.yml 생성
echo "Initializing Redmine..."

# database.yml이 생성될 때까지 기다림
if [ ! -f "config/database.yml" ]; then
    echo "Waiting for database configuration to be created..."
    # 원본 docker-entrypoint.sh의 database.yml 생성 부분만 실행
    /docker-entrypoint.sh echo "Database config created" > /dev/null 2>&1 || true
    
    # database.yml이 생성될 때까지 잠시 대기
    sleep 2
fi

# 데이터베이스 연결 확인
echo "Checking database connection..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if bundle exec rails runner "puts 'Database connected successfully'" RAILS_ENV=production 2>/dev/null; then
        echo "Database connection verified!"
        break
    fi
    
    echo "Waiting for database... (attempt $((attempt + 1))/$max_attempts)"
    sleep 5
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo "Failed to connect to database after $max_attempts attempts"
    exit 1
fi

# 플러그인 마이그레이션 실행
echo "Running plugin migrations..."
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

echo "Starting Redmine server..."
# 이제 정상적으로 서버 시작
exec /docker-entrypoint.sh "$@"