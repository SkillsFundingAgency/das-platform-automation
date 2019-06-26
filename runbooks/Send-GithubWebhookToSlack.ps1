param(
    [object]$WebhookData
)

$RequestData = $WebhookData | ConvertFrom-Json -Depth 10
Write-Host "$RequestData"

$SlackSecurityAlertWebhook = Get-AutomationVariable -Name 'SlackSecurityAlertWebhook'

$Fields = @(
    @{
        title = "Repository"
        value = "<$($RequestData.repository.html_url)|$($RequestData.repository.full_name)>"
    },
    @{
        title = "Package"
        value = $RequestData.alert.affected_package_name
    }
)
    

switch ($RequestData.action) {
    'create' {
        $Colour = "danger"
        $Text = "New Security Vulnerability Alert"
        $Fields += @(        
            @{
                title = "Affected Range"
                value = $RequestData.alert.affected_range
            },
            @{
                title = "Fixed In"
                value = $RequestData.alert.fixed_in
            },
            @{
                title = "External Reference"
                value = $RequestData.alert.external_reference
            }
        )

        break
    }
    'dismiss' {
        $Colour = "warning"
        $Text = "Security Vulnerability Dismissed"
        break
    }
    'resolve' {
        $Colour = "good"
        $Text = "Security Vulnerability Resolved"
        break
    }
}

$SlackWebhookBody = @{
    username    = "Github"
    icon_emoji  = ":github:"
    attachments = @( 
        @{
            author_icon = "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png"
            text        = $Text
            fields      = $Fields
            color       = $Colour
        }
    )
}

Invoke-RestMethod -Method Post -Uri $SlackSecurityAlertWebhook -Body ($SlackWebhookBody | ConvertTo-Json -Depth 10) -Headers @{ "Content-Type" = "application/json" }