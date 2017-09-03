# Guidelines  

This packer template builds a basic AWS Amazon Machine Image for use in AWS Elastic Container Service.  Please note that ECS is [currently in beta](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_Windows.html) for Windows container hosts.  AMIs built with this template will be automatically bootstrapped with the latest [aws-ecs-agent](https://github.com/aws/amazon-ecs-agent), built in-line from source, off master.

## Pre-requisites

* Install [Packer](https://www.packer.io/downloads.html)
* Clone this repo

## Running Packer

Update `.\ecs_node.vars.json` with valid region, vpc_id, subnet_id value defining where the AMI should be built.  Note that the subnet will need to be configured to auto-assign public IP addresses to member instances.

Run the following, adding a valid `access_key` / `secret_key`:

```powershell
packer build -var-file=ecs_node.vars.json -var "access_key=" -var "secret_key=" ecs_node.json
```

## Consumption

The resulting AMI can then be referenced in launch configurations etc to add instances to an ECS cluster.  This is usually done by specifying custom userdata on the launched instances, sample below.

```powershell
<powershell>
# Set agent env variables for the Machine context (durable)
[Environment]::SetEnvironmentVariable("ECS_CLUSTER", "${cluster_name}", "Machine")
[Environment]::SetEnvironmentVariable("ECS_ENABLE_TASK_IAM_ROLE", "false", "Machine")

## Start the agent script in the background.
$ecsExeDir = "$env:ProgramFiles\Amazon\ECS"
$script =  "cd '$ecsExeDir'; .\amazon-ecs-agent.ps1"
$jobname = "ECS-Agent-Init"
$jobpath = $env:LOCALAPPDATA + "\Microsoft\Windows\PowerShell\ScheduledJobs\$jobname\ScheduledJobDefinition.xml"
$repeat = (New-TimeSpan -Minutes 1)

if($(Test-Path -Path $jobpath)) {
    Write-Output "Job definition (ECS Agent) already present"
}
else {
    Write-Output "Configuring Job definition (ECS Agent)"
    $scriptblock = [scriptblock]::Create("$script")
    $trigger = New-JobTrigger -At (Get-Date).Date -RepeatIndefinitely -RepetitionInterval $repeat -Once
    $options = New-ScheduledJobOption -RunElevated -ContinueIfGoingOnBattery -StartIfOnBattery
    Register-ScheduledJob -Name $jobname -ScriptBlock $scriptblock -Trigger $trigger -ScheduledJobOption $options -RunNow
    Add-JobTrigger -Name $jobname -Trigger (New-JobTrigger -AtStartup -RandomDelay 00:1:00)        
}
</powershell>
<persist>true</persist>
```

The majority of the content of this repository is sourced from the AWS / Packer documentation.  As Windows on ECS is still in beta, it is, of course subject to change and should be considered of beta quality itself.  Any improvements / fixes via pull request greatly appreciated.