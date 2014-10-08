[CmdletBinding()]
Param(
   [String]$ConfigFile,
   [String]$Server = "",
   [String]$Username = "",
   [String]$Password = "",
   [String]$Database = "",
   [String]$UsernameField = "",
   [String]$UserOU = "",
   [String]$BaseUserHomeDir = "",
   [String]$PrimaryGroup = "",
   [String[]]$SecondaryGroup = @(),
   [String]$Query = "",
   [Bool]$ReportOnly = $true,
   [String]$OracleModule = "..\Modules\ODP.NET_Managed121012_x64\odp.net\managed\common\Oracle.ManagedDataAccess.dll",
   [Bool]$OutputResults = $false,
   [String]$OutputResultsFile = "output.txt",
   [String]$InputCSVFile = "db.csv",
   [String]$OutputCSVFile = "db.csv",
   [Bool]$SendEmail = $false,
   [String]$EmailTo = "",
   [String]$EmailFrom = "",
   [String]$EmailServer = "",
   [String]$EmailSubject = "",
   [String]$EmailBodyHeader = "",
   [Bool]$DebugProgram,
   [Bool]$NoAD = $true,
   [Bool]$NoDB = $false,
   [Bool]$NoCreate = $true,
   [Bool]$NoDelete = $true,
   [Bool]$NoUpdate = $false,
   [Bool]$NoGroupAdd = $false,
   [Bool]$NoGroupDelete = $false,
   [Bool]$NoParameterSync = $false,
   [Bool]$NoEnable = $false,
   [Bool]$NoDisable = $false,
   [Bool]$UseCSV = $false,
   [Bool]$SaveAsCSV = $true
)
### END OF PARAMETERS ###

Try{
   Import-Module ActiveDirectory
}Catch{
   Write-Host $_.Exception.Message
   Write-Host $_.Exception.ItemName
   Write-Host "Please install the ActiveDirectory Module"
   Exit 1
}

### FUNCTIONS ###
####################### 
function Get-Type 
{ 
    param($type) 
 
$types = @( 
'System.Boolean', 
'System.Byte[]', 
'System.Byte', 
'System.Char', 
'System.Datetime', 
'System.Decimal', 
'System.Double', 
'System.Guid', 
'System.Int16', 
'System.Int32', 
'System.Int64', 
'System.Single', 
'System.UInt16', 
'System.UInt32', 
'System.UInt64') 
 
    if ( $types -contains $type ) { 
        Write-Output "$type" 
    } 
    else { 
        Write-Output 'System.String' 
         
    } 
} #Get-Type 
 
####################### 
<# 
.SYNOPSIS 
Creates a DataTable for an object 
.DESCRIPTION 
Creates a DataTable based on an objects properties. 
.INPUTS 
Object 
    Any object can be piped to Out-DataTable 
.OUTPUTS 
   System.Data.DataTable 
.EXAMPLE 
$dt = Get-psdrive| Out-DataTable 
This example creates a DataTable from the properties of Get-psdrive and assigns output to $dt variable 
.NOTES 
Adapted from script by Marc van Orsouw see link 
Version History 
v1.0  - Chad Miller - Initial Release 
v1.1  - Chad Miller - Fixed Issue with Properties 
v1.2  - Chad Miller - Added setting column datatype by property as suggested by emp0 
v1.3  - Chad Miller - Corrected issue with setting datatype on empty properties 
v1.4  - Chad Miller - Corrected issue with DBNull 
v1.5  - Chad Miller - Updated example 
v1.6  - Chad Miller - Added column datatype logic with default to string 
v1.7 - Chad Miller - Fixed issue with IsArray 
.LINK 
http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx 
#> 
function Out-DataTable 
{ 
    [CmdletBinding()] 
    param([Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)] [PSObject[]]$InputObject) 
 
    Begin 
    { 
        $dt = new-object Data.datatable   
        $First = $true  
    } 
    Process 
    { 
        foreach ($object in $InputObject) 
        { 
            $DR = $DT.NewRow()   
            foreach($property in $object.PsObject.get_properties()) 
            {   
                if ($first) 
                {   
                    $Col =  new-object Data.DataColumn   
                    $Col.ColumnName = $property.Name.ToString()   
                    if ($property.value) 
                    { 
                        if ($property.value -isnot [System.DBNull]) { 
                            $Col.DataType = [System.Type]::GetType("$(Get-Type $property.TypeNameOfValue)") 
                         } 
                    } 
                    $DT.Columns.Add($Col) 
                }   
                if ($property.Gettype().IsArray) { 
                    $DR.Item($property.Name) =$property.value | ConvertTo-XML -AS String -NoTypeInformation -Depth 1 
                }   
               else { 
                    $DR.Item($property.Name) = $property.value 
                } 
            }   
            $DT.Rows.Add($DR)   
            $First = $false 
        } 
    }  
      
    End 
    { 
        Write-Output @(,($dt)) 
    } 
 
} #Out-DataTable

