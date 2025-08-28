#!/bin/bash
# entrypoint.sh

set -e

echo "=== Redmine Ultimate Pack Initialization ==="

if [ "$1" = 'rails' ] && [ "$2" = 'server' ]; then
    echo "Step 1: Running original Redmine initialization..."
    # database.yml 생성 및 초기 설정을 위해 원본 entrypoint 스크립트의 초기화 부분만 실행
    source /docker-entrypoint.sh > /dev/null 2>&1 || true
    
    echo "Step 2: Waiting for database connection..."
    max_attempts=30
    attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1; then
            echo "✓ Database connection successful!"
            break
        fi
        
        echo "Waiting for database... (attempt $((attempt + 1))/$max_attempts)"
        sleep 5
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -eq $max_attempts ]; then
        echo "✗ Failed to connect to database after $max_attempts attempts"
        exit 1
    fi
    
    echo "Step 3: Running core Redmine migrations..."
    if ! bundle exec rake db:migrate RAILS_ENV=production; then
        echo "✗ Core migrations failed, but continuing..."
    else
        echo "✓ Core migrations completed"
    fi
    
    echo "Step 4: Loading default Redmine data..."
    if ! bundle exec rake redmine:load_default_data RAILS_ENV=production REDMINE_LANG=ko; then
        echo "⚠ Default data loading failed or already exists, continuing..."
    else
        echo "✓ Default data loaded"
    fi
    
    echo "Step 5: Running plugin migrations..."
    if ! bundle exec rake redmine:plugins:migrate RAILS_ENV=production; then
        echo "⚠ Some plugin migrations failed, but continuing..."
        # 각 플러그인별로 개별적으로 마이그레이션 시도
        for plugin_dir in /usr/src/redmine/plugins/*/; do
            if [ -d "$plugin_dir" ]; then
                plugin_name=$(basename "$plugin_dir")
                echo "Trying to migrate plugin: $plugin_name"
                bundle exec rake redmine:plugins:migrate NAME="$plugin_name" RAILS_ENV=production || echo "Plugin $plugin_name migration failed"
            fi
        done
    else
        echo "✓ Plugin migrations completed"
    fi
    
    echo "Step 6: Generating secret token..."
    bundle exec rake generate_secret_token RAILS_ENV=production || true
    
    echo "Step 7: Starting Rails server..."
    # 환경 변수 설정으로 로그 레벨 조정
    export RAILS_LOG_LEVEL=info
    
    echo "=== Redmine Ultimate Pack Ready ==="
    exec bundle exec rails server -b 0.0.0.0 -e production
else
    # 다른 명령어는 원본 entrypoint로 전달
    exec /docker-entrypoint.sh "$@"
fi