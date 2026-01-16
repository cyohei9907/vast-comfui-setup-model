# PowerShell script to parse workflow JSON files and generate model.txt

$WorkflowDir = Join-Path $PSScriptRoot "workflow"
$OutputFile = Join-Path $PSScriptRoot "model.yaml"

Write-Host "Parsing workflow files in: $WorkflowDir"
Write-Host "Output file: $OutputFile"

# Clear output file
"" | Set-Content $OutputFile

# Process each JSON file
Get-ChildItem "$WorkflowDir\*.json" | ForEach-Object {
    $jsonFile = $_
    $workflowName = $jsonFile.BaseName
    Write-Host "Processing: $workflowName"
    
    # Read JSON content
    $content = Get-Content $jsonFile.FullName -Raw
    
    # Extract all URLs with directory context
    $urlPattern = '"url":\s*"(https://[^"]+)"'
    $dirPattern = '"directory":\s*"([^"]+)"'
    
    $urls = [regex]::Matches($content, $urlPattern) | ForEach-Object { $_.Groups[1].Value }
    
    if ($urls.Count -eq 0) {
        Write-Host "  No URLs found in $workflowName"
        return
    }
    
    # Group URLs by category
    $categories = @{}
    
    foreach ($url in $urls) {
        # Find directory context near this URL
        $urlIndex = $content.IndexOf("`"$url`"")
        if ($urlIndex -gt 0) {
            # Look for directory in surrounding context (500 chars before and after)
            $contextStart = [Math]::Max(0, $urlIndex - 500)
            $contextEnd = [Math]::Min($content.Length, $urlIndex + 500)
            $context = $content.Substring($contextStart, $contextEnd - $contextStart)
            
            $dirMatch = [regex]::Match($context, $dirPattern)
            if ($dirMatch.Success) {
                $category = $dirMatch.Groups[1].Value
            } else {
                # Fallback: guess from URL
                $filename = Split-Path $url -Leaf
                if ($url -match 'lora|LoRA') {
                    $category = 'loras'
                } elseif ($url -match 'upscal') {
                    $category = 'latent_upscale_models'
                } elseif ($url -match 'text_encoder|gemma|umt5') {
                    $category = 'text_encoders'
                } elseif ($url -match 'vae') {
                    $category = 'vae'
                } elseif ($url -match 'diffusion') {
                    $category = 'diffusion_models'
                } elseif ($url -match 'depth|lotus') {
                    $category = 'depth'
                } else {
                    $category = 'checkpoints'
                }
            }
            
            if (-not $categories.ContainsKey($category)) {
                $categories[$category] = @()
            }
            
            # Add URL if not already in list
            if ($categories[$category] -notcontains $url) {
                $categories[$category] += $url
            }
        }
    }
    
    # Write to output file
    Add-Content $OutputFile "${workflowName}:"
    
    foreach ($cat in $categories.Keys | Sort-Object) {
        $urlList = $categories[$cat] | ForEach-Object { "'$_'" }
        $urlString = $urlList -join ', '
        Add-Content $OutputFile "  ${cat}: [$urlString]"
    }
    
    Add-Content $OutputFile ""
}

Write-Host ""
Write-Host "Model URLs extracted to: $OutputFile"
Write-Host "Done!"
