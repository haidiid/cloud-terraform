@echo off
setlocal

pushd "%~dp0" || exit /b 1
terraform plan -input=false -var-file="local.tfvars" -var-file="zookeeper-server\local.tfvars"
set "terraform_exit_code=%ERRORLEVEL%"
if not "%terraform_exit_code%"=="0" goto cleanup

terraform apply -auto-approve -input=false -var-file="local.tfvars" -var-file="zookeeper-server\local.tfvars"
set "terraform_exit_code=%ERRORLEVEL%"

:cleanup
popd

exit /b %terraform_exit_code%