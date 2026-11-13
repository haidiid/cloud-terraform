@echo off
REM ---
REM Copyright (C) 2026 Kasyfillah Haidi Bysr <haidi.id@hotmail.com>
REM Cirebon, GPLv3 License
REM ---

REM ---
REM An executable file designated to run ZooKeeper CLI client on Windows
REM
REM usage:
REM    zookeeper-client.cmd                          opens a shell on haidi.online:443
REM    zookeeper-client.cmd ls /                     runs one command on haidi.online:443
REM    zookeeper-client.cmd -server host:443 ls /    targets another server
REM
REM every variable below can be set before calling this file to override its default
REM    JAVA_HOME                    Java 11 or newer (no default, required by zkCli.cmd)
REM    ZOOKEEPER_HOME               extracted ZooKeeper binary release
REM    ZOOKEEPER_SERVER             host:port of the secureClientPort
REM    ZOOKEEPER_KEYSTORE_PASSWORD  password of credential\tls\zookeeper-client.p12
REM    ZOOKEEPER_TRUSTSTORE_PASSWORD password of credential\tls\truststore.p12
REM ---
setlocal

if not defined JAVA_HOME call :not_defined "JAVA_HOME" "Please define it first" || exit /b 1
if not defined ZOOKEEPER_HOME call :not_defined "ZOOKEEPER_HOME" "Please define it first" || exit /b 1

if not defined ZOOKEEPER_SERVER set "ZOOKEEPER_SERVER=15.134.165.145:443"
if not defined ZOOKEEPER_KEYSTORE_PASSWORD set "ZOOKEEPER_KEYSTORE_PASSWORD=zookeeper-client"
if not defined ZOOKEEPER_TRUSTSTORE_PASSWORD set "ZOOKEEPER_TRUSTSTORE_PASSWORD=ca"

REM keystore and truststore live next to this file, whatever the current directory is.
REM forward slashes: a backslash is an escape character inside quoted JDK_JAVA_OPTIONS values
set "ZOOKEEPER_TLS_DIR=%~dp0credential\tls"
set "ZOOKEEPER_KEYSTORE=%ZOOKEEPER_TLS_DIR%\zookeeper-client.p12"
set "ZOOKEEPER_TRUSTSTORE=%ZOOKEEPER_TLS_DIR%\truststore.p12"

if not exist "%ZOOKEEPER_HOME%\bin\zkCli.cmd" goto :no_zookeeper
REM a source checkout also has bin\zkCli.cmd but no jars, which fails with ClassNotFoundException
if not exist "%ZOOKEEPER_HOME%\lib\zookeeper-*.jar" goto :no_zookeeper
if not exist "%ZOOKEEPER_KEYSTORE%" goto :no_keystore
if not exist "%ZOOKEEPER_TRUSTSTORE%" goto :no_truststore

set "ZOOKEEPER_KEYSTORE=%ZOOKEEPER_KEYSTORE:\=/%"
set "ZOOKEEPER_TRUSTSTORE=%ZOOKEEPER_TRUSTSTORE:\=/%"

REM zkCli.cmd has no CLIENT_JVMFLAGS hook on Windows, so the client TLS settings are handed to the
REM JVM through JDK_JAVA_OPTIONS, which the java launcher reads on its own (Java 9 or newer).
REM    - Netty client socket: TLS is not supported by the default NIO client socket
REM    - TLSv1.3 and its cipher suites must match the server (ssl.protocol / ssl.ciphersuites)
REM    - keystore: client key + certificate presented to the server (ssl.clientAuth=need)
REM    - truststore: the self-signed root CA used to verify the server certificate
REM    - hostnameVerification: the -server host must match the server certificate's SANs
set JDK_JAVA_OPTIONS=-Dzookeeper.clientCnxnSocket=org.apache.zookeeper.ClientCnxnSocketNetty
set JDK_JAVA_OPTIONS=%JDK_JAVA_OPTIONS% -Dzookeeper.client.secure=true
set JDK_JAVA_OPTIONS=%JDK_JAVA_OPTIONS% -Dzookeeper.ssl.protocol=TLSv1.3
set JDK_JAVA_OPTIONS=%JDK_JAVA_OPTIONS% -Dzookeeper.ssl.enabledProtocols=TLSv1.3
set JDK_JAVA_OPTIONS=%JDK_JAVA_OPTIONS% -Dzookeeper.ssl.ciphersuites=TLS_AES_256_GCM_SHA384,TLS_AES_128_GCM_SHA256,TLS_CHACHA20_POLY1305_SHA256
set JDK_JAVA_OPTIONS=%JDK_JAVA_OPTIONS% -Dzookeeper.ssl.hostnameVerification=true
set JDK_JAVA_OPTIONS=%JDK_JAVA_OPTIONS% "-Dzookeeper.ssl.keyStore.location=%ZOOKEEPER_KEYSTORE%"
set JDK_JAVA_OPTIONS=%JDK_JAVA_OPTIONS% -Dzookeeper.ssl.keyStore.type=PKCS12
set JDK_JAVA_OPTIONS=%JDK_JAVA_OPTIONS% "-Dzookeeper.ssl.keyStore.password=%ZOOKEEPER_KEYSTORE_PASSWORD%"
set JDK_JAVA_OPTIONS=%JDK_JAVA_OPTIONS% "-Dzookeeper.ssl.trustStore.location=%ZOOKEEPER_TRUSTSTORE%"
set JDK_JAVA_OPTIONS=%JDK_JAVA_OPTIONS% -Dzookeeper.ssl.trustStore.type=PKCS12
set JDK_JAVA_OPTIONS=%JDK_JAVA_OPTIONS% "-Dzookeeper.ssl.trustStore.password=%ZOOKEEPER_TRUSTSTORE_PASSWORD%"

REM a -server given on the command line comes last, so it wins over the default one
call "%ZOOKEEPER_HOME%\bin\zkCli.cmd" -server %ZOOKEEPER_SERVER% %*
exit /b %ERRORLEVEL%

:not_defined
REM written to stderr, then the script is terminated with a failing exit code
echo Error: %~1 is not defined. %~2 Execution stopped. 1>&2
exit /b 1

:no_zookeeper
echo Error: no ZooKeeper binary release in "%ZOOKEEPER_HOME%" ^(needs bin\zkCli.cmd and lib\zookeeper-*.jar^). 1>&2
echo Set ZOOKEEPER_HOME to an extracted ZooKeeper binary release ^(apache-zookeeper-x.y.z-bin^).
exit /b 1

:no_keystore
echo Error: client keystore not found: "%ZOOKEEPER_KEYSTORE%"
exit /b 1

:no_truststore
echo Error: truststore not found: "%ZOOKEEPER_TRUSTSTORE%"
exit /b 1
