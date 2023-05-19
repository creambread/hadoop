# Hadoop_Installer v0.1

hadoop 에코시스템 설치 모듈 <br>
기본적으로 zookeeper와 hadoop, java 설치 tar파일을 따로 구해야 한다 <br>
공개는 했지만 아직 잘모르고 사용하기엔 부족함이 있음

## 목표

- hadoop, hbase, spark ... 등등 시스템을 설치를 지원 한다.
- 기동,종료,상태 를 원격지정지에서 확인 할 수 있는 스크립트를 개발 한다.
- 운영중 튜닝을 위한 패치 기능을 지원한다.
- 설정 파일의 간결화를 한다.

## TODO LIST

- hadoop 외의 솔루션(trendmap)에 대해 정리 할 필요가 있음
- 사용매뉴얼을 상세하게 적어야함
- single node 설치에서 지원해야함
- ha(이중화구성) 이 아닌 모드에서도 설치를 지원해야함