Function Get-IniContent
{
    <#
    .Synopsis
        Gets the content of an INI file      
    .Description
        Gets the content of an INI file and returns it as a hashtable
    .Notes
        Author    : Oliver Lipkau <oliver@lipkau.net>
        Blog      : http://oliver.lipkau.net/blog/
        Date      : 2014/06/23
        Version   : 1.1
        #Requires -Version 2.0
    .Inputs
        System.String
    .Outputs
        System.Collections.Hashtable
    .Parameter FilePath
        Specifies the path to the input file.
    .Example
        $FileContent = Get-IniContent "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent
    .Example
        $inifilepath | $FileContent = Get-IniContent
        -----------
        Description
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent
    .Example
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"
        C:\PS>$FileContent["Section"]["Key"]
        -----------
        Description
        Returns the key "Key" of the section "Section" from the C:\settings.ini file
    .Link
        Out-IniFile
    #>
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [string]$FilePath
    )
    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}   
    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"       
        $ini = @{}
        switch -regex -file $FilePath
        {
            "^\[(.+)\]$" # Section
            {
                $section = $matches[1]
                $ini[$section] = @{}
                $CommentCount = 0
            }
            "^(;.*)$" # Comment
            {
                if (!($section))
                {
                    $section = "No-Section"
                    $ini[$section] = @{}
                }
                $value = $matches[1]
                $CommentCount = $CommentCount + 1
                $name = "Comment" + $CommentCount
                $ini[$section][$name] = $value
            } 
            "(.+?)\s*=\s*(.*)" # Key
            {
                if (!($section))
                {
                    $section = "No-Section"
                    $ini[$section] = @{}
                }
                $name,$value = $matches[1..2]
                If($ini[$section][$name].Length -gt 0){
  	 	   $ini[$section][$name] += "|$value"
 		}Else{
                   $ini[$section][$name] = $value
		}
            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $path"
        Return $ini
    }        
    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function Get-All-Users-From-DB(){
   Try{
      Add-Type -Path $OracleModule
   }Catch{
      Write-Host $_.Exception.Message
      Write-Host $_.Exception.ItemName
      Write-Host "The module can be downloaded from: http://www.oracle.com/technetwork/topics/dotnet/index-085163.html"
      Exit 1
   }
   $con = New-Object Oracle.ManagedDataAccess.Client.OracleConnection("User Id=$Username;Password=$Password;Data Source=$Server/$Database")
   Try{
      $adapter = New-Object Oracle.ManagedDataAccess.Client.OracleDataAdapter($Query,$con)
   }Catch{
      Write-Host $_.Exception.Message
      Write-Host $_.Exception.ItemName
      Exit 1
   }
   $table = New-Object System.Data.DataTable
   $adapter.Fill($table) | Out-Null
   
   If($SaveAsCSV){
   ## TODO: Save from table so query isn't run twice
      $ds = New-Object System.Data.DataSet
      $adapter.Fill($ds) >$null| Out-Null
      $ds.Tables[0] | Export-CSV $OutputCSVFile -notypeinformation
      If($DebugProgram){$now = Get-Date; Write-Host "Finished Exporting Database at: $now"}
   }
   Return ,$table
}

#Function Does-User-Exist($username){
#   #If($DebugProgram){Write-Host "Checking user: $username"}
#   Try{
#      If(Get-ADUser -LDAPFilter "(sAMAccountName=$username)"){
#         Return $true
#      }Else{
#         Return $false
#      }
#   }Catch{
#      Write-Host $_.Exception.Message
#      Write-Host $_.Exception.ItemName
#   }
#}

Function Get-LDAP-Param($username, $aldapparam){
   If($DebugProgram){
      #Write-Host "Checking parameter:$aldapparam for user: $username"
   }
   Try{
      $UserParamValue = Get-ADUser -LDAPFilter "(sAMAccountName=$username)" -Properties $aldapparam
      If($UserParamValue.$aldapparam.Length -eq 0){
         Return ""
      }Else{
         Return $UserParamValue.$aldapparam
      }
   }Catch{
      Write-Host $_.Exception.Message
      Write-Host $_.Exception.ItemName
   }
}

#Function IsUserEnabled($username){
#   $user = (Get-ADUser -LDAPFilter "(sAMAccountName=$username)" -Properties Name,sAMAccountType,Enabled,LockedOut,PasswordLastSet)
#   Return $user.Enabled
#}

#Function IsUserInGroup($username, $groupname){
#   $user = (Get-ADUser -LDAPFilter "(sAMAccountName=$username)" -Properties MemberOf,sAMAccountName | Select-Object MemberOf,sAMAccountName)
#   if (-not ($user.MemberOf -match $groupname)){
#        return $false
#   }
#   else{
#        return $true
#   }   
#}

Function AddUserToGroup($username, $groupname){
   #$user = (Get-ADUser -Identity $username -Properties MemberOf,sAMAccountName | Select-Object MemberOf,sAMAccountName)
   Add-ADGroupMember -Identity $groupname -Members $username
}

Function RemoveUserFromGroup($username, $groupname){
   #$user = (Get-ADUser -Identity $username -Properties MemberOf,sAMAccountName | Select-Object MemberOf,sAMAccountName)
   Remove-ADGroupMember -Identity $groupname -Members $username
}

Function Create-ADUser($username){
   Return $true
}

Function Delete-ADUser($username){
   Return $true
}

### END OF FUNCTIONS...DO I WANT CMDLETS INSTEAD?? ###

### READ A CONFIGURATION FILE IF ASKED TO (GOTTA BE A BETTER WAY!!)###
If($ConfigFile.Length -gt 0){ 
   $ConfigData = Get-IniContent($ConfigFile) 
   If($ConfigData["General"]["ReportOnly"].Length -gt 0){ $ReportOnly = $ConfigData["General"]["ReportOnly"] }
   If($ConfigData["General"]["Debug"].Length -gt 0){ If($ConfigData["General"]["Debug"] -eq "True"){ $DebugProgram = $true }Else{ $DebugProgram = $false} }
   If($ConfigData["General"]["OracleModule"].Length -gt 0){ $OracleModule = $ConfigData["General"]["OracleModule"] }
   If($ConfigData["Database"]["Server"].Length -gt 0){ $Server = $ConfigData["Database"]["Server"] }
   If($ConfigData["Database"]["Username"].Length -gt 0){ $Username = $ConfigData["Database"]["Username"] }
   If($ConfigData["Database"]["Password"].Length -gt 0){ $Password = $ConfigData["Database"]["Password"] }
   If($ConfigData["Database"]["Database"].Length -gt 0){ $Database = $ConfigData["Database"]["Database"] }
   If($ConfigData["Database"]["UsernameField"].Length -gt 0){ $UsernameField = $ConfigData["Database"]["UsernameField"] }
   If($ConfigData["Database"]["Query"].Length -gt 0){ $Query = $ConfigData["Database"]["Query"] }
   If($ConfigData["EnableIf"].Length -gt 0){
      $AllEnableIfCriteria = $ConfigData["EnableIf"]
      #$AllEnableIfCriteria.GetEnumerator() | % {$_.Key+"`t"+$_.Value}
   }
   If($ConfigData["LDAP"]["UserOU"].Length -gt 0){ $UserOU = $ConfigData["LDAP"]["UserOU"] }
   If($ConfigData["LDAP"]["BaseUserHomeDir"].Length -gt 0){ $BaseUserHomeDir = $ConfigData["LDAP"]["BaseUserHomeDir"] }
   If($ConfigData["LDAP"]["PrimaryGroup"].Length -gt 0){ $PrimaryGroup = $ConfigData["LDAP"]["PrimaryGroup"] }
   If($ConfigData["EmailReport"]["SendEmail"].Length -gt 0){ If($ConfigData["EmailReport"]["SendEmail"] -eq "True"){ $SendEmail = $true }Else{ $SendEmail = $false} }
   If($ConfigData["EmailReport"]["EmailTo"].Length -gt 0){ $EmailTo = $ConfigData["EmailReport"]["EmailTo"] }
   If($ConfigData["EmailReport"]["EmailFrom"].Length -gt 0){ $EmailFrom = $ConfigData["EmailReport"]["EmailFrom"] }
   If($ConfigData["EmailReport"]["EmailServer"].Length -gt 0){ $EmailServer = $ConfigData["EmailReport"]["EmailServer"] }
   If($ConfigData["EmailReport"]["EmailSubject"].Length -gt 0){ $EmailSubject = $ConfigData["EmailReport"]["EmailSubject"] }
   If($ConfigData["SecondaryGroup"].Length -gt 0){
      $AllMyGroups = $ConfigData["SecondaryGroup"]
      #$AllMyGroups.GetEnumerator() | % {$_.Key+"`t"+$_.Value}
   }
   If($ConfigData["LDAPParam"].Length -gt 0){
      $AllLDAPParams = $ConfigData["LDAPParam"]
      #$AllLDAPParams.GetEnumerator() | % {$_.Key+"`t"+$_.Value}  
   }
   If($ConfigData["Troubleshoot"]["NoDB"].Length -gt 0){ If($ConfigData["Troubleshoot"]["NoDB"] -eq "True"){ $NoDB = $true }Else{ $NoDB = $false} }
   If($ConfigData["Troubleshoot"]["NoAD"].Length -gt 0){ If($ConfigData["Troubleshoot"]["NoAD"] -eq "True"){ $NoAD = $true }Else{ $NoAD = $false} }
   If($ConfigData["Troubleshoot"]["NoCreate"].Length -gt 0){ If($ConfigData["Troubleshoot"]["NoCreate"] -eq "True"){ $NoCreate = $true }Else{ $NoCreate = $false} }
   If($ConfigData["Troubleshoot"]["NoDelete"].Length -gt 0){ If($ConfigData["Troubleshoot"]["NoDelete"] -eq "True"){ $NoDelete = $true }Else{ $NoDelete = $false} }
   If($ConfigData["Troubleshoot"]["NoUpdate"].Length -gt 0){ If($ConfigData["Troubleshoot"]["NoUpdate"] -eq "True"){ $NoUpdate = $true }Else{ $NoUpdate = $false} }
   If($ConfigData["Troubleshoot"]["NoGroupAdd"].Length -gt 0){ If($ConfigData["Troubleshoot"]["NoGroupAdd"] -eq "True"){ $NoGroupAdd = $true }Else{ $NoGroupAdd = $false} }
   If($ConfigData["Troubleshoot"]["NoGroupDelete"].Length -gt 0){ If($ConfigData["Troubleshoot"]["NoGroupDelete"] -eq "True"){ $NoGroupDelete = $true }Else{ $NoGroupDelete = $false} }
   If($ConfigData["Troubleshoot"]["NoParameterSync"].Length -gt 0){ If($ConfigData["Troubleshoot"]["NoParameterSync"] -eq "True"){ $NoParameterSync = $true }Else{ $NoParameterSync = $false} }
   If($ConfigData["Troubleshoot"]["NoEnable"].Length -gt 0){ If($ConfigData["Troubleshoot"]["NoEnable"] -eq "True"){ $NoEnable = $true }Else{ $NoEnable = $false} }
   If($ConfigData["Troubleshoot"]["NoDisable"].Length -gt 0){ If($ConfigData["Troubleshoot"]["NoDisable"] -eq "True"){ $NoDisable = $true }Else{ $NoDisable = $false} }
}

$MessageBody = ""

If($DebugProgram){
   $CommandName = $PSCmdlet.MyInvocation.InvocationName;
   # Get the list of parameters for the command
   $ParameterList = (Get-Command -Name $CommandName).Parameters;

   # Grab each parameter value, using Get-Variable
   foreach ($Parameter in $ParameterList) {
      Get-Variable -Name $Parameter.Values.Name -ErrorAction SilentlyContinue;
   }
   If($DebugProgram){$now = Get-Date; Write-Host "`n$($MyInvocation.MyCommand.Name):: Program started $now"}
}

### GET ALL USERS IN DATASTORE ###
If(-Not($NoDB)){
   If(-Not($UseCSV)){
      If($DebugProgram){$now = Get-Date; Write-Host "Started Querying Database at: $now"}
      $AllDBData = Get-All-Users-From-DB
      If($DebugProgram){$now = Get-Date; Write-Host "Finished Querying Database at: $now"}
      Write-Host "All Records:" $AllDBData.Rows.Count
      $AllDBUsers = $AllDBData | Select * | Sort-Object -Property $UsernameField -Unique
      If($DebugProgram){$now = Get-Date; Write-Host "Unique Records:" $AllDBUsers.Count}
   }Else{
      If($DebugProgram){$now = Get-Date; Write-Host "Started Querying CSV at: $now"}
      $AllDBData = Import-CSV $InputCSVFile | Out-DataTable
      If($DebugProgram){$now = Get-Date; Write-Host "Finished Querying CSV at: $now"}
      Write-Host "All Records:" $AllDBData.Rows.Count
      $AllDBUsers = $AllDBData | Select * | Sort-Object -Property $UsernameField -Unique
      If($DebugProgram){$now = Get-Date; Write-Host "Unique Records:" $AllDBUsers.Count}
   }
}
######

### CREATE ACCOUNTS ###
If(-Not($NoCreate)){
   ### GET ALL USERS IN ACTIVE DIRECTORY ###
   If(-Not($NoAD)){
      If($DebugProgram){$now = Get-Date; Write-Host "Started Querying Active Directory at: $now"}
      $AllADUsers = Get-ADUser -Filter * -Property memberOf,Enabled
      If($DebugProgram){$now = Get-Date; Write-Host "Finished Querying Active Directory at: $now"}
   }
   ######

   If($DebugProgram){$now = Get-Date; Write-Host "Started Creating Accounts at: $now"}
   Compare-Object $AllADUsers.sAMAccountName $AllDBUsers.$UsernameField | Where-Object {$_.SideIndicator -eq "=>"} | ForEach-Object {
      If($_.InputObject.Length -gt 1){
	 If(-Not($ReportOnly)){
	    $Return = Create-ADUser($_.InputObject)
            If($Return){
	       $MessageBody += "Successfully created account: "+$_.InputObject | Out-String
            }Else{
               $MessageBody += "Error creating account: "+$_.InputObject | Out-String
            }
	 }Else{
            $MessageBody += "Please create account: "+$_.InputObject | Out-String
         }
      }
   }
   If($DebugProgram){$now = Get-Date; Write-Host "Finished Creating Accounts at: $now"}
}
######

$DeletedUsers = @()
### DELETE ACCOUNTS ###
If(-Not($NoDelete)){
   ### GET ALL USERS IN ACTIVE DIRECTORY -make a function... ###
   If(-Not($NoAD)){
      If($DebugProgram){$now = Get-Date; Write-Host "Started Querying Active Directory at: $now"}
      $AllADUsers = Get-ADUser -Filter * -Property memberOf,Enabled -SearchBase $UserOU -SearchScope OneLevel
      If($DebugProgram){$now = Get-Date; Write-Host "Finished Querying Active Directory at: $now"}
   }
   ######

   If($DebugProgram){$now = Get-Date; Write-Host "Started Deleting Accounts at: $now"}
   Compare-Object $AllADUsers.sAMAccountName $AllDBUsers.$UsernameField | Where-Object {$_.SideIndicator -eq "<="} | ForEach-Object {
      $DeletedUsers += $_.InputObject
      If(-Not($ReportOnly)){
         $Return = Delete-ADUser($_.InputObject)
         If($Return){
            $MessageBody += "Successfully deleted account: "+$_.InputObject | Out-String
         }Else{
            $MessageBody += "Error deleting account: "+$_.InputObject | Out-String
         }
      }Else{
         $MessageBody += "Please delete account: "+$_.InputObject | Out-String
      }
   }
   If($DebugProgram){$now = Get-Date; Write-Host "Finished Deleting Accounts at: $now"}
}
######

### UPDATE ACCOUNT ATTRIBUTES ###  
If(-Not($NoUpdate)){
   If($DebugProgram){$now = Get-Date; Write-Host "Started Updating Accounts at: $now"}
    
   ### GET ALL USERS IN ACTIVE DIRECTORY -make a function... ###
   If(-Not($NoAD)){
      If($DebugProgram){$now = Get-Date; Write-Host "Started Querying Active Directory at: $now"}
      $AllADUsers = Get-ADUser -Filter * -Property memberOf,Enabled -SearchBase $UserOU -SearchScope OneLevel
      If($DebugProgram){$now = Get-Date; Write-Host "Finished Querying Active Directory at: $now"}
   }
   ######
   
   ### GROUPS MANGEMENT ###
   If(-Not($NoGroupAdd)){
      If($DebugProgram){$now = Get-Date; Write-Host "Started Group Management at: $now"}
      $AllMyGroups = $ConfigData["SecondaryGroup"]
      $AllMyGroups.GetEnumerator() | % {	       
         $newDataView = New-Object System.Data.DataView($AllDBData)
         $aGroup = $_.Key
         $aQuery = $_.Value.Replace("|"," OR ")
         $newDataView.RowFilter = $aQuery
	 $AllUsersInGroup = $newDataView | Select * | Sort-Object -Property $UsernameField -Unique
	 $AllADUsersInGroup = $AllADUsers | Where-Object {$_.memberOf -iLike "CN="+$aGroup+",*" -And $_.Enabled -eq $true}
	 If($AllADUsersInGroup.Count -gt 0 -And $AllUsersInGroup.Count -gt 0){
	    $AllTargetedUsers = $AllADUsers | Select-Object sAMAccountName
            Compare-Object $AllADUsersInGroup.sAMAccountName $AllUsersInGroup.$UsernameField | Where-Object {$_.SideIndicator -eq "=>"} | ForEach-Object { 
	       If($AllTargetedUsers.sAMAccountName -Contains $_.InputObject -And $DeletedUsers -NotContains $_.InputObject){
                  $MessageBody += "Add User: "+$_.InputObject+" to Group: "+$aGroup | Out-String
	       }       
 	    }
            Compare-Object $AllADUsersInGroup.sAMAccountName $AllUsersInGroup.$UsernameField | Where-Object {$_.SideIndicator -eq "<="} | ForEach-Object { 
	       If($AllTargetedUsers.sAMAccountName -Contains $_.InputObject -And $DeletedUsers -NotContains $_.InputObject){
	          $MessageBody += "Remove User: "+$_.InputObject+" from Group: "+$aGroup | Out-String  
               }
            }
         }
      }
      If($DebugProgram){$now = Get-Date; Write-Host "Finished Group Management at: $now"}
   }    
   ######
 
   ### PARAMETER MANAGEMENT ###
   If(-Not($NoParameterSync)){
      If($DebugProgram){$now = Get-Date; Write-Host "Started Parameter Management at: $now"}
      $AllTargetedUsers = $AllADUsers | Select-Object sAMAccountName
      ForEach($aDBUser in $AllDBUsers){
         If($aDBUser.$UsernameField.Length -gt 1 -And $AllTargetedUsers.sAMAccountName -Contains $aDBUser.$UsernameField -And $DeletedUsers -NotContains $aDBUser.$UsernameField){
            ### PARAMETER MANAGEMENT ###
            $AllLDAPParams = $ConfigData["LDAPParam"]
            $AllLDAPParams.GetEnumerator() | % {
               ForEach($aVal in $_.Value.Split("|")){
                  $ldapvalue = $_.Key
		  $sqlvalue = $aVal
		  $maxParams = $sqlvalue.Split("{").Length - 1
 		  If($sqlvalue.Contains("{")){
		     $temp = $sqlvalue
		     For($i=0;$i -lt $maxParams;$i++){
                        $sqlcrit = $temp.Split("{")[$i+1].Split("}")[0]
		        $replace = "{"+$sqlcrit+"}"
		        $sqlval = $aDBUser.$sqlcrit.ToString().Trim()
			If($sqlval.Length -eq 0){
                           If($sqlvalue.Contains(" "+$replace)){
			      $sqlvalue = $sqlvalue.Replace(" "+$replace,"")			   
			   }Else{
			      $sqlvalue = $sqlvalue.Replace($replace,"")
			   }
			}Else{
			   $sqlvalue = $sqlvalue.Replace($replace,$sqlval)
	                }
		     }
		  }
		  If($sqlvalue.Length -gt 0){
		     If($ldapvalue.ToLower() -eq "initials"){
		        $sqlvalue = $sqlvalue.Replace(".", "")
                        $sqlvalue = $sqlvalue.Replace("'", "")
                        $sqlvalue = $sqlvalue.Replace("``", "")
                        $sqlvalue = $sqlvalue.Replace(",", "")
                        $sqlvalue = $sqlvalue.Replace("-", "")
                        $sqlvalue = $sqlvalue.Substring(0, 1)
                        $sqlvalue = $sqlvalue.ToUpper()+"."             
		     }
		  }
	          #Write-Host "Param Name:"$_.Key
	          #Write-Host "Param Value:"$aVal
		  #Write-Host "Modified:"$sqlvalue
                  $sqlvalue = $sqlvalue.Trim()
		  $username = $aDBUser.$UsernameField
                  $ldapparam = $_.Key.ToString().Trim()
		  $aldapparamvalue = Get-LDAP-Param $username $ldapparam
		  If($aldapparamvalue -ne $sqlvalue){ $MessageBody += "Update parameter: $ldapparam for user: $username to value: $sqlvalue from value: $aldapparamvalue" | Out-String}
	       }
            }  
         }Else{
            If(-Not($aDBUser.$UsernameField.Length -gt 1)){
               $MessageBody += "ERROR: Please update email address in database for user:"
               $MessageBody += $aDBUser | Out-String
            }
         }
         ######
      }
      $now = Get-Date; Write-Host "Finished Parameter Management at: $now"
   }
   ### ENABLE USERS ###
   If(-Not($NoEnable)){
      If($DebugProgram){$now = Get-Date; Write-Host "Started Enabling Users at: $now"}
      $newDataView = New-Object System.Data.DataView($AllDBData)
      $AllEnableCriteria = $ConfigData["EnableIf"]["Enable"]
      $aQuery = $AllEnableCriteria.Replace("|"," OR ")
      $newDataView.RowFilter = $aQuery
      $AllUsersToEnable = $newDataView | Select * | Sort-Object -Property $UsernameField -Unique 
      $AllDisabledADUsers = $AllADUsers | Where-Object {$_.Enabled -eq $false}
      If(@($AllDisabledADUsers).Count -gt 0 -And @($AllUsersToEnable).Count -gt 0){
         Compare-Object @($AllDisabledADUsers).sAMAccountName @($AllUsersToEnable).$UsernameField -IncludeEqual | Where-Object {$_.SideIndicator -eq "=="} | ForEach-Object {
         $MessageBody += "Enable User: "+$_.InputObject | Out-String
 	 }
      }
      If($DebugProgram){$now = Get-Date; Write-Host "Finished Enabling Users at: $now"}
   }
   ######
   ### DISABLE USERS ###
   If(-Not($NoDisable)){
      If($DebugProgram){$now = Get-Date; Write-Host "Started Disabling Users at: $now"}
      $newDataView = New-Object System.Data.DataView($AllDBData)
      $AllDisableCriteria = $ConfigData["EnableIf"]["Disable"]
      $aQuery = $AllDisableCriteria.Replace("|"," OR ")
      $newDataView.RowFilter = $aQuery
      $AllUsersToDisable = $newDataView | Select * | Sort-Object -Property $UsernameField -Unique
      $AllEnabledADUsers = $AllADUsers | Where-Object {$_.Enabled -eq $true}
      If(@($AllUsersToDisable).Count -gt 0 -And @($AllEnabledADUsers).Count -gt 0){
         Compare-Object @($AllEnabledADUsers).sAMAccountName @($AllUsersToDisable).$UsernameField -IncludeEqual | Where-Object {$_.SideIndicator -eq "=="} | ForEach-Object { 
	    $MessageBody += "Disable User: "+$_.InputObject | Out-String
 	 }
      }
   If($DebugProgram){$now = Get-Date; Write-Host "Finished Disabling Users at: $now"}
   }   
   ######
   If($DebugProgram){$now = Get-Date; Write-Host "Finished Updating Accounts at: $now"}
}
######

### OUTPUT RESULTS ###
If($MessageBody.Length -gt 0 -AND $SendEmail) {
   Send-MailMessage -To $EmailTo -Subject $EmailSubject -Body $EmailBodyHeader$MessageBody -SmtpServer $EmailServer -From $EmailFrom
}Else{
   Write-Host $MessageBody
}

If($OutputResults){
   $MessageBody | Out-File $OutputResultsFile
}
######

If($DebugProgram){ $Now = Get-Date; Write-Host "$($MyInvocation.MyCommand.Name):: Program ended $Now"}
