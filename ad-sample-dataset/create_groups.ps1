# website: activedirectorypro.com

Import-Module ActiveDirectory

#Import CSV
$groups = Import-Csv c:\it\groups.csv


# Loop through the CSV
    foreach ($group in $groups) {

    $groupProps = @{

      Name          = $group.name
      Path          = $group.path
      GroupScope    = $group.scope
      GroupCategory = $group.category
      Description   = $group.description

      }#end groupProps

    New-ADGroup @groupProps
    
} #end foreach loop