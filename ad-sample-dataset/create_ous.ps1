# This script is used for creating bulk OUs from a CSV file
# Update the CSV with the OU name and path
# website: activedirectorypro.com

# Import active directory module for running AD cmdlets
Import-Module activedirectory
  
#Store the data from ADUsers.csv in the $ADUsers variable. CSV template needs the following headers-> name, path
$ADOU = Import-csv C:\it\ous.csv

#Loop through each row containing user details in the CSV file
foreach ($ou in $ADou)
{
	#Read data from each field in each row and assign the data to a variable as below
		
	$name 	= $ou.name
	$path 	= $ou.path

    #Account will be created in the OU provided by the $OU variable read from the CSV file
	   New-ADOrganizationalUnit `
            -Name $name `
            -path $path `      

}