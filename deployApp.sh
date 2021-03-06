#!/bin/sh

frontName=traderfront
webName=traderweb
backName=traderback
domain=cfapps.io
sqlName=tradersql
messagingName=tradermessaging

date

echo Creating service instances
cf create-service cleardb spark tradersql
cf create-service cloudamqp lemur tradermessaging

echo Deploying front end services tier
cf push -p dist/spring-nanotrader-services-1.0.1.BUILD-SNAPSHOT.war -m 1G -t 180 -d $domain -n $frontName --no-start $frontName
cf bind-service $frontName $sqlName
cf bind-service $frontName $messagingName
cf set-env $frontName JBP_CONFIG_OPEN_JDK_JRE '[version: 1.7.0_+]'
cf set-env $frontName JBP_CONFIG_TOMCAT '[tomcat: {version: 7.0.+}]'
cf push -p dist/spring-nanotrader-services-1.0.1.BUILD-SNAPSHOT.war -m 1G -t 180 -d $domain -n $frontName $frontName

echo Making this app available as a service instance
cf cups $frontName -p '{"uri":"http://'$frontName'.'$domain'/api/"}'

echo Deploying the web tier
cf push -p dist/spring-nanotrader-web-1.0.1.BUILD-SNAPSHOT.war -m 1G -t 180 -d $domain -n $webName --no-start $webName
cf set-env $webName JBP_CONFIG_OPEN_JDK_JRE '[version: 1.7.0_+]'
cf set-env $webName JBP_CONFIG_TOMCAT '[tomcat: {version: 7.0.+}]'
cf bind-service $webName $frontName
cf push -p dist/spring-nanotrader-web-1.0.1.BUILD-SNAPSHOT.war -m 1G -t 180 -d $domain -n $webName $webName

echo Deploying back end services tier
cf push -p dist/spring-nanotrader-asynch-services-1.0.1.BUILD-SNAPSHOT.war -m 1G -t 180 -d $domain -n $backName --no-start $backName
cf set-env $backName JBP_CONFIG_OPEN_JDK_JRE '[version: 1.7.0_+]'
cf set-env $backName JBP_CONFIG_TOMCAT '[tomcat: {version: 7.0.+}]'
cf bind-service $backName $sqlName
cf bind-service $backName $messagingName
cf push -p dist/spring-nanotrader-asynch-services-1.0.1.BUILD-SNAPSHOT.war -m 1G -t 180 -d $domain -n $backName $backName

date
