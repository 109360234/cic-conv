wvSetPosition -win $_nWave1 {("G1" 0)}
wvOpenFile -win $_nWave1 {/home/t109360234/Desktop/conv2019/CONV.fsdb}
wvResizeWindow -win $_nWave1 -8 -8 1536 801
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/testfixture"
wvSetPosition -win $_nWave1 {("G1" 6)}
wvSetPosition -win $_nWave1 {("G1" 6)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/testfixture/L0_EXP0\[0:4095\]} \
{/testfixture/L0_EXP1\[0:4095\]} \
{/testfixture/L1_EXP0\[0:1023\]} \
{/testfixture/L1_EXP1\[0:1023\]} \
{/testfixture/L2_EXP\[0:2047\]} \
{/testfixture/PAT\[0:4095\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 1 2 3 4 5 6 )} 
wvSetPosition -win $_nWave1 {("G1" 6)}
wvGetSignalClose -win $_nWave1
wvResizeWindow -win $_nWave1 -8 -8 1536 801
wvExit
