param([string]$Tests = "comprehensive_test", [int]$Seeds = 1) 
if (-not (Test-Path "build")) { New-Item -ItemType Directory -Name "build" } 
$testList = $Tests -split ' ' | Where-Object { $_ -ne '' } 
$seedList = 1..$Seeds 
foreach ($t in $testList) { 
    foreach ($s in $seedList) { 
        Write-Host "   Running $t | SEED=$s" 
        $log  = "build/log_${t}_${s}.log" 
        $ucdb = "build/cov_${t}_${s}.ucdb" 
        $cmd = "vsim -c -voptargs=+acc work.top -classdebug -uvmcontrol=all +UVM_TESTNAME=$t +TESTNAME=$t -sv_seed $s -coverage -do ""coverage save -onexit $ucdb; run -all; quit"" -l $log" 
        Invoke-Expression $cmd 
    } 
} 
Write-Host "=> Regression Complete!" 
