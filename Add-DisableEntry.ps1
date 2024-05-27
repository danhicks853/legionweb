Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase

# MySQL connection details
$MYSQL_HOST = "100.116.69.113"
$MYSQL_PORT = 3310
$MYSQL_USER = "spp_userDB"
$MYSQL_PASSWORD = "wl0BlZ@4QB7V@Bpg"
$MYSQL_DATABASE = "legion_world"
Add-Type -Path "MySqlConnector.dll"  # Ensure the correct path to MySqlConnector.dll

# Load data from CSV files
$spellData = Import-Csv -Path "spells.csv"
$mapData = Import-Csv -Path "maps.csv"

function Test-DbConnection {
    try {
        $connectionString = "server=$MYSQL_HOST;port=$MYSQL_PORT;uid=$MYSQL_USER;pwd=$MYSQL_PASSWORD;database=$MYSQL_DATABASE;"
        $connection = New-Object MySql.Data.MySqlClient.MySqlConnection($connectionString)
        $connection.Open()
        $connection.Close()
        return $true
    } catch {
        Write-Output "Error testing database connection: $_"
        return $false
    }
}

function Add-ToDatabase {
    param (
        [int]$entry,
        [int]$sourceType,
        [int]$entryType,
        [int]$flags,
        [string]$comment
    )
    try {
        $connectionString = "server=$MYSQL_HOST;port=$MYSQL_PORT;uid=$MYSQL_USER;pwd=$MYSQL_PASSWORD;database=$MYSQL_DATABASE;"
        $connection = New-Object MySql.Data.MySqlClient.MySqlConnection($connectionString)
        $connection.Open()
        $query = "INSERT INTO disables (entry, sourceType, flags, comment) VALUES (@entry, @sourceType, @flags, @comment)"
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        $command.Parameters.Add((New-Object MySql.Data.MySqlClient.MySqlParameter("@entry", [MySql.Data.MySqlClient.MySqlDbType]::Int32))).Value = $entry
        $command.Parameters.Add((New-Object MySql.Data.MySqlClient.MySqlParameter("@sourceType", [MySql.Data.MySqlClient.MySqlDbType]::Int32))).Value = $sourceType
        $command.Parameters.Add((New-Object MySql.Data.MySqlClient.MySqlParameter("@flags", [MySql.Data.MySqlClient.MySqlDbType]::Int32))).Value = $flags
        $command.Parameters.Add((New-Object MySql.Data.MySqlClient.MySqlParameter("@comment", [MySql.Data.MySqlClient.MySqlDbType]::VarChar, 255))).Value = $comment
        $command.ExecuteNonQuery()
        $connection.Close()
        $StatusLabel.Dispatcher.Invoke([action]{ $StatusLabel.Content = "Added to database: Entry=$entry, SourceType=$sourceType, Flags=$flags, Comment=$comment" })
    } catch {
        $StatusLabel.Dispatcher.Invoke([action]{ $StatusLabel.Content = "Error adding to database: $_" })
    }
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Disable Manager" Height="550" Width="600">
    <Grid>
        <Label Content="Spell Name" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,10,0,0"/>
        <TextBox Name="SpellNameTextBox" HorizontalAlignment="Left" Height="23" Margin="100,10,0,0" VerticalAlignment="Top" Width="300"/>
        <Button Content="Search Spell" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="410,10,0,0" Name="SearchSpellButton"/>
        <ListView Name="SpellListView" HorizontalAlignment="Left" Margin="10,40,0,0" VerticalAlignment="Top" Width="560" Height="100">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="ID" DisplayMemberBinding="{Binding ID}" Width="50"/>
                    <GridViewColumn Header="Name" DisplayMemberBinding="{Binding Name}" Width="200"/>
                    <GridViewColumn Header="Description" DisplayMemberBinding="{Binding Description}" Width="300"/>
                </GridView>
            </ListView.View>
        </ListView>
        <Button Content="Disable Spell" HorizontalAlignment="Left" VerticalAlignment="Top" Width="100" Margin="10,150,0,0" Name="DisableSpellButton"/>
        
        <Label Content="Map Name" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,180,0,0"/>
        <TextBox Name="MapNameTextBox" HorizontalAlignment="Left" Height="23" Margin="100,180,0,0" VerticalAlignment="Top" Width="300"/>
        <Button Content="Search Map" HorizontalAlignment="Left" VerticalAlignment="Top" Width="75" Margin="410,180,0,0" Name="SearchMapButton"/>
        <ListView Name="MapListView" HorizontalAlignment="Left" Margin="10,210,0,0" VerticalAlignment="Top" Width="560" Height="100">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="ID" DisplayMemberBinding="{Binding ID}" Width="50"/>
                    <GridViewColumn Header="Name" DisplayMemberBinding="{Binding Name}" Width="200"/>
                    <GridViewColumn Header="Description" DisplayMemberBinding="{Binding Description}" Width="300"/>
                </GridView>
            </ListView.View>
        </ListView>
        
        <CheckBox Content="Normal / 10-Man Normal" Name="MapType1" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="100,320,0,0"/>
        <CheckBox Content="Heroic / 25-Man Normal" Name="MapType2" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="100,350,0,0"/>
        <CheckBox Content="10-Man Heroic" Name="MapType4" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="100,380,0,0"/>
        <CheckBox Content="25-Man Heroic" Name="MapType8" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="100,410,0,0"/>
        
        <Label Content="Comment" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,440,0,0"/>
        <TextBox Name="DisableCommentTextBox" HorizontalAlignment="Left" Height="23" Margin="100,440,0,0" VerticalAlignment="Top" Width="300"/>
        
        <Button Content="Disable Map" HorizontalAlignment="Left" VerticalAlignment="Top" Width="100" Margin="10,470,0,0" Name="DisableMapButton"/>
        
        <Button Content="Test DB Connection" HorizontalAlignment="Left" VerticalAlignment="Top" Width="125" Margin="120,470,0,0" Name="TestDbConnectionButton"/>

        <Label Name="StatusLabel" Content="" HorizontalAlignment="Left" VerticalAlignment="Bottom" Margin="10,500,0,0" Width="500"/>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Find controls
$SearchSpellButton = $window.FindName("SearchSpellButton")
$SpellNameTextBox = $window.FindName("SpellNameTextBox")
$SpellListView = $window.FindName("SpellListView")
$DisableSpellButton = $window.FindName("DisableSpellButton")

$SearchMapButton = $window.FindName("SearchMapButton")
$MapNameTextBox = $window.FindName("MapNameTextBox")
$MapListView = $window.FindName("MapListView")
$MapType1 = $window.FindName("MapType1")
$MapType2 = $window.FindName("MapType2")
$MapType4 = $window.FindName("MapType4")
$MapType8 = $window.FindName("MapType8")
$DisableCommentTextBox = $window.FindName("DisableCommentTextBox")
$DisableMapButton = $window.FindName("DisableMapButton")

$TestDbConnectionButton = $window.FindName("TestDbConnectionButton")
$StatusLabel = $window.FindName("StatusLabel")


# Event handlers
$SearchSpellButton.Add_Click({
    $spellName = $SpellNameTextBox.Text
    $SpellListView.Items.Clear()
    $spells = $spellData | Where-Object { $_.Name -like "*$spellName*" }
    if ($spells) {
        foreach ($spell in $spells) {
            $item = New-Object PSObject -Property @{
                ID = $spell.ID
                Name = $spell.Name
                Description = $spell.Description
            }
            $SpellListView.Items.Add($item)
        }
    } else {
        $StatusLabel.Content = "No spells found matching '$spellName'."
    }
})

$DisableSpellButton.Add_Click({
    $selectedSpell = $SpellListView.SelectedItem
    $disableComment = $DisableCommentTextBox.Text
    if ($selectedSpell) {
        $spellID = $selectedSpell.ID -as [int]
        $spellName = $selectedSpell.Name
        Add-ToDatabase -entry $spellID -sourceType 0 -flags 0 -comment $disableComment
        $StatusLabel.Content = "Spell '$spellName' ($spellID) disabled successfully."
    } else {
        $StatusLabel.Content = "No spell selected to disable."
    }
})

$SearchMapButton.Add_Click({
    $mapName = $MapNameTextBox.Text
    $MapListView.Items.Clear()
    $maps = $mapData | Where-Object { $_.MapName -match "$mapName" }
    if ($maps) {
        foreach ($map in $maps) {
            $item = New-Object PSObject -Property @{
                ID = $map.ID
                Name = $map.MapName
            }
            $MapListView.Items.Add($item)
        }
    } else {
        $StatusLabel.Content = "No maps found matching '$mapName'."
    }
})

$DisableMapButton.Add_Click({
    $selectedMap = $MapListView.SelectedItem
    $disableComment = $DisableCommentTextBox.Text
    if ($selectedMap) {
        $mapID = $selectedMap.ID -as [int]
        $mapName = $selectedMap.Name
        if ($MapType1.IsChecked) { Add-ToDatabase -entry $mapID -sourceType 1 -flags 1 -comment $disableComment }
        if ($MapType2.IsChecked) { Add-ToDatabase -entry $mapID -sourceType 1 -flags 2 -comment $disableComment }
        if ($MapType4.IsChecked) { Add-ToDatabase -entry $mapID -sourceType 1 -flags 4 -comment $disableComment }
        if ($MapType8.IsChecked) { Add-ToDatabase -entry $mapID -sourceType 1 -flags 8 -comment $disableComment }
        $StatusLabel.Content = "Map '$mapName' ($mapID) disabled successfully."
    } else {
        $StatusLabel.Content = "No map selected to disable."
    }
})

$TestDbConnectionButton.Add_Click({
    try {
        if (Test-DbConnection) {
            $StatusLabel.Dispatcher.Invoke([action]{ $StatusLabel.Content = "Database connection successful." })
        } else {
            $StatusLabel.Dispatcher.Invoke([action]{ $StatusLabel.Content = "Database connection failed." })
        }
    } catch {
        $StatusLabel.Dispatcher.Invoke([action]{ $StatusLabel.Content = "Error during DB connection test: $_" })
    }
})

$window.ShowDialog()
