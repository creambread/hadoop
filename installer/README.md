# CF_Hadoop_Manager v0.2

hadoop 에코시스템 설치 모듈 <br>
설치 파일인 zookeeper, hadoop, java 등 bin파일은 이 installer 에서 지원하지 않음<br>

## 목표

- hadoop, hbase, spark ... 등등 시스템을 설치를 지원 한다.
- 기동,종료,상태 를 원격지정지에서 확인 할 수 있는 스크립트를 개발 한다.
- 운영중 튜닝을 위한 패치 기능을 지원한다.
- 설정 파일의 간결화를 한다.

## 사용매뉴얼

- 호스트 및 사용자 설정
```
vi $MANAGER_HOME/script/cf-env.sh
```
- cf-env.sh에 세팅한 bin압축파일 수급(java, hadoop, zookeeper ... )
- $MANAGER_HOME/script/cf-installer.sh 실행후 안내 사항대로 설치 (hadoop을 제일먼저 설치해야함)
```
$MANAGER_HOME/script/cf-installer.sh
```
- $MANAGER_HOME/script/cf-command.sh 로 기동종료 테스트
```
$MANAGER_HOME/script/cf-command.sh start hadoop
$MANAGER_HOME/script/cf-command.sh status hadoop
```
- 설치중 에러 발생 및 문제가 발생하면 {MANAGER_HOME}/script/util/delete-cf.sh 를 이용하여 삭제 하거나, 강제로 삭제하고난 후 진행
```
$MANAGER_HOME/script/util/delete-cf.sh hadoop
```

## TODO LIST

- 사용매뉴얼을 상세하게 적어야 한다.
- single node 설치에서 지원해야 한다.
- 외부에 공개한 url이 installer를 포함하고 있어서 10월까지는 루트 디렉토리명을 installer로 명명 이후에는 manager로 변경해야 한다.
