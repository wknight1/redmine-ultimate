// index.ts

// Easypanel 템플릿 유틸리티에서 필요한 함수들을 가져옵니다.
import { Output, randomPassword, Services } from "~templates-utils";
// meta.yaml 스키마에 정의된 입력 타입을 가져옵니다.
import { Input } from "./meta";

// 템플릿을 생성하는 메인 함수
export function generate(input: Input): Output {
  // 서비스 목록을 담을 빈 배열을 만듭니다.
  const services: Services = [];
  // 데이터베이스에 사용할 랜덤 비밀번호를 생성합니다.
  const databasePassword = randomPassword();
  // 보안 강화를 위해 Redmine Secret Key도 랜덤하게 생성합니다.
  const secretKeyBase = randomPassword(64);

  // 1. Redmine 앱 서비스 정의
  services.push({
    type: "app",
    data: {
      serviceName: input.appServiceName, // meta.yaml에서 받은 앱 서비스 이름
      // Redmine 실행에 필요한 환경 변수들을 설정합니다.
      env: [
        `REDMINE_DB_MYSQL=$(PROJECT_NAME)_${input.databaseServiceName}`,
        `REDMINE_DB_PORT=3306`,
        `REDMINE_DB_USERNAME=mysql`,
        `REDMINE_DB_PASSWORD=${databasePassword}`,
        `REDMINE_DB_DATABASE=$(PROJECT_NAME)`,
        `REDMINE_SECRET_KEY_BASE=supersecretkey`,
        `REDMINE_DEFAULT_THEME=opale`, // 기본 테마를 'Opale'로 설정
      ].join("\n"),
      // 사용할 Docker 이미지를 지정합니다.
      source: {
        type: "image",
        image: input.appServiceImage, // meta.yaml에서 받은 이미지 주소
      },
      // 외부 도메인과 앱의 포트를 연결합니다.
      domains: [
        {
          host: "$(EASYPANEL_DOMAIN)",
          port: 80, 
        },
      ]
    },
  });

  // 2. MySQL 데이터베이스 서비스 정의
  services.push({
    type: "mysql",
    data: {
      serviceName: input.databaseServiceName, // meta.yaml에서 받은 DB 서비스 이름
      password: databasePassword, // 앱 서비스와 동일한 비밀번호 사용
    },
  });

  // 최종 서비스 목록을 반환합니다.
  return { services };
}